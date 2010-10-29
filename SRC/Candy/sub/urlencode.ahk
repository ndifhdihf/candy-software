
;**************************************************************************************************************************
;http://www.blooberry.com/indexdot/html/topics/urlencoding.htm
url2gbk(s)
{
   ;must be first or we are in trouble
   StringReplace, s, s, % chr(37), % hex(37), All
   ;AsciiControlCharacters 00-1F hex (0-31 decimal) and 7F (127 decimal.
   loop, 32
      StringReplace, s, s, % chr(A_Index-1), % hex(A_Index-1), All
   StringReplace, s, s, % chr(127), % hex(127), All
   ;Non-ASCII characters 80-FF % hex (128-255 decimal.)
   loop, 128
      StringReplace, s, s, % chr(A_Index+127), % hex(A_Index+127), All
   ;"Reserved characters"
   StringReplace, s, s, % chr(36), % hex(36), All
   StringReplace, s, s, % chr(38), % hex(38), All
   StringReplace, s, s, % chr(43), % hex(43), All
   StringReplace, s, s, % chr(44), % hex(44), All
   StringReplace, s, s, % chr(47), % hex(47), All
   StringReplace, s, s, % chr(58), % hex(58), All
   StringReplace, s, s, % chr(59), % hex(59), All
   StringReplace, s, s, % chr(61), % hex(61), All
   StringReplace, s, s, % chr(63), % hex(63), All
   StringReplace, s, s, % chr(64), % hex(64), All
   ;"Unsafe characters"
   StringReplace, s, s, % chr(32), % hex(32), All
   StringReplace, s, s, % chr(34), % hex(34), All
   StringReplace, s, s, % chr(60), % hex(60), All
   StringReplace, s, s, % chr(62), % hex(62), All
   StringReplace, s, s, % chr(35), % hex(35), All
   StringReplace, s, s, % chr(123), % hex(123), All
   StringReplace, s, s, % chr(125), % hex(125), All
   StringReplace, s, s, % chr(124), % hex(124), All
   StringReplace, s, s, % chr(92), % hex(92), All
   StringReplace, s, s, % chr(94), % hex(94), All
   StringReplace, s, s, % chr(126), % hex(126), All
   StringReplace, s, s, % chr(91), % hex(91), All
   StringReplace, s, s, % chr(93), % hex(93), All
   StringReplace, s, s, % chr(96), % hex(96), All
   return s
}


hex(n){
   f:=n//16
   s:=Mod(n, 16)
   if (f=10)
      f=A
   else if (f=11)
      f=B
   else if (f=12)
      f=C
   else if (f=13)
      f=D
   else if (f=14)
      f=E
   else if (f=15)
      f=F
   if (s=10)
      s=A
   else if (s=11)
      s=B
   else if (s=12)
      s=C
   else if (s=13)
      s=D
   else if (s=14)
      s=E
   else if (s=15)
      s=F
   return "%" . f . s
}

;**************************************************************************************************************************
;http://hi.baidu.com/mettlesome/blog/item/72e878b5ed9ebcc437d3ca36.html
/*
CP_ACP   = 0
CP_OEMCP = 1
CP_MACCP = 2
CP_UTF7 = 65000
CP_UTF8 = 65001
*/

Ansi2Oem(sString)
{
   Ansi2Unicode(sString, wString, 0)
   Unicode2Ansi(wString, zString, 1)
   Return zString
}

Oem2Ansi(zString)
{
   Ansi2Unicode(zString, wString, 1)
   Unicode2Ansi(wString, sString, 0)
   Return sString
}

Ansi2UTF8(sString)
{
   Ansi2Unicode(sString, wString, 0)
   Unicode2Ansi(wString, zString, 65001)
   Return zString
}

UTF82Ansi(zString)
{
   Ansi2Unicode(zString, wString, 65001)
   Unicode2Ansi(wString, sString, 0)
   Return sString
}

Ansi2Unicode(ByRef sString, ByRef wString, CP = 0)
{
     nSize := DllCall("MultiByteToWideChar"
      , "Uint", CP
      , "Uint", 0
      , "Uint", &sString
      , "int", -1
      , "Uint", 0
      , "int", 0)

   VarSetCapacity(wString, nSize * 2)

   DllCall("MultiByteToWideChar"
      , "Uint", CP
      , "Uint", 0
      , "Uint", &sString
      , "int", -1
      , "Uint", &wString
      , "int", nSize)
}

Unicode2Ansi(ByRef wString, ByRef sString, CP = 0)
{
     nSize := DllCall("WideCharToMultiByte"
      , "Uint", CP
      , "Uint", 0
      , "Uint", &wString
      , "int", -1
      , "Uint", 0
      , "int", 0
      , "Uint", 0
      , "Uint", 0)

   VarSetCapacity(sString, nSize)

   DllCall("WideCharToMultiByte"
      , "Uint", CP
      , "Uint", 0
      , "Uint", &wString
      , "int", -1
      , "str", sString
      , "int", nSize
      , "Uint", 0
      , "Uint", 0)
}

url2utf8(p)
{
 str:=Ansi2UTF8(p)
 res:=Encode(&str)
 return res
}

Encode(p)
{
SetFormat,integer,hex
res := ""
while,value := *p++
{
   if(value==33 || (value>=39 && value <=42) || value==45 || value ==46 || (value>=48 && value<=57)    || (value>=65 && value<=90) || value==95 || (value>=97 && value<=122) || value==126)
   {
      ;msgbox,Chr(value)
      res .= Chr(value)
   }
   Else
   {
      res .= "%"
      res .= SubStr(value,3,2)
   }
}
Return res
}
