;This is the autohotkey version.
Process Priority,,High
;#NoTrayIcon
#SingleInstance Ignore
#Include sub/urlencode.ahk
#Include sub/ini.ahk
#Include sub/web_search.ahk
#Include sub/get_processname.ahk
SetWorkingDir,%A_ScriptDir%                              ;设置工作目录为candy所在目录
splitpath,A_ScriptDir,,,,,script_driver                  ;candy所在的盘符

;提取命令行
If 0>0
{
	Loop, %0%
	{
	   tmp := %A_Index%
	   If InStr( tmp, "/ini=", TRUE ) = 1
			StringReplace ,Settings_file,tmp,/ini=
	   Else
			CommandLineInput=%CommandLineInput%%A_Space%%tmp%
	}
}
CandyInit:
If Settings_file=
{
	StringReplace, Settings_file, A_ScriptName, .exe, .ini
}
IfNotExist,%Settings_file%
{
    Msgbox Usage: `n------------------------------`nThe name of your configuration file must be same as the executable file. %Settings_file%`nOr run with parameters "%A_ScriptName% /ini=anyname.ini" `n
    ;exitapp
    return
}
ini_Load(src,Settings_file)
return

CandyGo:
WinGet,currwin_pid,pid,A                                    ;当前窗口的PID
WinGetClass, currwin_class, A                              ;当前窗口的class
WinGetTitle, currwin_Title, A                              ;当前窗口的Title
ControlGet, currwin_hwnd,Hwnd,,,A                          ;当前窗口的Handle
currwin_fullpath:=GetModuleFileNameEx(currwin_pid)          ;当前窗口的fullpath
splitpath,currwin_fullPath,,,,currwin_name,               ;切割当前窗口的路径，获取窗口的name

/*
提取目标
*/

If CommandLineInput!=   ;如果有命令行参数，跳过CTRL C取目标
{
    f_fileselected=%CommandLineInput%
    Goto Lable_CommandLineInput
}
;**************************************************************************************************************************
;没有命令行参数，则要靠CTRL C取目标了
IniRead,p_timewait_for_candy,%settings_file%,configuration,TimeWaitCandy,0.4
Saved_ClipBoard := ClipboardAll
clipboard =
Send, ^c
ClipWait,%p_timewait_for_candy%
f_fileselected=%Clipboard%
Clipboard := Saved_ClipBoard
Saved_ClipBoard =


;**************************************************************************************************************************
is_windowflag:=0
If f_fileselected=                                             ;如果粘贴板里面没有内容，则进行candywindows进程
{
    f_FileExt:="window"
    f_fileselected=%currwin_name%
    is_windowflag:=1
    GOTO Lable_WindowSelected
    ;;ExitApp
    return
}

;提取后缀
Lable_CommandLineInput:
IniRead,p_ShortText_length,%settings_file%,configuration,ShortText_length,80         ;短文本的长度
IfExist,%f_fileselected%                           ;如果是电脑里面存在的文件
{
	FileGetAttrib, f_file_Attrib, %f_fileselected%           ;是文件的情况下，区分是否文件夹,把 Path 指向的文件或文件夹的属性赋值给 Attrib
    IfInString, f_file_Attrib, D                               ;如果在 Attrib 里有 D ,就表示这个路径代表的是文件夹，否则就是文件
    {
        If(RegExMatch(f_fileselected,":\\$"))
        {
            f_FileExt:="Driver"            ;是否盘符
        }
        Else
        {
            f_FileExt:="Folder"            ;是否文件夹
		}
		SplitPath,f_fileselected,,f_FilePath,,f_filefoldernameonly,f_FileDriver
	}
    Else        ;若不是文件夹的话，则只能是文件了
    {
        is_fileflag:=1
        splitpath,f_fileselected,f_FileName,f_FilePath,f_FileExt,f_FileNamenoext,f_FileDriver
        SplitPath,f_FilePath,,,,f_filefoldernameonly,
		;StringReplace,f_FileDriverletter,f_FileDriver,:                ;被选文件的盘符，不带冒号
        If !f_FileExt    ;没有后缀的文件
        {
			f_FileExt:="NoExt"
        }
    }
}
Else             ;如果是文本
{
	is_textflag:=1
	If(RegExMatch(f_fileselected,"i)^(https://|http://|www.)([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)?"))
    {
		f_FileExt:="WebUrl"   ;判断是否网址
    }
    Else If(RegExMatch(f_fileselected, "^[\w-_.]+@(?:\w+(?::\d+)?\.){1,3}(?:\w+\.?){1,2}$"))
    {
        f_FileExt:="Email"    ;判断是否email地址
    }
    Else If (strlen(f_fileselected)<p_ShortText_length)
    {
        f_FileExt:="ShortText" ;判断是否短文本
    }
    Else
    {
        f_FileExt:="LongText"  ;判断是否长文本
    }
}


;对能够赢

Lable_WindowSelected:   ;如果是windows则直接跳到这里来，避免被认为是0长度的short_text
abc=i)(^|\|)%f_fileext%($|\|)   ;正则表达式啊，好辛苦的，|必须要有 \开道
f_fileext_group:=ini_FindKeysRE(src, "associations", abc)
IniRead,MyAppName, %Settings_file%,associations,%f_fileext_group%, ;在ini文件里面找匹配



If MyAppName=Error           ;如果没有相应后缀的定义
{
	If is_fileflag=1                              ;如果没有定义，若是文件的话，看是否有anyfile的定义
	{
		IniRead,MyAppName, %Settings_file%,associations,AnyFile
		If MyAppName=Error
		{
			Run,%f_fileselected%, ,useerrorlevel  ;UseErrorLevel如果run命令失败，忽略出错提示并置errorlevel为Error，线程继续往下。
			;ExitApp
                        return
		}
	}
	Else if is_textflag=1                                         ;如果没有定义，后缀是文本，看是否有anytext的定义
	{
		IniRead,MyAppName, %Settings_file%,associations,AnyText
		If MyAppName=Error
		{
			;ExitApp
                        return
		}
	}
	Else   ;其它的后缀是文件夹、盘符、窗体等了，这种情况下直接退出程序即可
	{
		;ExitApp
                return
	}
}



;**************************************************************************************************************************
;判断是QuickCandy，还是menuCandy
If(RegExMatch(MyAppName,"i)^(menu_)")) ;如果是以menu_开头,先去画菜单
	Goto Lable_DrawMenu
Else                                     ;否则直接运行应用程序
	Goto Lable_RunApp




Lable_DrawMenu:
	;================菜单第一行，限制字数在20个字================================
    f_length_fileselected:=StrLen(f_fileselected)
    IfGreater,f_length_fileselected,20
    {
        stringleft,f_textmenu_left,f_fileselected,5
        StringRight,f_textmenu_right,f_fileselected,12
        menu mymenu,add,%f_textmenu_left% …  %f_textmenu_right%,r_CopyFullPath     ;加第一行菜单，显示选中的内容，该菜单让你拷贝其内容
    }
    Else
    {
        Menu mymenu,add,%f_fileselected%,r_CopyFullPath     ;加第一行菜单，显示选中的内容，该菜单让你直接打开配置文件
    }
	;================根据各类型画出菜单================================
	IfInString,MyAppName,@
	{
		f_Menu_additional:=1
		StringReplace,MyAppName,MyAppName,@
	}

	key:=ini_GetKeys(src,MyAppName)             ;调用时，如果是变量就不用加%%
	if key!=
	{
		menu mymenu,add
		Loop,Parse,key,`n
		{
			Menu,mymenu,Add,%A_LoopField%,r_Menu_handle
		}
	}
	If f_Menu_additional=1        ;如果没有@，则不用显示附加的菜单
	{
		menu mymenu,add
		f_Menu_additional:=0
		f_key_Menu_AnyFile:=ini_GetKeys(src,"Menu_AnyFile")  ;调用时，如果是常量，一定要加""
		Loop,Parse,f_key_Menu_AnyFile,`n
		{
			Menu,mymenu,Add,%A_LoopField%,r_Menu_handle_AnyFile
		}
	}

	Menu,MyMenu,Show
        Menu, MyMenu, DeleteAll
	;ExitApp
        return


	;================菜单处理================================
	r_Menu_handle:
		MyAppName:=ini_Read(src,MyAppName,A_ThisMenuItem)
		Goto Lable_RunApp

	r_Menu_handle_AnyFile:
		MyAppName:=ini_Read(src,"Menu_AnyFile",A_ThisMenuItem)
		Goto Lable_RunApp


	r_CopyFullPath:
		Clipboard:=f_fileselected
		;ExitApp
                return



/*
╔══════════════════════════════════════╗
║             运行处理②运行处理                                             ║
╚══════════════════════════════════════╝
*/

Lable_RunApp:
	If(RegExMatch(MyAppName,"i)^(https://|http://|www.)([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)?")) ;如果是网页搜索，以http开头，转成utf8
	{
		f_fileselected:=url2UTF8(f_fileselected)
		f_网址=%MyAppName%%f_fileselected%
		mywebrun:=websearch(Settings_file,f_网址,currwin_class,currwin_fullpath)
		Run, %mywebrun%,,useerrorlevel
		;ExitApp
                return
	}
	If(RegExMatch(MyAppName,"i)^(@https://|@http://|@www.)([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)?")) ;如果是网页搜索，以@http开头，转成gbk
	{
		StringTrimLeft,MyAppName,MyAppName,1
		f_fileselected:=url2gbk(f_fileselected)
		f_网址=%MyAppName%%f_fileselected%
		mywebrun:=websearch(Settings_file,f_网址,currwin_class,currwin_fullpath)
		Run, %mywebrun%,,useerrorlevel
		;ExitApp
                return
	}
	;=========================================
	Else  ;不是网址，则是一般的应用程序
	{
		;替换掉当前窗口那一部分的
		StringReplace,MyAppName,MyAppName,<win_class>    ,%currwin_class%,All
		StringReplace,MyAppName,MyAppName,<win_title>    ,%currwin_title%,All
		StringReplace,MyAppName,MyAppName,<win_hwnd>     ,%currwin_hwnd%
		StringReplace,MyAppName,MyAppName,<win_name>     ,%currwin_name%,All
		StringReplace,MyAppName,MyAppName,<win_fullpath> ,%currwin_fullpath%
		;目的是相对路径
		StringReplace,MyAppName,MyAppName,<cp>,%A_ScriptDir%,All
		StringReplace,MyAppName,MyAppName,<cd>,%script_driver%,All
		;一些时间参数
		StringReplace,MyAppName,MyAppName,<year> ,%A_YEAR%,All
		StringReplace,MyAppName,MyAppName,<mon>  ,%A_MM%,All
		StringReplace,MyAppName,MyAppName,<date> ,%A_dd%,All
		StringReplace,MyAppName,MyAppName,<hour> ,%A_YEAR%,All
		StringReplace,MyAppName,MyAppName,<min>  ,%A_Min%,All
		StringReplace,MyAppName,MyAppName,<sec>  ,%A_Sec%,All
		StringReplace,MyAppName,MyAppName,<wday> ,%A_WDay%,All
		StringReplace,MyAppName,MyAppName,<now>  ,%A_Now%,All
		;操作对象是文件的时候，进行替换的对象
		StringReplace,MyAppName,MyAppName,<file_driver>     ,%f_FileDriver%,All           ;
		StringReplace,MyAppName,MyAppName,<file_path>       ,%f_FilePath%,All             ;不带文件名的路径
		StringReplace,MyAppName,MyAppName,<file_name>       ,%f_FileNamenoext%,All        ;纯粹的文件名，无后缀，无路径
		StringReplace,MyAppName,MyAppName,<file_ext>        ,%f_FileExt%,All
		StringReplace,MyAppName,MyAppName,<file_foldername> ,%f_filefoldernameonly%,All
		StringReplace,MyAppName,MyAppName,<file_fullpath>   ,%f_fileselected%,All
		;特别的参数
		IfInString,MyAppName,<clipon>
		{
			Clipboard:=f_fileselected
			StringReplace,MyAppName,MyAppName,<clipon>,,all
		}
		IfInString,MyAppName,<input>
		{
			Gui +LastFound +OwnDialogs +AlwaysOnTop
			InputBox, myinput,CandyInput,`n`n     Please input your parameter: ,, 285, 175,,,,,
			if errorlevel
				;ExitApp
                                return
			Else
				StringReplace,MyAppName,MyAppName,<input>,%myinput%,all
		}
		IfInString,MyAppName,<hinput>
		{
			Gui +LastFound +OwnDialogs +AlwaysOnTop
			InputBox, myinput,CandyInput,`n`n     Please input your parameter: ,Hide, 285, 175,,,,,
			if errorlevel
				;ExitApp
                                return
			Else
				StringReplace,MyAppName,MyAppName,<hinput>,%myinput%,all
		}
		IfInString,MyAppName,<select>
		{
			FileSelectFile, f_selectedname ,  , , Open a file,
			If f_selectedname <>
			{
				StringReplace,MyAppName,MyAppName,<select>,%f_selectedname%,all
			}
			Else
			{
				;MsgBox,Canceled
				;ExitApp
                                return
			}
		}
                ;clear runn#
                clear=|||
                StringSplit,runn,clear,|
		;替换完成，就是运行了
		StringSplit,runn,MyAppName,|
		If runn2=
		{
			If is_windowflag!=1   ;如果是windows，那么“操作对象”可以置空
			runn2="%f_fileselected%"
		}
		;MsgBox run %runn1%`, %runn2%`,%runn3%`,%runn4%
                if runn1="" and runn2=""
                  return
		run,%runn1% %runn2%,%runn3%,%runn4% useerrorlevel
		;1:程序 2:目标 3:工作目录 4:状态
		;ExitApp
                return
	}






;**************************************************************************************************************************
;by wannainshuyao@gmail.com
;**************************************************************************************************************************
