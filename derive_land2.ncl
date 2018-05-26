; LvK 19-JAN-2017
;
; extends function derive_land() with units scaling
; if no match is found, the function derive_land() is called
;

load "/glade/u/home/lvank/analysis/libncl/derive_land.ncl"

;********************************************************
undef("derive_land2")
;
;  Read named standard variable from file pointer
;     -or-
;  calculate derived variable based on standard variables.
;  Variables are scaled to standard units (mm/Yr etc)
;  ( this is the main difference to derive_land)
;
;  var_name    : variable name 
;  ptr         : file pointer
;
;********************************************************
function derive_land2(var_name:string,ptr:file)
begin
   routine = "derive_land2()"

   if(var_name.eq."ALBEDO" .or. var_name .eq. "ASA" .or. var_name .eq. "ALL_SKY_ALBEDO" )then
      ; albedo between [0, 1]
      var = derive_land(var_name,ptr)
      var = var * 0.01
      return(var)
   end if

   if(var_name.eq."ALBEDO_ICE") then
      ; albedo between [0, 1]
      var = derive_land(var_name,ptr)
      var = var * 0.01
      return(var)
   end if


   if (var_name.eq."TOTAL_MELT") then
      smelt = derive_land2("QSNOMELT",ptr)
      imelt = derive_land2("QICE_MELT",ptr)
      var = imelt + smelt
      copy_VarMeta(smelt,var)
      return(var)
   end if

   if(var_name .eq. "TOTAL_MELT_ICE") then
      smelt = derive_land2("QSNOMELT_ICE",ptr)
      imelt = derive_land2("QICE_MELT",ptr)
      var = imelt + smelt
      copy_VarMeta(smelt,var)
      return(var)
   end if

   ; standard mass fluxes
   if(var_name .eq. "QSNOMELT_ICE" \
        .or. var_name .eq. "QSNOMELT" \
        .or. var_name .eq. "QSNOFRZ" \
        .or. var_name .eq. "QSNOFRZ_ICE" \
        .or. var_name .eq. "QICE_MELT" \
        .or. var_name .eq. "QICE" \
        .or. var_name .eq. "QROFICE" \
        .or. var_name .eq. "QSOIL_ICE" \
        .or. var_name .eq. "QSOIL" \
        .or. var_name .eq. "QSNWCPICE" \
        .or. var_name .eq. "QSNWCPLIQ" \
        .or. var_name .eq. "QRUNOFF" \
        .or. var_name .eq. "QRUNOFF_TO_COUPLER" \
        .or. var_name .eq. "RAIN" \
        .or. var_name .eq. "SNOW" \
        .or. var_name .eq. "PRECC" \
        .or. var_name .eq. "PRECL" \
        .or. var_name .eq. "PRECSC" \
        .or. var_name .eq. "PRECSL" \
        .or. var_name .eq. "RAIN_REPARTITIONED" \
        .or. var_name .eq. "SNOW_REPARTITIONED" \
        .or. var_name .eq. "QFLX_SNOW_DRAIN") then
     var   = ptr->$var_name$
     ; unit scaling: mm/s to mm/year
     var = var * (86400. * 365)
     return(var)
   end if

   ; liquid runoff
   if(var_name .eq. "ROF") then
      imelt = derive_land2("QICE_MELT",ptr)
      smelt = derive_land2("QFLX_SNOW_DRAIN",ptr)
      var = imelt + smelt
      copy_VarMeta(smelt,var)
      return(var)

      ;var = derive_land2("QRUNOFF_TO_COUPLER",ptr)
      ;return(var)
   end if

   if(var_name .eq. "GHF") then
      ; FGR includes snow melt and ice melt. Subtract those to obtain 'pure' ground heat flux GHF.
      ;  vars1['GHF'] = vars1['FGR'] + np.minimum(vars1['QICE'],0.0)*hfus - vars1['FSM']
      hfus = 3.337e5 ; heat of fusion  [J/kg]
      icemelt  = ptr->QICE_MELT
      fsm      = ptr->FSM
      fgr      = ptr->FGR
      grf = fgr - hfus*icemelt - fsm
      copy_VarMeta(fgr,grf)
      return(grf)
   end if

   if(var_name .eq. "MHEAT") then
      ; MHEAT is total melt heat
      ; var_dict['MHEAT']   = var_dict['FSM_ICE'] + var_dict['QICE_MELT']*hfus
      hfus = 3.337e5 ; heat of fusion  [J/kg]
      icemelt  = ptr->QICE_MELT
      fsm      = ptr->FSM
      mheat = fsm
      mheat = fsm + hfus*icemelt
      copy_VarMeta(fsm,mheat)
      return(mheat)
   end if

   if(var_name .eq. "GHF_ICE") then
      ; FGR includes snow melt and ice melt. Subtract those to obtain 'pure' ground heat flux.
      ;  vars1['GHF'] = vars1['FGR'] + np.minimum(vars1['QICE'],0.0)*hfus - vars1['FSM']
      hfus = 3.337e5 ; heat of fusion  [J/kg]
      icemelt  = ptr->QICE_MELT
      fsm      = ptr->FSM_ICE
      fgr      = ptr->FGR_ICE
      grf = fgr - hfus*icemelt - fsm
      copy_VarMeta(fgr,grf)
      return(grf)
   end if

   if(var_name .eq. "H2OSNO") then
      ; convert from mm to m
      var0   := ptr->$var_name$ 
      var0 = var0 * 0.001
      return(var0)
   end if

   if(var_name .eq. "CAM_PREC") then
      precc   := ptr->PRECC
      precl   := ptr->PRECL

      cam_prec = precc + precl
      copy_VarMeta(precc,cam_prec)
      ; convert from m/s to mm/yr
      cam_prec = cam_prec * 3600 * 24. * 365 * 1000
      return(cam_prec)
   end if


   if(var_name .eq. "CAM_RAIN") then
      precc   := ptr->PRECC
      precl   := ptr->PRECL
      precsc   := ptr->PRECSC
      precsl   := ptr->PRECSL

      cam_rain = precc + precl - precsc - precsl
      copy_VarMeta(precc,cam_rain)
      ; convert from m/s to mm/yr
      cam_rain = cam_rain * 3600 * 24. * 365 * 1000
      return(cam_rain)
   end if

   if(var_name .eq. "CAM_SNOW") then
      precsc   := ptr->PRECSC
      precsl   := ptr->PRECSL

      cam_snow = precsc + precsl
      copy_VarMeta(precsc,cam_snow)
      ; convert from m/s to mm/yr
      cam_snow = cam_snow * 3600 * 24. * 365 * 1000
      return(cam_snow)
   end if

   if (var_name .eq. "LWP") then
      ; liquid water path
      var   := ptr->TGCLDLWP
      var = var * 1000 ; convert kg to g 
      return(var)
   end if

   if (var_name .eq. "IWP") then
      ; liquid water path
      var   := ptr->TGCLDIWP
      var = var * 1000 ; convert kg to g 
      return(var)
   end if

   ; no match
   var = derive_land(var_name,ptr)
   return var
end
