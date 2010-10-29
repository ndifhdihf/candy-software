;By shimanov at http://www.autohotkey.com/forum/viewtopic.php?t=4182&postdays=0&postorder=asc&highlight=full+path&start=15

GetModuleFileNameEx(p_pid )
{
   h_process := DllCall( "OpenProcess", "uint", 0x10|0x400, "int", false, "uint", p_pid )
   if ( ErrorLevel or h_process = 0 )
      return
   name_size = 255
   VarSetCapacity( name, name_size )
   result := DllCall( "psapi.dll\GetModuleFileNameExA", "uint", h_process, "uint", 0, "str", name, "uint", name_size )
   DllCall( "CloseHandle", h_process )
   return, name
}
