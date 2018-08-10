

load "/glade/u/home/lvank/analysis/libncl/list_utils.ncl"
load "/glade/u/home/lvank/analysis/libncl/monthly_to_season.ncl"


;********************************************************
undef("get_racmo_data_in_keyed_list_ann")
;
; Annual RACMO 2.3 data
;  varlist  : list of variables to be selected
;  (ys,ye1) : period of interest
;
;********************************************************
function get_racmo_data_in_keyed_list_ann(varlist,ys1,ye1)
begin
   routine = "get_racmo_data_in_keyed_list_ann()"
   print(""+routine)

   ; location of data
   ;racmo_data = "/glade/p/work/lvank/racmo/racmo23_GRN_yearly/"
   racmo_data = "/glade/p_old/work/lvank/racmo/racmo23_GRN_yearly/" ; July 2018

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
undef("get_racmo_data_in_keyed_list_version")
;
; Monthly RACMO data averaged to season
;  varlist  : list of variables to be selected
;  (ys,ye1) : period of interest
;  seasons  : seasons of interest
; version   : string with version number (2.3 , 2.3p2)
;
;********************************************************
function get_racmo_data_in_keyed_list_version(varlist,ys1,ye1,seasons, version)
local version, routine, ysr, yer, racmo_data
begin
   routine = "get_racmo_data_in_keyed_list_version()"
   print(""+routine)

   if (version .eq. "2.3") then
      ; location of data
      racmo_data = "/glade/u/home/lvank/work/racmo/racmo23_GRN_monthly/"
      ; start and end year of data
      ysr      = 1958
      yer      = 2013
   else if (version .eq. "2.3p2") then
      ; location of data
      ;racmo_data = "/glade/p/work/lvank/racmo/racmo23p2_GRN_monthly/"
      racmo_data = "/glade/work/lvank/racmo/racmo23p2_GRN_monthly/" ; new location July 2018
      ; start and end year of data
      ysr      = 1961
      yer      = 1990
   else 
      print("ERROR: unsupported version: "+version)
      exit()
   end if
   end if

   ; indices to be selected ( full years)
   jms1     = (ys1-ysr)*12
   jme1     = (ye1-ysr+1)*12-1
   print("RACMO jms1,jme1 = "+jms1+", "+jme1)

   ret_list = NewList("fifo")

   if (version .eq. "2.3p2") then
      ; workaround: LAT, LON are corrupted in MM files
      ptr := addfile(racmo_data+"latlon.nc","r")
      lat = ptr->LAT
      lon = ptr->LON
   end if

   do v = 0, dimsizes(varlist)-1,1
      var_name = varlist(v)
      print(""+var_name)
      var_name0 := var_name

      do s = 0, dimsizes(seasons)-1,1
      season = seasons(s)

       ; variable name must match filename
      ptr := addfile(racmo_data+var_name+".1961-1990.BN_RACMO2.4_FGRN11.MM.nc","r")
      if (version .ne. "2.3p2") then
         lat = ptr->LAT
         lon = ptr->LON
      end if

      var := ptr->$var_name0$
      dims=dimsizes(var)
      ;print(dims)
      var0 := var(jms1:jme1,:,:)

      ; calculate seasonal or annual mean
      if (season  .eq. "ANN") then
         var0 := month_to_annual(var0,1)
         var0 := dim_avg_n(var0(:,:,:), (/ 0 /) )
         copy_VarMeta(var(0,:,:),var0)
         var0 := rm_single_dims(var0) ; removes time dimension, http://www.ncl.ucar.edu/Document/Functions/Contributed/rm_single_dims.shtml
      else if (season  .eq. "MONTHLY") then
         var0 := clmMonTLL(var0)
      else
         var0 := month_to_season(var0,season)
         var0 := dim_avg_n(var0(:,:,:), (/ 0 /) )
         copy_VarMeta(var(0,:,:),var0)
         var0 := rm_single_dims(var0) ; removes time dimension, http://www.ncl.ucar.edu/Document/Functions/Contributed/rm_single_dims.shtml
      end if
      end if

      ; manually insert RACMO lat/lon coordinates for correct display
      var0@lat2d = lat
      var0@lon2d = lon

      ; WORKAROUND : scale racmo mass fields by 12 to obtain annual values from monthly data
      if (var_name .eq. "smb" .or. \
         var_name .eq. "precip" .or. \
         var_name .eq. "snowmelt" .or. \
         var_name .eq. "snowfall" .or. \
         var_name .eq. "runoff" .or. \
         var_name .eq. "refr" .or. \
         var_name .eq. "subl" ) then
         print("INFO: RACMO var "+var_name+" is scaled by 12")
         var0 = var0 * 12
      end if

      ListPushWithKey(ret_list,var0,var_name+"_avg_"+season)
      end do
   end do
   return ret_list
end


;********************************************************
undef("get_racmo_data_in_keyed_list")
;
; convenience wrapper function 
;
; Monthly RACMO 2.3 data averaged to season
;  varlist  : list of variables to be selected
;  (ys,ye1) : period of interest
;  seasons  : seasons of interest
;
;********************************************************
function get_racmo_data_in_keyed_list(varlist,ys1,ye1,seasons)
local routine, xlist
begin
   routine = "get_racmo_data_in_keyed_list()"
   print(""+routine)
   xlist = get_racmo_data_in_keyed_list_version(varlist,ys1,ye1,seasons,"2.3")
   return(xlist)
end


;********************************************************
undef("get_racmo23p2_data_in_keyed_list")
;
; convenience wrapper function 
;
; Monthly RACMO 2.3p2 data averaged to season
;  varlist  : list of variables to be selected
;  (ys,ye1) : period of interest
;  seasons  : seasons of interest
;
;********************************************************
function get_racmo23p2_data_in_keyed_list(varlist,ys1,ye1,seasons)
begin
   routine = "get_racmo23p2_data_in_keyed_list()"
   print(""+routine)
   xlist = get_racmo_data_in_keyed_list_version(varlist,ys1,ye1,seasons,"2.3p2")
   return(xlist)
end

