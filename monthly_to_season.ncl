;********************************************************
; LvK 17-Jan-2017
;
; This library exports the following functions: 
;
;  - get_variables_for_dataset()
;        returns list with data
;
;  - month_to_season_or_annual()
;        helper function 
;
;********************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/lvank/analysis/libncl/list_utils.ncl"
load "/glade/u/home/lvank/analysis/libncl/derive_land.ncl"


;********************************************************
undef("month_to_season_or_annual")
; 
; Extends function month_to_season with option 'ANN'
;
;********************************************************
function month_to_season_or_annual(var,season)
begin
   if (season  .eq. "ANN") then
      return month_to_annual(var,1)
   else
      return month_to_season(var,season)
   end if
end


;********************************************************
undef("get_variables_for_dataset")
;
; From a given file, retrieve a custom list (specific to this script) of variables and statistics (means)
;
;********************************************************
function get_variables_for_dataset(ptr_data:file,varlist:string,seasons:string)
local tsoi
begin
   routine="get_variables_for_dataset()"
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
          print("ERROR "+routine+" unknown season: "+season)
          exit()
      end if

      if(var_name .eq. "QSNOMELT_ICE" \
            .or. var_name .eq. "QSNOMELT" \
            .or. var_name .eq. "QSNOFRZ_ICE" \
            .or. var_name .eq. "QICE_MELT" \
            .or. var_name .eq. "QICE" \
            .or. var_name .eq. "QROFICE" \
            .or. var_name .eq. "QSOIL_ICE" \
            .or. var_name .eq. "QSOIL" \
            .or. var_name .eq. "QSNWCPICE" \
            .or. var_name .eq. "QSNWCPLIQ" \
            .or. var_name .eq. "RAIN" \
            .or. var_name .eq. "SNOW" \
            .or. var_name .eq. "RAIN_REPARTITIONED" \
            .or. var_name .eq. "SNOW_REPARTITIONED" \
            .or. var_name .eq. "QFLX_SNOW_DRAIN") then
         var   = ptr_data->$var_name$
         ; unit scaling: mm/s to mm/year
         var = var * (86400. * 365)
            ;var0 = var * (86400. * 365)
            ;copy_VarMeta(var,var0)
            ;var := var0
         xa := month_to_season_or_annual(var,season)

      else if(var_name .eq. "ROF") then
         ; liquid runoff
         melti = ptr_data->QICE_MELT
         melts = ptr_data->QFLX_SNOW_DRAIN
         var = melti + melts
         var = var * (86400. * 365)
         copy_VarMeta(melts,var)
         xa := month_to_season_or_annual(var,season)

      else if(var_name .eq. "TOTAL_MELT_ICE") then
         snowmelt   = ptr_data->QSNOMELT_ICE
         icemelt   = ptr_data->QICE_MELT
         var = snowmelt + icemelt
         ; unit scaling: mm/s to mm/year
         var = var * (86400. * 365)
         copy_VarMeta(snowmelt,var)
         xa := month_to_season_or_annual(var,season)

      else if(var_name .eq. "TOTAL_MELT") then
         snowmelt   = ptr_data->QSNOMELT
         icemelt   = ptr_data->QICE_MELT
         var = snowmelt + icemelt
         ; unit scaling: mm/s to mm/year
         var = var * (86400. * 365)
         copy_VarMeta(snowmelt,var)
         xa := month_to_season_or_annual(var,season)

      else if(var_name .eq. "TSOI_BOT") then 
         tsoi   := ptr_data->TSOI_ICE
         somevar   = ptr_data->QSNOMELT_ICE
         tsoi0 = new(dimsizes(somevar), float)
         tsoi0 = (/ tsoi(:,14,:,:) /)
         copy_VarMeta(somevar,tsoi0)
         xa := month_to_season_or_annual(tsoi0,season)

      else if(var_name .eq. "TSOI_TOP") then 
         tsoi   := ptr_data->TSOI_ICE
         somevar   = ptr_data->QSNOMELT_ICE
         tsoi0 = new(dimsizes(somevar), float)
         tsoi0 = (/ tsoi(:,0,:,:) /)
         copy_VarMeta(somevar,tsoi0)
         xa := month_to_season_or_annual(tsoi0,season)

      else if(var_name .eq. "RUNOFF_FRAC") then
         ; Fraction of meltwater that runs off
         snowmelt   = ptr_data->QSNOMELT_ICE
;         icemelt   = ptr_data->QICE_MELT
         runoff      = ptr_data->QFLX_SNOW_DRAIN

         snowmelt0   := month_to_season_or_annual(snowmelt,season)
         runoff0     := month_to_season_or_annual(runoff,season)

         print("before: "+num(snowmelt0))
         snowmelt0 = mask(snowmelt0,(snowmelt0 .eq. 0), False)
         print("after: "+num(snowmelt0))

         xa := (runoff0 / snowmelt0) * 100.
         copy_VarMeta(snowmelt0,xa)

      else if(var_name .eq. "REFR_FRAC") then
         snowmelt   = ptr_data->QSNOMELT_ICE
         runoff      = ptr_data->QFLX_SNOW_DRAIN

         snowmelt0   := month_to_season_or_annual(snowmelt,season)
         runoff0     := month_to_season_or_annual(runoff,season)

         snowmelt0 = mask(snowmelt0,(snowmelt0 .eq. 0), False)
         xa := (snowmelt0 - runoff0) / snowmelt0 * 100
         copy_VarMeta(snowmelt0,xa)

      else if(var_name .eq. "GHF") then
         ; FGR includes snow melt and ice melt. Subtract those to obtain 'pure' ground heat flux.
         ;  vars1['GHF'] = vars1['FGR'] + np.minimum(vars1['QICE'],0.0)*hfus - vars1['FSM']
         hfus = 3.337e5 ; heat of fusion  [J/kg]
         icemelt  = ptr_data->QICE_MELT
         fsm      = ptr_data->FSM
         fgr      = ptr_data->FGR
         icemelt0    := month_to_season_or_annual(icemelt,season)
         fsm0        := month_to_season_or_annual(fsm,season)
         fgr0        := month_to_season_or_annual(fgr,season)
         xa := fgr0 - hfus * icemelt0  - fsm0
         ;ghf0 = fgr0 - fsm0
         copy_VarMeta(fsm0,xa)

      else if(var_name .eq. "H2OSNO") then
         ; convert from mm to m
         var0   := ptr_data->$var_name$ 
         xa := month_to_season_or_annual(var0,season) 
         xa = xa * 0.001

      else if(var_name .eq. "CAM_RAIN") then
         ; NOTE: NOT TESTED YET
         precc   := ptr_data->PRECC
         precl   := ptr_data->PRECL
         precsc   := ptr_data->PRECSC
         precsl   := ptr_data->PRECSL

         cam_rain = precc + precl - precsc - precsl
         copy_VarMeta(precc,cam_rain)
         xa   := month_to_season_or_annual(cam_rain,season)
         ; convert from m/s to mm/yr
         xa = xa * 3600 * 24. * 365 * 1000

      else if(var_name .eq. "CAM_SNOW") then
         ; NOTE: NOT TESTED YET
         precsc   := ptr_data->PRECSC
         precsl   := ptr_data->PRECSL

         cam_snow = precsc + precsl
         copy_VarMeta(precsc,cam_snow)
         xa   := month_to_season_or_annual(cam_snow,season)
         ; convert from m/s to mm/yr
         xa = xa * 3600 * 24. * 365 * 1000

      else if (var_name .eq. "LWP") then
         ; liquid water path
         var0   := ptr_data->TGCLDLWP
         xa := month_to_season_or_annual(var0,season)
         xa = xa * 1000 ; convert kg to g 

      else if (var_name .eq. "IWP") then
         ; liquid water path
         var0   := ptr_data->TGCLDIWP
         xa := month_to_season_or_annual(var0,season)
         xa = xa * 1000 ; convert kg to g 

      else if (var_name .eq. "ALBEDO") then
         var := derive_land(var_name,ptr_data)
         xa := month_to_season_or_annual(var,season)

      else 
         var0   := ptr_data->$var_name$
         xa := month_to_season_or_annual(var0,season)

      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if

      xa := rm_single_dims(xa) ; removes time dimension, http://www.ncl.ucar.edu/Document/Functions/Contributed/rm_single_dims.shtml
      ;print(dimsizes(xa))
      ListPushWithKey(ret_list,xa,var_name+"_avg_"+season)

   end do ; season
   end do ; varlist
   return ret_list
end 


