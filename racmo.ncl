


;********************************************************
undef("racmo_derive_land")
;
; Returns the named variable from the file pointer
;
;********************************************************
function derive_land_racmo(var_name,ptr)
begin
  routine = "racmo_derive_land"

  if(var_name.eq."ff10m")then
     var=ptr->ff10m
     return(var)
  end if

  if(var_name.eq."tskin")then
     var=ptr->tskin
     return(var)
  end if

  if(var_name.eq."snowfall")then
     var=ptr->snowfall
     return(var)
  end if

  if(var_name.eq."snowmelt")then
     var=ptr->snowmelt
     return(var)
  end if

  var = new(20,"float")
  print("ERROR: "+routine+": variable not implemented: "+var_name)
  return(var)
end



;********************************************************
undef("racmo_icesheet_total")
;
; Ice sheet area integral
;
;********************************************************
function racmo_icesheet_total(var,msk,area)
begin
   varsum = sum(var* msk * area )

   ; mm = kg / m2
   ; area in km2 so convert factor 1e6
   varsum = varsum * 1e6 

   ; kg to Gt (G=1e9  t=1e3 kg)
   varsum = varsum / 1e12

   sec_to_year = 86400 * 365
   varsum = varsum * sec_to_year
   return varsum
end


;********************************************************
undef("racmo_icesheet_total_YY12")
;
; Clone of racmo_icesheet_total()
;
;********************************************************
function racmo_icesheet_total_YY12(var,msk,area)
; units in mmWE / month
begin
   varsum = sum(var* msk * area )

   ; mm = kg / m2
   ; area in km2 so convert factor 1e6
   varsum = varsum * 1e6 

   ; kg to Gt (G=1e9  t=1e3 kg)
   varsum = varsum / 1e12

   sec_to_year = 86400 * 365
   ;varsum = varsum * sec_to_year
   varsum = varsum * 12
   return varsum
end


