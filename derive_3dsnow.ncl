;
; LvK 19-NOV-2015
;
SCRIPT_DIR="/glade/u/home/lvank/analysis/libncl/" 
loadscript(SCRIPT_DIR+"interpolate_3dsnow.ncl")

;********************************************************
undef("derive_3dsnow_depth_average")
;
; Derive 3 dimensional snow variable averaged in depth [zmin,zmax]
;
function derive_3dsnow_depth_average(var_name:string,ptr:file,zmin,zmax,dz)
begin
   routine = "derive_3dsnow_depth_average()"
   sno_z = ptr->SNO_Z

   if(var_name.eq."SNO_BW") then
      var = ptr->SNO_BW
   end if

   if(var_name.eq."SNO_MELT_ICE") then
      var = ptr->SNO_MELT_ICE
   end if

   if(var_name.eq."SNO_FRZ_ICE") then
      var = ptr->SNO_FRZ_ICE
   end if

   ;var_int =  linint_3dsnow_layer(sno_z, zmin, zmax, dz, var) 
   var_int =  sample_3dsnow_layer(sno_z, zmin, zmax, dz, var) 
   print("max = "+ max(var_int))
   print("min = "+min(var_int))
   return(var_int)
end

;********************************************************
;
; From (T, LON, LAT) array with T=0:11 the months, calculate seasonal mean
;
undef("derive_3dsnow_seasonal")
function derive_3dsnow_seasonal(var_name:string,ptr:file,season:string)
begin
   ;var = derive_3dsnow(var_name,ptr)
   ;var := month_to_season(var,season)
   ;var!0 = "time"
   ;var!1 = "lat"
   ;var!2 = "lon"
   ;var&lat = ptr->lat
   ;var&lon = ptr->lon
   ;return var
   return 0
end
