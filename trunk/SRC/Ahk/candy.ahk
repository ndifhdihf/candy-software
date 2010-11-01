;This is the autohotkey version.
Process Priority,,High
;#NoTrayIcon
#SingleInstance Ignore
#Include sub/urlencode.ahk
#Include sub/ini.ahk
#Include sub/web_search.ahk
#Include sub/get_processname.ahk
SetWorkingDir,%A_ScriptDir%                              ;���ù���Ŀ¼Ϊcandy����Ŀ¼
splitpath,A_ScriptDir,,,,,script_driver                  ;candy���ڵ��̷�

;��ȡ������
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
WinGet,currwin_pid,pid,A                                    ;��ǰ���ڵ�PID
WinGetClass, currwin_class, A                              ;��ǰ���ڵ�class
WinGetTitle, currwin_Title, A                              ;��ǰ���ڵ�Title
ControlGet, currwin_hwnd,Hwnd,,,A                          ;��ǰ���ڵ�Handle
currwin_fullpath:=GetModuleFileNameEx(currwin_pid)          ;��ǰ���ڵ�fullpath
splitpath,currwin_fullPath,,,,currwin_name,               ;�иǰ���ڵ�·������ȡ���ڵ�name

/*
��ȡĿ��
*/

If CommandLineInput!=   ;����������в���������CTRL CȡĿ��
{
    f_fileselected=%CommandLineInput%
    Goto Lable_CommandLineInput
}
;**************************************************************************************************************************
;û�������в�������Ҫ��CTRL CȡĿ����
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
If f_fileselected=                                             ;���ճ��������û�����ݣ������candywindows����
{
    f_FileExt:="window"
    f_fileselected=%currwin_name%
    is_windowflag:=1
    GOTO Lable_WindowSelected
    ;;ExitApp
    return
}

;��ȡ��׺
Lable_CommandLineInput:
IniRead,p_ShortText_length,%settings_file%,configuration,ShortText_length,80         ;���ı��ĳ���
IfExist,%f_fileselected%                           ;����ǵ���������ڵ��ļ�
{
	FileGetAttrib, f_file_Attrib, %f_fileselected%           ;���ļ�������£������Ƿ��ļ���,�� Path ָ����ļ����ļ��е����Ը�ֵ�� Attrib
    IfInString, f_file_Attrib, D                               ;����� Attrib ���� D ,�ͱ�ʾ���·����������ļ��У���������ļ�
    {
        If(RegExMatch(f_fileselected,":\\$"))
        {
            f_FileExt:="Driver"            ;�Ƿ��̷�
        }
        Else
        {
            f_FileExt:="Folder"            ;�Ƿ��ļ���
		}
		SplitPath,f_fileselected,,f_FilePath,,f_filefoldernameonly,f_FileDriver
	}
    Else        ;�������ļ��еĻ�����ֻ�����ļ���
    {
        is_fileflag:=1
        splitpath,f_fileselected,f_FileName,f_FilePath,f_FileExt,f_FileNamenoext,f_FileDriver
        SplitPath,f_FilePath,,,,f_filefoldernameonly,
		;StringReplace,f_FileDriverletter,f_FileDriver,:                ;��ѡ�ļ����̷�������ð��
        If !f_FileExt    ;û�к�׺���ļ�
        {
			f_FileExt:="NoExt"
        }
    }
}
Else             ;������ı�
{
	is_textflag:=1
	If(RegExMatch(f_fileselected,"i)^(https://|http://|www.)([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)?"))
    {
		f_FileExt:="WebUrl"   ;�ж��Ƿ���ַ
    }
    Else If(RegExMatch(f_fileselected, "^[\w-_.]+@(?:\w+(?::\d+)?\.){1,3}(?:\w+\.?){1,2}$"))
    {
        f_FileExt:="Email"    ;�ж��Ƿ�email��ַ
    }
    Else If (strlen(f_fileselected)<p_ShortText_length)
    {
        f_FileExt:="ShortText" ;�ж��Ƿ���ı�
    }
    Else
    {
        f_FileExt:="LongText"  ;�ж��Ƿ��ı�
    }
}


;���ܹ�Ӯ

Lable_WindowSelected:   ;�����windows��ֱ�����������������ⱻ��Ϊ��0���ȵ�short_text
abc=i)(^|\|)%f_fileext%($|\|)   ;������ʽ����������ģ�|����Ҫ�� \����
f_fileext_group:=ini_FindKeysRE(src, "associations", abc)
IniRead,MyAppName, %Settings_file%,associations,%f_fileext_group%, ;��ini�ļ�������ƥ��



If MyAppName=Error           ;���û����Ӧ��׺�Ķ���
{
	If is_fileflag=1                              ;���û�ж��壬�����ļ��Ļ������Ƿ���anyfile�Ķ���
	{
		IniRead,MyAppName, %Settings_file%,associations,AnyFile
		If MyAppName=Error
		{
			Run,%f_fileselected%, ,useerrorlevel  ;UseErrorLevel���run����ʧ�ܣ����Գ�����ʾ����errorlevelΪError���̼߳������¡�
			;ExitApp
                        return
		}
	}
	Else if is_textflag=1                                         ;���û�ж��壬��׺���ı������Ƿ���anytext�Ķ���
	{
		IniRead,MyAppName, %Settings_file%,associations,AnyText
		If MyAppName=Error
		{
			;ExitApp
                        return
		}
	}
	Else   ;�����ĺ�׺���ļ��С��̷���������ˣ����������ֱ���˳����򼴿�
	{
		;ExitApp
                return
	}
}



;**************************************************************************************************************************
;�ж���QuickCandy������menuCandy
If(RegExMatch(MyAppName,"i)^(menu_)")) ;�������menu_��ͷ,��ȥ���˵�
	Goto Lable_DrawMenu
Else                                     ;����ֱ������Ӧ�ó���
	Goto Lable_RunApp




Lable_DrawMenu:
	;================�˵���һ�У�����������20����================================
    f_length_fileselected:=StrLen(f_fileselected)
    IfGreater,f_length_fileselected,20
    {
        stringleft,f_textmenu_left,f_fileselected,5
        StringRight,f_textmenu_right,f_fileselected,12
        menu mymenu,add,%f_textmenu_left% ��  %f_textmenu_right%,r_CopyFullPath     ;�ӵ�һ�в˵�����ʾѡ�е����ݣ��ò˵����㿽��������
    }
    Else
    {
        Menu mymenu,add,%f_fileselected%,r_CopyFullPath     ;�ӵ�һ�в˵�����ʾѡ�е����ݣ��ò˵�����ֱ�Ӵ������ļ�
    }
	;================���ݸ����ͻ����˵�================================
	IfInString,MyAppName,@
	{
		f_Menu_additional:=1
		StringReplace,MyAppName,MyAppName,@
	}

	key:=ini_GetKeys(src,MyAppName)             ;����ʱ������Ǳ����Ͳ��ü�%%
	if key!=
	{
		menu mymenu,add
		Loop,Parse,key,`n
		{
			Menu,mymenu,Add,%A_LoopField%,r_Menu_handle
		}
	}
	If f_Menu_additional=1        ;���û��@��������ʾ���ӵĲ˵�
	{
		menu mymenu,add
		f_Menu_additional:=0
		f_key_Menu_AnyFile:=ini_GetKeys(src,"Menu_AnyFile")  ;����ʱ������ǳ�����һ��Ҫ��""
		Loop,Parse,f_key_Menu_AnyFile,`n
		{
			Menu,mymenu,Add,%A_LoopField%,r_Menu_handle_AnyFile
		}
	}

	Menu,MyMenu,Show
        Menu, MyMenu, DeleteAll
	;ExitApp
        return


	;================�˵�����================================
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
�X�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�[
�U             ���д�������д���                                             �U
�^�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�a
*/

Lable_RunApp:
	If(RegExMatch(MyAppName,"i)^(https://|http://|www.)([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)?")) ;�������ҳ��������http��ͷ��ת��utf8
	{
		f_fileselected:=url2UTF8(f_fileselected)
		f_��ַ=%MyAppName%%f_fileselected%
		mywebrun:=websearch(Settings_file,f_��ַ,currwin_class,currwin_fullpath)
		Run, %mywebrun%,,useerrorlevel
		;ExitApp
                return
	}
	If(RegExMatch(MyAppName,"i)^(@https://|@http://|@www.)([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)?")) ;�������ҳ��������@http��ͷ��ת��gbk
	{
		StringTrimLeft,MyAppName,MyAppName,1
		f_fileselected:=url2gbk(f_fileselected)
		f_��ַ=%MyAppName%%f_fileselected%
		mywebrun:=websearch(Settings_file,f_��ַ,currwin_class,currwin_fullpath)
		Run, %mywebrun%,,useerrorlevel
		;ExitApp
                return
	}
	;=========================================
	Else  ;������ַ������һ���Ӧ�ó���
	{
		;�滻����ǰ������һ���ֵ�
		StringReplace,MyAppName,MyAppName,<win_class>    ,%currwin_class%,All
		StringReplace,MyAppName,MyAppName,<win_title>    ,%currwin_title%,All
		StringReplace,MyAppName,MyAppName,<win_hwnd>     ,%currwin_hwnd%
		StringReplace,MyAppName,MyAppName,<win_name>     ,%currwin_name%,All
		StringReplace,MyAppName,MyAppName,<win_fullpath> ,%currwin_fullpath%
		;Ŀ�������·��
		StringReplace,MyAppName,MyAppName,<cp>,%A_ScriptDir%,All
		StringReplace,MyAppName,MyAppName,<cd>,%script_driver%,All
		;һЩʱ�����
		StringReplace,MyAppName,MyAppName,<year> ,%A_YEAR%,All
		StringReplace,MyAppName,MyAppName,<mon>  ,%A_MM%,All
		StringReplace,MyAppName,MyAppName,<date> ,%A_dd%,All
		StringReplace,MyAppName,MyAppName,<hour> ,%A_YEAR%,All
		StringReplace,MyAppName,MyAppName,<min>  ,%A_Min%,All
		StringReplace,MyAppName,MyAppName,<sec>  ,%A_Sec%,All
		StringReplace,MyAppName,MyAppName,<wday> ,%A_WDay%,All
		StringReplace,MyAppName,MyAppName,<now>  ,%A_Now%,All
		;�����������ļ���ʱ�򣬽����滻�Ķ���
		StringReplace,MyAppName,MyAppName,<file_driver>     ,%f_FileDriver%,All           ;
		StringReplace,MyAppName,MyAppName,<file_path>       ,%f_FilePath%,All             ;�����ļ�����·��
		StringReplace,MyAppName,MyAppName,<file_name>       ,%f_FileNamenoext%,All        ;������ļ������޺�׺����·��
		StringReplace,MyAppName,MyAppName,<file_ext>        ,%f_FileExt%,All
		StringReplace,MyAppName,MyAppName,<file_foldername> ,%f_filefoldernameonly%,All
		StringReplace,MyAppName,MyAppName,<file_fullpath>   ,%f_fileselected%,All
		;�ر�Ĳ���
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
		;�滻��ɣ�����������
		StringSplit,runn,MyAppName,|
		If runn2=
		{
			If is_windowflag!=1   ;�����windows����ô���������󡱿����ÿ�
			runn2="%f_fileselected%"
		}
		;MsgBox run %runn1%`, %runn2%`,%runn3%`,%runn4%
                if runn1="" and runn2=""
                  return
		run,%runn1% %runn2%,%runn3%,%runn4% useerrorlevel
		;1:���� 2:Ŀ�� 3:����Ŀ¼ 4:״̬
		;ExitApp
                return
	}






;**************************************************************************************************************************
;by wannainshuyao@gmail.com
;**************************************************************************************************************************
