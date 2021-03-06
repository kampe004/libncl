
;********************************************************
;
; geopotential height at specific pressure level (e.g. 500 hPa)
;
; USAGE
;  ncl infile=\"b.e20.BHIST.f09_g17.20thC.190_ramp204_reset.002.cam.h0.1973-01.nc\" outfile=\"output.nc\"
;
; DRIVER  
;  pressurelevels_driver.py
;
;********************************************************

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

load "/glade/u/home/lvank/analysis/libncl/list_utils.ncl"
load "/glade/u/home/lvank/analysis/libncl/interpolate_3dsnow.ncl"
load "/glade/u/home/lvank/analysis/libncl/size.ncl" 

;********************************************************
begin

   required = (/ "PS_file","T_file","outfile" /)
   do ireq = 0, dimsizes(required)-1
      req = required(ireq)
      if (.not.isvar(req)) then
         print("argument >"+req+"< required")
         exit()
      end if
   end do

   fin=addfile(T_file,"r")
   fin2=addfile(PS_file,"r")

   hyam = fin->hyam
   hybm = fin->hybm
   time = fin->time
   P0mb = 1000.                        ; reference pressure [mb]


   ;print(Vnew)

   ; read dimensions
   ;dims = getfilevardims(fin,varname)
   dims = getfilevardimsizes(fin,"T")
   ;dims  = dimsizes(var)
   nt    = dims(0)
   nlev  = dims(1)
   nlat  = dims(2)
   nlon  = dims(3)

   print("nt = "+nt)
   print("nlev = "+nlev)
   print("nlat = "+nlat)
   print("nlon = "+nlon)

   print("Writing "+outfile)
   if (isfilepresent(outfile)) then
      system("rm "+outfile)
   end if
   fout:=addfile(outfile,"cw")

   dim_names = (/"time","lat","lon"/)
   dim_sizes = (/nt,nlat,nlon/) 
   dim_unlimited = (/True,False,False/)
   filedimdef(fout, dim_names, dim_sizes, dim_unlimited)
;
;   ;filevardef(fout,"time","double","time")
   filevardef(fout,"lat","double","lat")
   filevardef(fout,"lon","double","lon")
   fout->time  = fin->time
   fout->lat   = fin->lat
   fout->lon   = fin->lon

   plev = (/ 850. /)
   Vnew = vinth2p(fin->T,hyam, hybm, plev ,fin2->PS, 2,P0mb, 1, False)
   fout->T850 =  Vnew 
   atts = True
   atts@long_name = "Temperature at 850 hPa"
   atts@units = "m"
   filevarattdef(fout,"T850",atts)


end

