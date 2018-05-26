; LvK 30-OCT-2017
;
; extends function derive_land2() with automatic calculation of seasonal mean
; the 4 standard seasons are supported, as well as 'ANN' and 'MONTHLY', for convenience
; 
load "/glade/u/home/lvank/analysis/libncl/derive_land2.ncl"
load "/glade/u/home/lvank/analysis/libncl/month_to_season_LvK.ncl" ; overwrite month_to_season with custom implementation that support unstructured grids

undef("derive_land_season")
function derive_land_season(var_name:string,ptr:file,season:string)
begin
   routine = "derive_land_season()"
   if (season .ne. "ANN" .and. \
       season .ne. "DJF" .and. \
       season .ne. "MAM" .and. \
       season .ne. "JJA" .and. \
       season .ne. "SON" .and. \
       season .ne. "MONTHLY") then
       print("ERROR: "+routine+" unknown season: "+season)
       exit()
   end if

   ; read data, do scaling to standard units
   var = derive_land2(var_name, ptr) 

   ; calculate seasonal or annual mean
   if (season  .eq. "ANN") then
      xa := month_to_annual(var,1)
   else if (season .eq. "MONTHLY") then
      xa := var
   else
      xa := month_to_season(var,season)
   end if
   end if

   ; removes singular time dimension, http://www.ncl.ucar.edu/Document/Functions/Contributed/rm_single_dims.shtml
   xa := rm_single_dims(xa) 
   ;print(var_name+", "+dimsizes(xa))
   return(xa)
end
