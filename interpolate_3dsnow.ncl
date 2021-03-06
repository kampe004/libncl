; interpolate_3dsnow.ncl
;********************************************************
;  DESCRIPTION
; 
;     Library of functions that deal with 3d snow output 
;     fields from CESM. 
;
;********************************************************


;********************************************************
undef("__getTargetDomain")
;
; PRIVATE FUNCTION
;
function __getTargetDomain(zmin,zmax,dz)
begin
   ; Numerical quadrature domain
   nz = round((zmax-zmin)/dz,3)
   eps=1e-6
   if ( abs((zmin+nz*dz)-zmax) .gt. eps) then
     print("WARNING: "+routine+" provided averaging range not divisible by stepsize dz")
     print("INFO: nz = "+nz)
     print("INFO: zmax = "+zmax)
     print("INFO: zmin+nz*dz = "+(nz*dz+zmin))
   end if
   if (nz.eq.0) then
     print("ERROR: nz = 0")
     exit
   end if
   if (nz.eq.1) then
      zdom = (zmax+zmin)/2.
   else
      zdom = fspan(zmin+0.5*dz,zmax-0.5*dz,nz) 
   end if
   return zdom
end


;********************************************************
undef("linint_3dsnow_surface")
;
; Interpolate to target depth (depth = constant) 
;  INPUT 
;     sno_z    : snow layer thickness [time,lev,lat,lon]
;     z_surf   : target depth [scalar]
;     var      : field variable [time,lev,lat,lon]
;
; OUTPUT
;     var_o    : interpolated field variable at target depth [time,lat,lon]
;                 
function linint_3dsnow_surface(sno_z, z_surf, var)
begin
   routine="linint_3dsnow_surface()"

   dims     = dimsizes(var)
   nmonth   = dims(0)
   nlevsno  = dims(1)
   nlat     = dims(2)
   nlon     = dims(3)

   ; setup output variable
   var_o = new( (/ nmonth, nlat, nlon /), typeof(var) ) 
   var_o!0 = "time"
   var_o!1 = "lat"
   var_o!2 = "lon"
   var_o&time = var&time
   var_o&lat  = var&lat
   var_o&lon  = var&lon

   ; reorder input arrays and add entries at z=0 and z=BOT
   z_ext    = new( (/ nmonth, nlat, nlon, nlevsno+2 /), typeof(sno_z))
   var_ext  = new( (/ nmonth, nlat, nlon, nlevsno+2 /), typeof(var))

   z_ext(:,:,:,1:nlevsno)  = sno_z( time|:, lat|:, lon|:, lev|:)
   z_ext(:,:,:,0)          = 0.0
   z_ext_cs                = dim_cumsum(z_ext,0) 
   z_ext_cs                = z_ext_cs - 0.5*z_ext ; subtract half the layer thickness to arrive at layer midpoint values

   var_ext(:,:,:,1:nlevsno)   = var( time|:, lat|:, lon|:, lev|:)
   var_ext(:,:,:,0)           = var( time|:, lat|:, lon|:, lev|0)

   ; Rightmost index fastest changing (like C)
   do t=0,nmonth-1
   do i=0,nlat-1
   do j=0,nlon-1
      num_sno=max(ind(.not.ismissing(var_ext(t,i,j,:)))) ; actual number of snow layers
      if(num_sno .eq. 0) then
        print("ERROR: this should not be possible! ")
        exit
      else if (num_sno .gt. 0) then
         z_ext_cs(t,i,j,num_sno+1)     = z_ext_cs(t,i,j,num_sno) + 0.5 * z_ext(t,i,j,num_sno) ; add half the layer thickness to arrive at bottom
         var_ext(t,i,j,num_sno+1)   = var_ext(t,i,j,num_sno)

         ; Do interpolation
         var_o(t,i,j) = linint1(z_ext_cs(t,i,j,:), var_ext(t,i,j,:), False, z_surf, 0)
      end if
      end if
   end do
   end do
   end do

   return var_o
end


;********************************************************
undef("linint_3dsnow_cval")
;
; Interpolate to target field value (var = constant) 
;
; This function assumes the field is monotonically increasing with depth.
; Therefore, we look for the first layer k where var[k-1] < cval <= var[k] 
; at which point we perform a linear interpolation between depth[k-1] and depth[k]
; 
;  EXTREME CASES
;     cval < var[lev=0]    : return 0.
;     cval > var[lev=n]    : return spval
;
;  INPUT 
;     sno_z    : snow layer thickness [time,lev,lat,lon]
;     cval     : target field value [scalar]
;     var      : field variable [time,lev,lat,lon]
;
; OUTPUT
;     z_o      : interpolated depth at target field value [time,lat,lon]
;
function linint_3dsnow_cval(sno_z, cval, var)
begin
   routine="linint_3dsnow_cval()"

   dims     = dimsizes(var)
   nmonth   = dims(0)
   nlevsno  = dims(1)
   nlat     = dims(2)
   nlon     = dims(3)

   ; setup output variable
   z_o = new( (/ nmonth, nlat, nlon /), typeof(var) ) 
   z_o!0 = "time"
   z_o!1 = "lat"
   z_o!2 = "lon"
   z_o&time = var&time
   z_o&lat  = var&lat
   z_o&lon  = var&lon

   ; reorder input arrays and add entries at z=0 and z=BOT
   z_ext    = new( (/ nmonth, nlat, nlon, nlevsno+2 /), typeof(sno_z))
   var_ext  = new( (/ nmonth, nlat, nlon, nlevsno+2 /), typeof(var))

   z_ext(:,:,:,1:nlevsno)  = sno_z( time|:, lat|:, lon|:, lev|:)
   z_ext(:,:,:,0)          = where(ismissing(sno_z(time|:,lat|:,lon|:,lev|0)),z_ext@_FillValue,0.0)
   z_ext(:,:,:,0)          = 0.0
   z_ext_cs                = dim_cumsum(z_ext,0) 
   z_ext_cs                = z_ext_cs - 0.5*z_ext ; subtract half the layer thickness to arrive at layer midpoint values

   var_ext(:,:,:,1:nlevsno)   = var( time|:, lat|:, lon|:, lev|:)
   var_ext(:,:,:,0)           = var( time|:, lat|:, lon|:, lev|0)

   ; Rightmost index fastest changing (like C)
   snow_present=.not.ismissing(var_ext(:,:,:,0))
   do t=0,nmonth-1
   print("t="+t)
   do i=0,nlat-1
   do j=0,nlon-1
      if(snow_present(t,i,j)) then
         ;num_sno=max(ind(.not.ismissing(var_ext(t,i,j,:)))) ; actual number of snow layers
         ;num_sno2=max(ind(.not.ismissing(z_ext_cs(t,i,j,:)))) ; actual number of snow layers
         ;num_sno=min((/num_sno,num_sno2/))

         num_sno=num(.not.ismissing(var_ext(t,i,j,:))) ; actual number of snow layers

         ; extend at bottom
         z_ext_cs(t,i,j,num_sno)   = z_ext_cs(t,i,j,num_sno-1) + 0.5 * z_ext(t,i,j,num_sno-1) ; add half the layer thickness to arrive at bottom
         var_ext(t,i,j,num_sno)   = var_ext(t,i,j,num_sno-1)

         ; Do interpolation
;         print("cval="+cval)
;         print("comparing to="+var_ext(t,i,j,:))
         if (cval .le. var_ext(t,i,j,0)) then
            z_o(t,i,j) = (/ z_ext_cs(t,i,j,0) /)
         else
            do k=1,num_sno
               if (cval .le. var_ext(t,i,j,k)) then
                  z_o(t,i,j) = linint1(var_ext(t,i,j,(k-1):k),z_ext_cs(t,i,j,(k-1):k),False,cval,0)
                  break
               end if
            end do
         end if
      end if
   end do
   end do
   end do

   return z_o
end


;********************************************************
undef("linint_3dsnow_layer")
;
; Average value over a layer (with thickness) 
; Integration within the layer is performed with a user-specified sampling interval dz. 
; This function uses linear interpolation in the quadrature
;
;  INPUT 
;     sno_z    : snow layer thickness [time,lev,lat,lon]
;     zmin     : minimum depth [m]
;     zmax     : maximum depth [m]
;     dz       : sampling interval [m]
;     var      : field variable [time,lev,lat,lon]
;
; OUTPUT
;     var_o    : output field variable [time,lat,lon]
;
function linint_3dsnow_layer(sno_z, zmin, zmax, dz, var)
begin
   routine="linint_3dsnow_layer"

   dims     = dimsizes(var)
   nmonth   = dims(0)
   nlevsno  = dims(1)
   nlat     = dims(2)
   nlon     = dims(3)

   ; setup output variable
   var_o = new( (/ nmonth, nlat, nlon /), typeof(var) ) 
   var_o!0 = "time"
   var_o!1 = "lat"
   var_o!2 = "lon"
   var_o&time = var&time
   var_o&lat  = var&lat
   var_o&lon  = var&lon

   missmask1   = ismissing(sno_z)
   missmask2   = ismissing(var)
   x=where(missmask1.eq.missmask2,0,1)
   print("disagreement in missing mask : "+num(x)+ " / "+dim_product(dims))

   ; reorder input arrays and add entries at z=0 and z=BOT
   print("reordering")
   z_ext    = new( (/ nmonth, nlat, nlon, nlevsno+2 /), typeof(sno_z))
   var_ext  = new( (/ nmonth, nlat, nlon, nlevsno+2 /), typeof(var))

   z_ext(:,:,:,1:nlevsno)  = sno_z( time|:, lat|:, lon|:, lev|:)
   z_ext(:,:,:,0)          = where(ismissing(sno_z(time|:,lat|:,lon|:,lev|0)),z_ext@_FillValue,0.0)
   z_ext_cs                = dim_cumsum(z_ext,0) 
   z_ext_cs                = z_ext_cs - 0.5*z_ext ; subtract half the layer thickness to arrive at layer midpoint values

   var_ext(:,:,:,1:nlevsno)   = var( time|:, lat|:, lon|:, lev|:)
   var_ext(:,:,:,0)           = var( time|:, lat|:, lon|:, lev|0)

   ; Rightmost index fastest changing (like C)
   snow_present=.not.ismissing(z_ext(:,:,:,0))
   print("adding bottom element")
   do t=0,nmonth-1
   print("t="+t)
   do i=0,nlat-1
   do j=0,nlon-1
      if(snow_present(t,i,j)) then
         ;num_sno=max(ind(.not.ismissing(var_ext(t,i,j,:)))) ; actual number of snow layers
         num_sno=num(.not.ismissing(var_ext(t,i,j,:))) ; actual number of snow layers
         num_sno2=num(.not.ismissing(z_ext_cs(t,i,j,:))) ; actual number of snow layers
         num_sno=min((/num_sno,num_sno2/))
         if (num_sno.gt.0) then
            z_ext_cs(t,i,j,num_sno)     = z_ext_cs(t,i,j,num_sno-1) + 0.5 * z_ext(t,i,j,num_sno-1) ; add half the layer thickness to arrive at bottom
            var_ext(t,i,j,num_sno)   = var_ext(t,i,j,num_sno-1)
            ;z_ext_cs(t,i,j,num_sno+1)     = z_ext_cs(t,i,j,num_sno) + 0.5 * z_ext(t,i,j,num_sno) ; add half the layer thickness to arrive at bottom
            ;var_ext(t,i,j,num_sno+1)   = var_ext(t,i,j,num_sno)
         end if
      end if
   end do
   end do
   end do

   ; Numerical quadrature domain
   zdom = __getTargetDomain(zmin,zmax,dz)
   print("INFO: zdom = "+zdom)

   ; Do interpolation
   print("interpolating")
   do t=0,nmonth-1
   print("t="+t)
   do i=0,nlat-1
   do j=0,nlon-1
      if (snow_present(t,i,j)) then
         present:=ind(.not.ismissing(z_ext_cs(t,i,j,:)))
         var_tmp := linint1(z_ext_cs(t,i,j,present), var_ext(t,i,j,present), False, zdom, 0)
         var_o(t,i,j) = avg(var_tmp)
      end if
   end do
   end do
   end do

   return var_o
end


;********************************************************
undef("sample_3dsnow_layer")
;
; Average value over a layer (with thickness) 
; Integration within the layer is performed with a user-specified sampling interval dz. 
; This function samples directly from input array in the quadrature
;
;  INPUT 
;     sno_z    : snow layer thickness [time,lev,lat,lon]
;     zmin     : minimum depth [m]
;     zmax     : maximum depth [m]
;     dz       : sampling interval [m]
;     var      : field variable [time,lev,lat,lon]
;
; OUTPUT
;     var_o    : output field variable [time,lat,lon]
;
; This function samples from the snow layer array directly
function sample_3dsnow_layer(sno_z, zmin, zmax, dz, var)
begin
   routine="sample_3dsnow_layer"

   dims     = dimsizes(var)
   nmonth   = dims(0)
   nlevsno  = dims(1)
   nlat     = dims(2)
   nlon     = dims(3)

   ; setup output variable
   var_o = new( (/ nmonth, nlat, nlon /), typeof(var) ) 
   var_o!0 = "time"
   var_o!1 = "lat"
   var_o!2 = "lon"
   var_o&time = var&time
   var_o&lat  = var&lat
   var_o&lon  = var&lon

   z_ext  = sno_z( time|:, lat|:, lon|:, lev|:)
   z_ext  = dim_cumsum(z_ext,0) 
   var_ext           = var( time|:, lat|:, lon|:, lev|:)

   ; Numerical quadrature domain
   zdom = __getTargetDomain(zmin,zmax,dz)
   print("INFO: zdom = "+zdom)
   nz = dimsizes(zdom)

   do t=0,nmonth-1
   print("t="+t)
   do i=0,nlat-1
   do j=0,nlon-1
      ; locate for each zdom(k) value the snow layer in which it falls (if any)
      lev       = 0
      zlev      = z_ext(t,i,j,lev)
      zlev_m1   = 0.
      k         = 0 ; index in zdom

      nfound    = 0
      sum_found = 0.0
      ; WHILE LOOP INVARIANTS
      ;   (1)   zdom(k) >= z_ext(lev-1)  -- or 0.0 if lev=0
      ;   (2)   zdom(k) < z_ext(lev)   
      ;   (3)   lev < actual number of snow layers <= nlevsno
      ;   (4)   k < nz
      do while( .not.ismissing(zlev)  \ ; (3)
                .and. k .lt. nz ) ; (4)
       
         if (zdom(k) .ge. zlev_m1 .and. zdom(k) .lt. zlev  ) then
            ; zdom(k) falls within layer 'lev'
            nfound = nfound + 1
            sum_found = sum_found + var_ext(t,i,j,lev)
            ; increase k
            k = k +1
         else
            ; zdom(k) falls outside layer 'lev'
            lev = lev + 1
            if (lev .lt. nlevsno) then
               zlev_m1   = zlev
               zlev      = z_ext(t,i,j,lev)
            else 
               ; we may not index z_ext anymore, setting to missing value will break loop
               zlev = zlev@_FillValue
            end if
         end if
      end do
      if (nfound .gt.0) then
         ; return mean 
         var_o(t,i,j) = sum_found/(1.0 * nfound)
      end if
   end do
   end do
   end do

   return var_o
end


;********************************************************
undef("3dsnow_vert_int_singlepoint")
;
; Do fixed point interpolation (one lat/lon) to a set of target depths
;

;function vertical_interpolation(z_, depth, var)
;begin
;
;
;   interp_var1 = new((/dimsizes(depth),dimsizes(time),dimsizes(lons)/),"double")
;   interp_var2 = new((/dimsizes(depth),dimsizes(time),dimsizes(lons)/),"double")
;   interp_var3 = new((/dimsizes(depth),dimsizes(time),dimsizes(lons)/),"double")
;   
;   
;   do i = 0, dimsizes(lons)-1,1 ; loop around locations
;   do t = 0, dimsizes(time)-1,1
;   
;      ; vertical interpolation
;      if(.not.ismissing(z1(t,0,ii(i),jj(i))))
;         interp_var1(:,t,i) = vertical_interpolation(z1(t,:,ii(i),jj(i)), depth, var1(t,:,ii(i),jj(i)))
;      end if
;      if(.not.ismissing(z2(t,0,ii(i),jj(i))))
;         interp_var2(:,t,i) = vertical_interpolation(z2(t,:,ii(i),jj(i)), depth, var2(t,:,ii(i),jj(i)))
;      end if
;      if(.not.ismissing(z3(t,0,ii(i),jj(i))))
;         interp_var3(:,t,i) = vertical_interpolation(z3(t,:,ii(i),jj(i)), depth, var3(t,:,ii(i),jj(i)))
;      end if
;   
;   end do
;   end do
;
;
;   ; count number of existing values
;   exists   = ind(.not.ismissing(z_))
;   n        = num(.not.ismissing(z_))
;   ; extent input depth with extra entry at zero
;   z        = new(n+1, typeof(z_))
;   z(1:)    = z_(exists)
;   z(0)     = 0.0
;   var      = new(n+1, typeof(var_))
;   var(1:)  = var_(exists)
;   var(0)   = var_(exists(0))
;   ; translate thickness to absolute depths
;   z           := cumsum(z,0)
;   ; do interpolation
;   interp_var  = linint1(z, var, False, depth, 0)
;   return interp_var
;end



