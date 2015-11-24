
;********************************************************
undef("size")
function size(x)
;
; Like num(), but also count missing values
;
local n
begin
   n = num(.not.ismissing(x))
   return n
end

