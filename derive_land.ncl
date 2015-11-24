
; LvK 5-NOV-2015
; Based on lnd_diag4.2.28/code/shared/lnd_func.ncl

;********************************************************
undef("derive_land")
function derive_land(var_name:string,ptr:file)
; derive various variables
begin

  routine = "derive_land"

  if(var_name.eq."ALBEDO" .or. var_name .eq. "ASA" .or. var_name .eq. "ALL_SKY_ALBEDO" )then
    fsr  = ptr ->FSR
    fsds = ptr ->FSDS
    var  = fsr                  ; trick to retain meta data
    if (any(fsds .eq. 0)) then  ; set zeros to _FillValue
      fsds = mask(fsds,(fsds .eq. 0),False)
    end if
    var  = ( fsr/fsds ) * 100.
    return(var)
  end if

  if(var_name.eq."TOPO_MEC")then

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

  if(var_name.eq."TOPO")then
     var=ptr->TOPO
     return(var)
  end if

  if(var_name.eq."PCT_GLC")then
     var=ptr->PCT_GLACIER
     return(var)
  end if

  if(var_name.eq."TG")then
     var=ptr->TG
     return(var)
  end if

  if(var_name.eq."QICE_MELT")then
     if (isfilevar(ptr, "QICE_MELT")) then
        var=ptr->QICE_MELT
     else
        var=new(dimsizes( ptr->FSR),float)
        var=0.0
     end if
     return(var)
  end if

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

  if(var_name.eq."DSTDEP")then
     var=ptr->DSTDEP
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

  if(var_name.eq."FSM")then
     var=ptr->FSM
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

  if(var_name.eq."QSNOMELT")then
     var=ptr->QSNOMELT
     return(var)
  end if

  if(var_name.eq."SNOW")then
     var=ptr->SNOW
     return(var)
  end if

  if(var_name.eq."REFREEZE")then
     var=ptr->QSNOFRZ
     return(var)
  end if

  if(var_name.eq."QSNWCPICE")then
     var=ptr->QSNWCPICE
     return(var)
  end if

  if(var_name.eq."RUNOFF")then
     var=ptr->QRUNOFF
     return(var)
  end if

  if(var_name.eq."QSOIL")then
     var=ptr->QSOIL
     return(var)
  end if

  if(var_name.eq."RAIN")then
     rain=ptr->RAIN
     return(rain)
  end if

  if(var_name.eq."RAIN_REPAR")then
     rain=ptr->RAIN_REPARTITIONED
     return(rain)
  end if

  if(var_name.eq."SNOW_REPAR")then
     rain=ptr->SNOW_REPARTITIONED
     return(rain)
  end if

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

  if (var_name.eq."REFR_DIV_PROD") then
      ; Note: this is a problematic variable as we get many (near) division by zeroes.
      ; A solution is to compute climatology first, then do the division. 
      ; This function now returns only refreezing, the caller script should do the division
      ; by liq_tot itself. 
;     liq_tot = derive_land("LIQUID_TOT",ptr)
     refr = derive_land("REFREEZE",ptr)
;     if (any(liq_tot .eq. 0)) then  ; set zeros to _FillValue
;       liq_tot = mask(liq_tot,(liq_tot .eq. 0),False)
;     end if
     var = refr
;     var = refr/liq_tot
     return(var)
  end if

  if(var_name.eq."SNO_BW") then
     var=ptr->SNO_BW
     return(var)
  end if

  if(var_name.eq."SNO_MELT") then
     var=ptr->SNO_MELT_ICE
     return(var)
  end if

  if(var_name.eq."SNO_FRZ") then
     var=ptr->SNO_FRZ_ICE
     return(var)
  end if

; if derived variable is not found, return an array of missing values.
; this is check for in the set code. size is irrelevant as long as
; the array is greater than 1.
  var = new(20,"float")
  print("ERROR: "+routine+": variable not implemented: "+var_name)
  return(var)

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


