Metrolina Trip Generation Program -- 2000 Run
Version date Aug. 25, 2005
 
tgv2.ctl
 
&files
  sefile      = 'C:\Metrolina\2000\landuse\SE2000_TAZ2934.DBF'
  distcorfile = 'C:\Metrolina\2000\ext\dist_to_closest_extsta.asc'
  xvolfile    = 'C:\Metrolina\2000\ext\extstavol.asc'
  atfile      = 'C:\Metrolina\2000\landuse\TAZ_AREATYPE.asc'
 
  prodfile    = 'C:\Metrolina\2000\tg\productions.asc'
  attrfile    = 'C:\Metrolina\2000\tg\attractions.asc'
  xxfile      = 'C:\Metrolina\2000\tg\xxfactor.asc'
  list        = 'C:\Metrolina\2000\report\tg2000.prn'
/
 
&parameters
  begtr       = 0
  endtr       = 0
  savescr     = .false.
/
 
Calibration adjustments
- EXTADJ adjusts the I/E share (a,1) and E/I share (a,2) models by area type
- ARATE adjusts the attraction equations to increase CBD, reduce Rural trips
- ATFACTA adjusts the COM, MTK, and HTK trip totals
 
&coeffs
  extadj(1,1)  = 0.9673, extadj(1,2) = 0.5215
  extadj(2,1)  = 0.5842, extadj(2,2) = 0.4295
  extadj(3,1)  = 0.5104, extadj(3,2) = 0.5104
  extadj(4,1)  = 0.6709, extadj(4,2) = 0.6709
  extadj(5,1)  = 1.7440, extadj(5,2) = 1.7440
 
  arate(5,1) = 1.25
  arate(5,4) = 2.4
  arate(5,5) = 2.4
  arate(5,7) = 3.0
  arate(4,2) = 0.05
  arate(4,3) =-0.3
  arate(4,4) = 2.05
  arate(4,5) = 3.3
  arate(4,7) = 0.9
  arate(4,8) =-0.6
 
  atfacta(9,1) = 0.40
  atfacta(9,2) = 0.43
  atfacta(9,3) = 0.53
  atfacta(9,4) = 0.62
  atfacta(9,5) = 0.57
 
  atfacta(10,1) = 0.45
  atfacta(10,2) = 0.40
  atfacta(10,3) = 0.40
  atfacta(10,4) = 0.50
  atfacta(10,5) = 0.60
 
  atfacta(11,1) = 0.40
  atfacta(11,2) = 0.40
  atfacta(11,3) = 0.40
  atfacta(11,4) = 0.50
  atfacta(11,5) = 0.60

  pfact(4,1) = 1.10
  pfact(4,2) = 1.10
  pfact(4,3) = 1.10
  pfact(4,4) = 1.10
  pfact(5,1) = 0.97
  pfact(5,2) = 1.10
  pfact(5,3) = 1.10
  pfact(5,4) = 1.12
  pfact(6,1) = 1.10
  pfact(6,2) = 1.10
  pfact(6,3) = 1.10
  pfact(6,4) = 1.10
  pfact(7,1) = 1.10
  pfact(7,2) = 1.10
  pfact(7,3) = 1.10
  pfact(7,4) = 1.10
  pfact(8,1) = 1.15
  pfact(8,2) = 1.15
  pfact(8,3) = 1.15
  pfact(8,4) = 1.15 
/
 
&equiv
  cbd         = 10001,-10003,10005,-10025,10039,10059,10103,10104,10106,
                10112,10115,10117,-10120,10139,-10144,10152,10174,10177,
                11025
/
 
&special
/
