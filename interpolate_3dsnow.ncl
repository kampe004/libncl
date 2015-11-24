
;********************************************************
undef("vint_3dsnow_surface")
;
; Interpolate 3D snow field to target surface (of constant depth)
;
function vint_3dsnow_surface(sno_z, z_surf, var)
begin
   routine="vint_3dsnow_surface()"
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
   var_ext(:,:,:,0)           = var(:,:,:,0)

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
undef("vint_3dsnow_layer")
;
; Average of 3D snow field over layer (with a thickness)
;
function vint_3dsnow_layer(sno_z, zmin, zmax, dz, var)
begin
   routine="vint_3dsnow_layer"

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

   missmask1 = ismissing(sno_z)
   missmask2 = ismissing(var)
   x=where(missmask1.eq.missmask2,0,1)
   print("disagreement in missing mask : "+num(x)+ " / "+dim_product(dims))
   

print("reordering")
   ; reorder input arrays and add entries at z=0 and z=BOT
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
         num_sno=num(var_ext(t,i,j,:)) ; actual number of snow layers
         z_ext_cs(t,i,j,num_sno+1)     = z_ext_cs(t,i,j,num_sno) + 0.5 * z_ext(t,i,j,num_sno) ; add half the layer thickness to arrive at bottom
         var_ext(t,i,j,num_sno+1)   = var_ext(t,i,j,num_sno)
      end if
   end do
   end do
   end do

   ; Numerical quadrature domain
   nz = round((zmax-zmin)/dz,3)
   eps=1e-6
   if ( abs((zmin+nz*dz)-zmax) .gt. eps) then
     print("WARNING: "+routine+" provided averaging range not divisible by stepsize dz")
     print("INFO: nz = "+nz)
     print("INFO: zmax = "+zmax)
     print("INFO: zmin+nz*dz = "+(nz*dz+zmin))
   end if
   zdom = fspan(zmin,zmax,nz) 
   print("zdom = "+zdom)

print("interpolating")
   ; Do interpolation
   do t=0,nmonth-1
print("t="+t)
   do i=0,nlat-1
   do j=0,nlon-1
      if (snow_present) then
         var_tmp := linint1(z_ext_cs(t,i,j,ind(present)), var_ext(t,i,j,ind(present)), False, zdom, 0)
         var_o(t,i,j) = avg(var_tmp)
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



