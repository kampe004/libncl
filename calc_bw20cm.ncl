
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
   varname  = "SNO_BW" ; variable to interpolate
   varname_out = "BW20CM" 
   ;varname  = "SNO_T" ; variable to interpolate
   ;varname_out = "T20CM" 
   period   = "0044-0048"
   ;period   = "1990-1999"
   ;period   = "2010-2014"

   zmin = 0.19 ; m
   zmax = 0.21 ; m
   dz = 0.02 ; sampling interval

   ;cases = (/ "tr_eraimod_5_cap", "clm117_eraimod_wnd_crocusdrift_dm175_cn450"/) 
   cases = (/ "clm117_sp_1m_tsoil", "clm117_sp_10m_tsoil" /)
   ;, "clm117_eraimod_wnd", "clm117_eraimod_wnd_dm150", "clm117_eraimod_wnd_crocus", "clm117_eraimod_wnd_crocus_dm150", "clm117_eraimod_wnd_crocusdrift_dm150" /)

   do icase = 0, dimsizes(cases)-1,1
      case = cases(icase)
      print("case = "+case)

      in = data_dir+"/"+case+"/"+period+"/"+case+"_ymonmean.nc"
      fin=addfile(in,"r")

      sno_z := fin->SNO_Z
      var   := fin->$varname$

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

      varavg     :=  sample_3dsnow_layer(sno_z, zmin, zmax, dz, var) 

      ; output monthly means
      ; BWSKIN_<casename>_ymonmean.nc
      out = data_dir+"/"+case+"/"+period+"/"+varname_out+"_"+case+"_ymonmean.nc"
      system("rm "+out)
      fout:=addfile(out,"cw")
      print("Writing "+out)
      dim_names = (/"time","lat","lon"/)
      dim_sizes = (/12,nlat,nlon/) ;time dimension is unlimited, but currently set to 1.
      dim_unlimited = (/True,False,False/)
      filedimdef(fout, dim_names, dim_sizes, dim_unlimited)

      ;filevardef(fout,"time","double","time")
      filevardef(fout,"lat","double","lat")
      filevardef(fout,"lon","double","lon")
      fout->time  = fin->time
      fout->lat   = fin->lat
      fout->lon   = fin->lon

      tatts = True
      tatts@long_name = "elapsed time"
      tatts@units = "hours since 01-01-2000"
      ;filevarattdef(fout,"time",tatts)

      atts = True
      atts@long_name = var@long_name
      atts@units = var@units
      filevardef(fout,varname_out,"float",(/"time","lat","lon"/))
      filevarattdef(fout,varname_out,atts)

      fout->$varname_out$ = (/ varavg /)


      ; output seasonal averages
      seasons = (/ "ANN", "DJF", "MAM", "JJA", "SON" /)
      do iseason = 0, dimsizes(seasons)-1
         season = seasons(iseason)
         out = data_dir+"/"+case+"/"+period+"/"+varname_out+"_"+case+"_"+season+".nc"
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
         atts@long_name = var@long_name
         atts@units = var@units
         filevardef(fout,varname_out,"float",(/"time","lat","lon"/))
         filevarattdef(fout,varname_out,atts)
   
         ; ----------------------------------------------
         ; output phase
         ; ----------------------------------------------
         if (season .eq. "ANN")
            varavg_s := month_to_annual(varavg,1)
         else
            varavg_s = month_to_season(varavg,season)
         end if
         print(dimsizes(fout->$varname_out$))
         print(dimsizes(varavg_s))
         fout->$varname_out$ = (/ varavg_s /)

      end do ; seasons
   end do ; cases
end

