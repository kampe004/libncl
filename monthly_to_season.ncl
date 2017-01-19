; LvK 17-Jan-2017

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/lvank/analysis/libncl/list_utils.ncl"
load "/glade/u/home/lvank/analysis/libncl/derive_land2.ncl"



;********************************************************
undef("get_variables_in_keyed_list")
;
; From a given file, retrieve a custom list (specific to this script) of variables and statistics (means)
;
;********************************************************
function get_variables_in_keyed_list(ptr_data:file,varlist:string,seasons:string)
local tsoi
begin
   routine="get_variables_in_keyed_list()"
   print(""+routine)
   ret_list = NewList("fifo")
   sec_in_day = 86400

   do v = 0, dimsizes(varlist)-1,1
      var_name = varlist(v)
      print("var = "+var_name)

      do s = 0, dimsizes(seasons)-1,1
      season = seasons(s)

         if (season .ne. "ANN" .and. \
             season .ne. "DJF" .and. \
             season .ne. "MAM" .and. \
             season .ne. "JJA" .and. \
             season .ne. "SON") then
             print("ERROR: "+routine+" unknown season: "+season)
             exit()
         end if

         ; read data, do scaling to standard units
         var = derive_land2(var_name, ptr_data) 

         ; calculate seasonal or annual mean
         if (season  .eq. "ANN") then
            xa := month_to_annual(var,1)
         else
            xa := month_to_season(var,season)
         end if

         ; removes singular time dimension, http://www.ncl.ucar.edu/Document/Functions/Contributed/rm_single_dims.shtml
         xa := rm_single_dims(xa) 

         ; add to List
         ListPushWithKey(ret_list,xa,var_name+"_avg_"+season)

      end do ; season
   end do ; varlist
   return ret_list
end 

;********************************************************
undef("get_seasonal_mean_data")
function get_seasonal_mean_data(var_name:string,ptr:file,season:string)
; From (T, LON, LAT) array with T=0:11 the months, calculate seasonal mean
begin
   var = derive_land(var_name,ptr)
   var := month_to_season(var,season)
   var!0 = "time"
   var!1 = "lat"
   var!2 = "lon"
   var&lat = ptr->lat
   var&lon = ptr->lon
   return var
end

;********************************************************
undef("get_annual_mean_data")
function get_annual_mean_data(var_name:string,ptr:file)
; From (T, LON, LAT) array with T=0:11 the months, calculate annual mean
begin
   var = derive_land(var_name,ptr)
;   opt=0 ; sum
   opt=1 ; average
   var := month_to_annual(var,opt)
   var!0 = "time"
   var!1 = "lat"
   var!2 = "lon"
   var&lat = ptr->lat
   var&lon = ptr->lon
   return var
end


