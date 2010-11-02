;count number of ascii char of a string
;sunyanteng@gmail.com

AscCount(str)
{
  i:=1
  count:=0
  len:=Strlen(str)
  Loop
  {
    if (i<=len)
    {
      StringMid, char, str, i, 1
      if(Asc(char) <= 127) 
        count := count + 1
      i:=i+1
    } 
    else 
      break
  }
  return %count%
}
