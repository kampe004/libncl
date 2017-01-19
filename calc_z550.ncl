
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "../libncl/list_utils.ncl"
load "../libncl/interpolate_3dsnow.ncl"
load "../libncl/size.ncl"


;********************************************************
begin
   f_msk = addfile("/glade/u/home/lvank/analysis/maskers.nc", "r") ; 1 degree mask

   data_dir = "/glade/u/home/lvank/scratch/archive/avg2/" ; location of case history output
   varname_out = "z550" 
   ;period   = "1996-2000"
   period   = "2010-2014"

   ;cases = (/ "tr_eraimod_5_cap", "tr_eraimod_12_cap_wnd2topfix" /) 
   ;cases = (/ "clm117_eraimod_default", "clm117_eraimod_wnd", "clm117_eraimod_wnd_dm150", "clm117_eraimod_wnd_crocus" /)
   cases = (/ "clm117_eraimod_wnd_crocus", "clm117_eraimod_wnd_crocus_dm150" /)

   do icase = 0, dimsizes(cases)-1,1
      case = cases(icase)
      print("case = "+case)

      in = data_dir+"/"+case+"/"+period+"/"+case+"_ymonmean.nc"
      fin=addfile(in,"r")

      sno_z := fin->SNO_Z
      var   := fin->SNO_BW

      ; read dimensions
      dims  = dimsizes(var)
      nt    = dims(0)
      nlev  = dims(1)
      nlat  = dims(2)
      nlon  = dims(3)

      print("nt = "+nt)
      print("nlev = "+nlev)
      print("nlat = "+nlat)
      print("nlon = "+nlon)

      cval = 550.
      z550 =  linint_3dsnow_cval(sno_z, cval, var)

      seasons = (/ "ANN", "DJF", "MAM", "JJA", "SON" /)
      do iseason = 0, dimsizes(seasons)-1
         season = seasons(iseason)
         out = data_dir+"/"+case+"/"+period+"/"+case+"_"+varname_out+"_"+season+".nc"
         system("rm "+out)
         fout:=addfile(out,"cw")
         print("Writing "+out)

         dim_names = (/"time","lat","lon"/)
         dim_sizes = (/1,nlat,nlon/) ;time dimension is unlimited, but currently set to 1.
         dim_unlimited = (/True,False,False/)
         filedimdef(fout, dim_names, dim_sizes, dim_unlimited)
   
         filevardef(fout,"time","double","time")
         filevardef(fout,"lat","double","lat")
         filevardef(fout,"lon","double","lon")
         fout->time  = (/ 0. /)
         fout->lat   = fin->lat
         fout->lon   = fin->lon
   
   
         tatts = True
         tatts@long_name = "elapsed time"
         tatts@units = "hours since 01-01-2000"
         filevarattdef(fout,"time",tatts)
   
         ;latatts = True
         ;latatts@long_name = "latitude"
         ;latatts@units = "degrees_north"
         ;filevarattdef(fout,"lat",latatts)
   
         ;lonatts = True
         ;lonatts@long_name = "longitude"
         ;lonatts@units = "degrees_east"
         ;filevarattdef(fout,"lon",lonatts)
   
         atts = True
         atts@long_name = "depth of 550 kg/m3"
         atts@units = "kg/m3"
         filevardef(fout,"z550","float",(/"time","lat","lon"/))
         filevarattdef(fout,"z550",atts)
   
         ; ----------------------------------------------
         ; output phase
         ; ----------------------------------------------
         if (season .eq. "ANN")
            z550_s := month_to_annual(z550,1)
         else
            z550_s = month_to_season(z550,season)
         end if
         print(dimsizes(fout->z550))
         print(dimsizes(z550_s))
         fout->z550 = (/ z550_s /)

      end do ; seasons
   end do ; cases
end

