; LvK 11-NOV-2015
; Functions to use lists in a slightly different way: using identification strings


;********************************************************
undef("ListPushWithIdstring")
;
; For a given list and variable identification string, retrieve variable index in list
;
procedure ListPushWithIdstring(my_list:list,y,idstring:string)
local ycopy
begin
   ycopy = y
   ycopy@idstring = idstring
   ListPush(my_list,ycopy)
end

;********************************************************
undef("ListIndexByIdstring")
;
; For a given list and variable identification string, retrieve variable index in list
;
function ListIndexByIdstring(my_list:list,idstring:string)
local idx, cnt, i
begin
  idx = -1 
  cnt = ListCount(my_list)
  do i = 0, cnt-1
     if (my_list[i]@idstring .eq. idstring) then
        idx = i
        break
     end if
  end do
  if (idx.eq.-1) then
     print("ERROR: idstring not found: "+idstring)
  end if
  return idx
end



