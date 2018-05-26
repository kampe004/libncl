; LvK 5-NOV-2015
; Updated 18-Jan-2017
; Based on lnd_diag4.2.28/code/shared/lnd_func.ncl
;
; Only 'special' cases are implemented -- by default the standard variable 
; is returned (this behaviour is different from the diagnostic package). 
;
; To scale variables to standard meteorological units, use derive_land2.ncl

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" ; copy_VarMeta

;********************************************************
undef("derive_land")
function derive_land(var_name:string,ptr:file)
; derive various variables
begin
   routine = "derive_land()"

   if(var_name.eq."ALBEDO" .or. var_name .eq. "ASA" .or. var_name .eq. "ALL_SKY_ALBEDO" )then
      ; albedo as percentage, for backwards compatibility
      fsr  = ptr ->FSR
      fsds = ptr ->FSDS
      var  = fsr                  ; trick to retain meta data
      if (any(fsds .eq. 0)) then  ; set zeros to _FillValue
         fsds = mask(fsds,(fsds .eq. 0),False)
      end if
      var  = ( fsr/fsds ) * 100.
      return(var)
   end if

   if(var_name.eq."ALBEDO_ICE" )then
      ; albedo as percentage, for backwards compatibility
      fsr  = ptr ->FSR_ICE
      fsds = ptr ->FSDS
      var  = fsr                  ; trick to retain meta data
      if (any(fsds .eq. 0)) then  ; set zeros to _FillValue
         fsds = mask(fsds,(fsds .eq. 0),False)
      end if
      var  = ( fsr/fsds ) * 100.
      return(var)
   end if


   if(var_name.eq."TOPO_MEC")then
      print("WARNING: do not trust TOPO_MEC from "+routine+" as it is hardcoded, not version dependent!")

      ptr_mec=addfile("/glade/p/cesmdata/cseg/inputdata/lnd/clm2/surfdata_map/surfdata_1.9x2.5_16pfts_simyr2000_c151014.nc","r")
      nmec = 10
      topo      = ptr->TOPO
      topo_mec  = ptr_mec->TOPO_GLC_MEC
      pct_glc   = ptr_mec->PCT_GLACIER
      pct_glc = pct_glc / 100. ; convert to unit scale
      pct_glc_mec   = ptr_mec->PCT_GLC_MEC
      pct_glc_mec = pct_glc_mec / 100. ; convert to unit scale
      ; average height in a gridcell with GLCMEC is the weighted average of all the classes, and other landunits (we assume TOPO for these)
      topo_mec_avg = topo
      topo_mec_avg = topo*0.0
      do i = 0, nmec-1
        topo_mec_avg = topo_mec_avg + topo_mec(i,:,:)*pct_glc_mec(i,:,:)
      end do
      var = topo
      var = (1.0-pct_glc)*topo + pct_glc * topo_mec_avg
      return(var)
   end if

   if(var_name.eq."PCT_GLC")then
      var=ptr->PCT_GLACIER
      return(var)
   end if

   ;if(var_name.eq."QICE_MELT")then
   ;   if (isfilevar(ptr, "QICE_MELT")) then
   ;      var=ptr->QICE_MELT
   ;   else
   ;      var=new(dimsizes( ptr->FSR),float)
   ;      var=0.0
   ;   end if
   ;   return(var)
   ;end if

   if(var_name.eq."PCT_GLC_MEC")then
      nmec = 10
      pct_glc      = ptr->PCT_GLACIER
      pct_glc_mec  = ptr->PCT_GLC_MEC
      var = pct_glc
      var = 0.0
      do i = 0, nmec-1
        var = var + pct_glc_mec(i,:,:)
      end do
      return(var)
   end if

   if(var_name.eq."DUST_TOP")then
      var=ptr->SNODSTMSL
      return(var)
   end if

   if(var_name.eq."DUST_COL")then
      var=ptr->SNODSTMCL
      return(var)
   end if

   if(var_name.eq."SNOBWTOPL")then
      bw=ptr->SNO_BW
      dims = getfilevardims(ptr,"SNO_BW")
;      printVarSummary(bw)
      var=bw(time|:,lat|:,lon|:,$dims(1)$|0)
      return(var)
   end if

   if(var_name.eq."FGR_MIN_FSM")then
      fgr=ptr->FGR
      fsm=ptr->FSM
      var = fgr
      var = fgr-fsm
      return(var)
   end if

   if(var_name.eq."CARBON_DEP")then
      bc=ptr->BCDEP
      oc=ptr->OCDEP
      var=bc
      var=bc+oc
      return(var)
   end if

   if(var_name.eq."CARBON_TOP")then
      bc=ptr->SNOBCMSL
      oc=ptr->SNOOCMSL
      var=bc
      var=bc+oc
      return(var)
   end if

   if(var_name.eq."CARBON_COL")then
      bc=ptr->SNOBCMCL
      oc=ptr->SNOOCMCL
      var=bc
      var=bc+oc
      return(var)
   end if

   if(var_name.eq."REFREEZE")then
      var=ptr->QSNOFRZ
      return(var)
   end if

   ;if(var_name.eq."RAIN_REPAR")then
   ;   rain=ptr->RAIN_REPARTITIONED
   ;   return(rain)
   ;end if

   ;if(var_name.eq."SNOW_REPAR")then
   ;   rain=ptr->SNOW_REPARTITIONED
   ;   return(rain)
   ;end if

   if(var_name.eq."LIQUID_TOT")then
      rain=ptr->RAIN_REPARTITIONED
      melt=ptr->QSNOMELT
      var = rain
      var = rain+melt
      return(var)
   end if

   if(var_name.eq."RUNOFF_TOT")then
      snwcp=ptr->QSNWCPICE
      runoff=ptr->QRUNOFF
      var = snwcp
      var = snwcp+runoff
      return(var)
   end if

   if (var_name.eq."TOTAL_MELT") then
      ice_melt = derive_land("QSNOMELT",ptr)
      snw_melt = derive_land("QICE_MELT",ptr)
      var = ice_melt
      var = ice_melt + snw_melt
      return(var)
   end if

   if(var_name .eq. "TSOI_BOT") then 
      print("WARNING: "+routine+" TSOI_BOT assumes 15 soil layers")
      tsoi   := ptr->TSOI_ICE
      somevar   = ptr->QSNOMELT
      tsoi0 = new(dimsizes(somevar), float)
      tsoi0 = (/ tsoi(:,14,:,:) /)
      copy_VarMeta(somevar,tsoi0)
      return(tsoi0)
   end if

   if(var_name .eq. "TSOI_TOP") then 
      tsoi   := ptr->TSOI_ICE
      somevar   = ptr->QSNOMELT
      tsoi0 = new(dimsizes(somevar), float)
      tsoi0 = (/ tsoi(:,0,:,:) /)
      copy_VarMeta(somevar,tsoi0)
      return(tsoi0)
   end if

   if(var_name .eq. "SWTRANS") then 
      ; SW transmissivity = SWd / SWd,toa
      print("WARNING: using variable FSDS, this should be from CAM not CLM")
      swn_toa   := ptr->FSNTOA
      swu_toa   := ptr->FSUTOA
      swd_toa = swn_toa + swu_toa
      if (any(swd_toa .eq. 0)) then  ; set zeros to _FillValue
         swd_toa = mask(swd_toa,(swd_toa .eq. 0),False)
      end if
      swd_sfc  := ptr->FSDS
      trans = swd_sfc / swd_toa
      copy_VarMeta(swd_sfc,trans)
      return(trans)
   end if

   if(var_name .eq. "NETCF") then 
      ; net cloud forcing
      swcf   := ptr->SWCF
      lwcf   := ptr->LWCF
      netcf = swcf + lwcf
      copy_VarMeta(swcf,netcf)
      return(netcf)
   end if

   if(var_name .eq. "NETRAD") then 
      ; net radiation
      swa   := ptr->FSA
      lwa   := ptr->FIRA
      netrad = swa - lwa ; FIRA negative towards the surface
      copy_VarMeta(swa,netrad)
      return(netrad)
   end if

   if(var_name .eq. "WIND_DC") then 
      ; directional constancy
      ; dc = sqrt(u**2 + v**2) / V
      uu   := ptr->UU
      vv   := ptr->VV
      u    := ptr->U
      v    := ptr->V
      dc = sqrt(u*u + v*v) / sqrt(uu + vv)
      copy_VarMeta(u,dc)
      return(dc)
   end if



   ; no match with any special case
   var = ptr->$var_name$
   return (var)

; if derived variable is not found, return an array of missing values.
; this is check for in the set code. size is irrelevant as long as
; the array is greater than 1.
;  var = new(20,"float")
;  print("ERROR: "+routine+": variable not implemented: "+var_name)
;  return(var)

end
