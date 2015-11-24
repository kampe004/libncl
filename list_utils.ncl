; LvK 11-NOV-2015
; Functions to query NCL lists with keys (more like a dictionary)


;********************************************************
undef("ListPushWithKey")
;
; For a given list and identification string, retrieve variable index in list
;
procedure ListPushWithKey(my_list:list,y,key:string)
local ycopy
begin
   ycopy = y
   ycopy@key = key
   ListPush(my_list,ycopy)
end

;********************************************************
undef("ListIndexByKey")
;
; For a given list and identification string, retrieve variable index in list
;
function ListIndexByKey(my_list:list,key:string)
local idx, cnt, i
begin
  idx = -1 
  cnt = ListCount(my_list)
  do i = 0, cnt-1
     if (my_list[i]@key .eq. key) then
        idx = i
        break
     end if
  end do
  if (idx.eq.-1) then
     print("ERROR: key not found: "+key)
  end if
  return idx
end



