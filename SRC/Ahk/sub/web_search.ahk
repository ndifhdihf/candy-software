;**************************************************************************************************************************
;by wannainshuyao@gmail.com
;http://hi.baidu.com/1wyears/blog

websearch(configfile,WebAddress,curWindowClass,curWindowPath)
{
	IniRead,f_UsedBrowser, %configfile%,configuration,used_browser
    IniRead,f_DefaultBrowser, %configfile%,configuration,Default_browser
	StringReplace,f_DefaultBrowser,f_DefaultBrowser,<cp>,%A_ScriptDir%,All
    StringReplace,f_DefaultBrowser,f_DefaultBrowser,<cd>,%script_driver%,All

    if curWindowClass Contains OpWindow,TheWorld_Frame,IEFrame,MozillaUIWindowClass,Maxthon2_Frame
    {
        Return,curWindowPath A_Space WebAddress
    }
	Else if curWindowPath Contains %f_UsedBrowser%
	{
        Return,curWindowPath A_Space WebAddress
    }
    Else
    {
		f_DefaultBrowser_test:= RegExReplace(f_DefaultBrowser, "exe[^!]*[^>]*", "exe")
        IfExist %f_DefaultBrowser_test%
        {
            Return,f_DefaultBrowser A_Space WebAddress
        }
        Else
        {
            Return,WebAddress
		}
    }

}
