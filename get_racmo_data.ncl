

load "/glade/u/home/lvank/analysis/libncl/list_utils.ncl"
load "/glade/u/home/lvank/analysis/libncl/monthly_to_season.ncl"


;********************************************************
undef("get_racmo_data_in_keyed_list_ann")
;
; Annual RACMO data
;  varlist  : list of variables to be selected
;  (ys,ye1) : period of interest
;
;********************************************************
function get_racmo_data_in_keyed_list_ann(varlist,ys1,ye1)
begin
   routine = "get_racmo_data_in_keyed_list_ann()"
   print(""+routine)

   ; location of data
   racmo_data = "/glade/p/work/lvank/racmo/racmo23_GRN_yearly/"

   ; start and end year of data
   ysr      = 1958
   yer      = 2013

   ; indices to be selected
   jms1     = (ys1-ysr)
   jme1     = (ye1-ysr)
   print("RACMO jms1,jme1 = "+jms1+", "+jme1)

   ret_list = NewList("fifo")

   do v = 0, dimsizes(varlist)-1,1
      var_name = varlist(v)
      print(""+var_name)
      
      ; variable name must match filename
      ptr := addfile(racmo_data+var_name+".YYYY.BN_1958_2013.YY.nc","r")
      lat = ptr->LAT
      lon = ptr->LON

      var = ptr->$var_name$
      var0 = dim_avg_n(var(jms1:jme1,:,:), (/ 0 /) )
      copy_VarMeta(var(0,:,:),var0)


      ; manually insert RACMO lat/lon coordinates for correct display
      var0@lat2d = lat
      var0@lon2d = lon

      ListPushWithKey(ret_list,var0,var_name+"_avg_"+"ANN")
   end do

   return ret_list
end


;********************************************************
undef("get_racmo_data_in_keyed_list")
;
; Monthly RACMO data averaged to season
;  varlist  : list of variables to be selected
;  (ys,ye1) : period of interest
;  seasons  : seasons of interest
;
;********************************************************
function get_racmo_data_in_keyed_list(varlist,ys1,ye1,seasons)
begin
   routine = "get_racmo_data_in_keyed_list()"
   print(""+routine)

   ; location of data
   racmo_data = "/glade/u/home/lvank/work/racmo/racmo23_GRN_monthly/"

   ; start and end year of data
   ysr      = 1958
   yer      = 2013

   ; indices to be selected ( full years)
   jms1     = (ys1-ysr)*12
   jme1     = (ye1-ysr+1)*12-1
   print("RACMO jms1,jme1 = "+jms1+", "+jme1)

   ret_list = NewList("fifo")

   do v = 0, dimsizes(varlist)-1,1
      var_name = varlist(v)
      print(""+var_name)

      if (var_name .eq. "runoff")
         print("WORKAROUND: NetCDF variable name 'rof' is used" )
         var_name0 := "rof"
      else 
         var_name0 := var_name
      end if

      do s = 0, dimsizes(seasons)-1,1
      season = seasons(s)

       ; variable name must match filename
      ptr := addfile(racmo_data+var_name+".1958-2013.BN_1958_2013.MM.nc","r")
      lat = ptr->LAT
      lon = ptr->LON

      var := ptr->$var_name0$
      var0 := var(jms1:jme1,:,:)

      ; calculate seasonal or annual mean
      if (season  .eq. "ANN") then
         var0 := month_to_annual(var0,1)
      else
         var0 := month_to_season(var0,season)
      end if

      var0 := dim_avg_n(var0(:,:,:), (/ 0 /) )
      copy_VarMeta(var(0,:,:),var0)
      var0 := rm_single_dims(var0) ; removes time dimension, http://www.ncl.ucar.edu/Document/Functions/Contributed/rm_single_dims.shtml

      ; manually insert RACMO lat/lon coordinates for correct display
      var0@lat2d = lat
      var0@lon2d = lon

      ; WORKAROUND : scale racmo fields by 12 to obtain annual values from monthly data
      if (var_name .eq. "smb" .or. \
         var_name .eq. "precip" .or. \
         var_name .eq. "snowmelt" .or. \
         var_name .eq. "snowfall" .or. \
         var_name .eq. "runoff" .or. \
         var_name .eq. "subl" ) then
         var0 = var0 * 12
      ;else if (var_name .eq. "runoff" ) then
      ;   ; mmWE / s to mmWE / yr
      ;   var0 = var0 * 365 * 86400
      ;end if
      end if

      ListPushWithKey(ret_list,var0,var_name+"_avg_"+season)
      end do
   end do
   return ret_list
end

