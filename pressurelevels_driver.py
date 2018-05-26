
#!/usr/bin/env python
"""
   Extract single variables from CESM history files.

   created LvK 27-Aug-2015
   updated LvK 19-Nov-2015
   updated LvK 07-Jun-2017 Added -shifttime,-1day, needed for CESM2 CLM output. Added ymonstd.
"""

import sys
import subprocess
import os
from glob import glob
import os.path


archive1='/glade/scratch/lvank/archive/'
archive2='/glade/p/cesm0005/archive/'

if (0):
   case = 'b.e20.BHIST.f09_g17.20thC.190_ramp204_reset.002' 
   datadir = os.path.join(archive1,case,'atm','hist')
   ys = '1980'
   ye = '2005'

if (1):
   case = 'b.e20.B1850.f09_g17.pi_control.all.260'
   datadir = os.path.join(archive2,case,'atm','hist')
   ys = '127'
   ye = '156'


if (0):
   varname='Z500'
if (1):
   varname='T700'
if (0):
   varname='T850'
if (0):
   varname='T500'


midfix='.cam.h0.'
if (not 'ys' in locals()):
   # glob all files
   infiles = glob(datadir+'/*cam.h0*.nc')
else:
   # glob specific range
   infiles = []
   for year in range(int(ys), int(ye)+1): # ye+1 is not included in range
      print('year = '+format(year,'04d'))
      search_str = datadir + '/'+case+midfix+format(year,'04d')+'*.nc'
      infiles_year = glob(search_str)
      infiles.extend(infiles_year)

infiles = sorted(infiles) # sort by month
print(len(infiles))

outbase = os.path.join(archive1,case,'atm','hist')
print(outbase)
outdir = os.path.join(outbase,varname) 

subprocess.check_call(['mkdir','-p', outdir])

if (True): # interpolate to specific pressure level 
   for infile in infiles:
      no_base = infile.split('/')[-1]
      print(no_base)
      outfile = outdir+'/'+no_base

      if (varname == 'Z500'):
         arg=['ncl','Z3_file=\"'+infile+'\"','PS_file=\"'+infile+'\"','outfile=\"'+outfile+'\"','calc_Z500.ncl' ]
      elif (varname == 'T500'):
         arg=['ncl','T_file=\"'+infile+'\"','PS_file=\"'+infile+'\"','outfile=\"'+outfile+'\"','calc_T500.ncl' ]
      elif (varname == 'T700'):
         arg=['ncl','T_file=\"'+infile+'\"','PS_file=\"'+infile+'\"','outfile=\"'+outfile+'\"','calc_T700.ncl' ]
      elif (varname == 'T850'):
         arg=['ncl','T_file=\"'+infile+'\"','PS_file=\"'+infile+'\"','outfile=\"'+outfile+'\"','calc_T850.ncl' ]
      else:
         print("not implemented: "+varname)
         sys.exit(0)

      if (not os.path.exists(outfile)):
         print(arg)
         subprocess.check_call(arg)


if (True): #make means
   outfiles = glob(outdir+'/*cam.h0*.nc')
   outfiles = sorted(outfiles)
   monfile=outdir+"/all_catted.nc"

   if not os.path.isfile(monfile):
      arg = ['ncrcat']
      arg.extend(outfiles)
      arg.append(monfile)
      print(arg)
      subprocess.check_call(arg) 

   mean1=outdir+"/"+varname+"_"+case+'_ymonmean.nc'
   mean2=outdir+"/"+varname+"_"+case+'_timmean.nc'
   mean3=outdir+"/"+varname+"_"+case+'_yearmonmean.nc'
   mean4=outdir+"/"+varname+"_"+case+'_ymonstd.nc'

   for (mean,oper) in zip((mean1,mean2,mean3,mean4),('-ymonmean','-timmean -yearmonmean','-yearmonmean','-ymonstd')):
      arg = ['cdo']
      arg += oper.split()
      arg += ['-shifttime,-1day']
      #arg += ['-seldate,1980-01-02,2006-01-01']
      arg += [monfile,mean]
      subprocess.check_call(arg,stderr=subprocess.STDOUT)
      print("INFO: created "+mean)

