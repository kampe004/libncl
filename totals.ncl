
; LvK 26-NOV-2015
; Based on lnd_diag4.2.28/code/shared/lnd_func.ncl


;********************************************************
undef("mass_totals_is")
function mass_totals_is(field,ptr_surfdat:file,is_string:string)
; compute ice sheet integrated mass totals for a given LAT/LON field
; note that surfdat is used to extract area and land mask, this should be in the same resolution as field
begin
   routine = "mass_totals_is"

   dims=dimsizes(field)
   nt=dims(0) ; assume first index is time
   nlat=dims(1) ; assume second index latitude
   massgt = new( (/ nt /), double) 

   icesheet = ptr_surfdat->PCT_GLC_ICESHEET
   area     = ptr_surfdat->AREA
   landfrac = ptr_surfdat->LANDFRAC_PFT
   
   nh=new(dimsizes(icesheet),integer)
   nh(0:nlat/2,:) = 0
   nh(nlat/2+1:,:) = 1
   
   gis=mask(mask(icesheet,nh,1)/100., icesheet.ge.0., True)
   ais=mask(mask(icesheet,nh,0)/100., icesheet.ge.0., True)
   
   gis_mul_area = gis*area*landfrac
   ais_mul_area = ais*area*landfrac
   
   gis_area=sum(gis_mul_area)
   ais_area=sum(ais_mul_area)

   if(is_string.eq."AIS") then
      print("AIS area = "+ais_area)
      is_mul_area = ais_mul_area
   else if (is_string.eq."GIS") then
      print("GIS area = "+gis_area)
      is_mul_area = gis_mul_area
   else 
      print("ERROR: not implemented: "+is_string)
   end if
   end if

   do i=0,nt-1
      massgt(i) = sum(is_mul_area*field(i,:,:))
   end do

   ; factor to convert mm/s to Gt/yr
   ; account for area multiplication km^2
   fac = 86400 * 365 * 1.e-12 * 1.e6
   massgt = massgt * fac
   return(massgt)
end


