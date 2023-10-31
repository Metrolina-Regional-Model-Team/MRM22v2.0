! 
!                P R O G R A M   C A P S P D                        
!          LINK PREPARATION AND SPEED/CAPACITY MODULE                 
!                          VERSION 3.1                                
!                         December 9, 2011                               



!   ACKNOWLEDGEMENTS:                                                 
!        THIS VERSION COMBINES THE LNKPREP MODULE WRITTEN BY BERNARD  
!   B. KAHAN OF JOHN HAMBURG & ASSOCIATES, THE CAPSPD PROGRAM,        
!   ORIGINALLY WRITTEN BY RICHARD L. MERRICK (ALSO OF JOHN HAMBURG    
!   & ASSOCIATES), AND SASZBR, WRITTEN BY TERRY LATHROP - CDOT.       
   
!   v 1.2 - added reading area type file (McLelland, November 12, 2004)
!   v 1.3 - added reading guideway speeds (McLelland, January 11, 2005)
!   v 1.4 - changed alpha / beta to lanes and funcl (McLelland, January 12, 2005)
!   v.1.5 - changed zvd calc for signals - removed 10 sec delay added for queue clearing
!           (McLelland - March 23, 2005)
!   v.1.6 - changed hov funcl 20 to 23 :  hov is now 22: hov2+, 23: hov3+.  buses allowed on both 
!           (McLelland - Sept. 7, 2005)
!           changed hov access funcl 80 to 83 - hov access is now 82 (hov2+) and 83 (hov3+).  buses 
!           allowed on both (McLelland - Sept. 14, 2005)
!   v.2.0 - Added non-stop bus travel times
!   v.2.1 - Added ability to retain earlier loaded speeds 
!   v.2.2 - changed impedence function from TT=0.6, Dist=0.4 to TT=0.8, Dist=0.2
!           change is entirely in GISDK - new version here for bookkeepping sake
!   v.2.3 - added return code
!   v.2.4 - added adjustment to speed limit - for base year rural surface streets (funcl 4-7, major
!              to local) - if these have speed limits 50 and above - reduced to 45 for areas that 
!              are suburban or urban - warning issued (capspd, line no. 120), runyear > baseyear
!           warnings about intersection controls for centroid connectors removed.  Connector is still
!              given intersection control, but warnings are not issued because it tends to bulk up
!              the report and centroid connectors do not have capacity restraint applied anyway.
!              McLelland - November 1, 2006
!   v.2.5  - freeway speed adjustments - cap at spdcap (default 60) for atype 1-4 or Meck Co (county=119)
!              runyear > capyear.  McLelland,  Jan. 29, 2007
!   v.2.6  - added functional classes 24,25 for arterial HOV lanes
!              24 - HOV 2+ arterial 
!              25 - HOV 3+ arterial
!   v.2.7  - repair return code, McLelland, Jan. 24, 2008
!   v.2.8  - max capacity of 2200 for freeway / expressway and 2000 for surface,
!              McLelland, April 24, 2008
!   v.2.9  - added funcl 85 for walk from station PnR or station bus to station
!   v.3.0  - ZBR switched from warning to fatal error
!		   - added check for relevant TAZ (bad TAZ is fatal)
!		   - repaired area type =1 for funcl = 85
!			   McLelland, March 17, 2009  
!	v.3.1  - repaired funcl 24 and 25 funcl names to HOT2+ and HOT3+ McLelland, Dec 09, 2011  
!		   - repaired factype lookup for signalized intersections from "S" to "L"  McLelland, Dec 09, 2011  

!   compile from \metrolina\pgm
!   command > df source\capspd /list /fpscomp:filesfromcmd
!
!  Joseph McLelland
!  Charlotte DOT

!  Trace  1:  subroutine entry   
!         2:  netpass1             NOT DONE
!         3:  checkN               
!         4:  ZBR                  NOT DONE 
!         5:  lookupin              
!         6:  capspd
!         7:  areatype
!         8   guideway
!  List   1:  lookup tables 


      IMPLICIT INTEGER (A-Z)                                            
                                                                       

! files
                                                                     
      integer*4    fcntrlin /5/, fnetin /10/, flookup /11/, fnetout /14/,      &
	               ferrmsg /8/, fwarnmsg /7/, fmsgout /6/, fnerr /12/,         &
				   fcntlout /16/, fdctout /15/, frtncd /18/,                    &
				   fatypein /9/, fguidewayin /13/
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout,        &  
				   fatypein, fguidewayin, frtncd

      LOGICAL*1 TRACE(10) /10*.false./, LIST(3) /3*.false./                                      
      COMMON /OPT/ TRACE,LIST                                          
         
	  INTEGER*4    RUNYEAR /2000/, SPDCAP /80/, CAPYEAR /2050/, BASEYEAR /2005/    
	  LOGICAL*1    RTNSPD 
	  COMMON /PARAM/ RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR, RTNSPD             

      logical*1	   fatal /.false./, severe /.false./                                                    
      integer      rtn /0/


	                 
! node arrays

	  integer*4       zbrin(30000) /30000*0/, zbrout(30000) /30000*0/
	  logical*1       nfun(30000,21) /630000*.false./, ncntl(30000,6) /180000*.false./

      COMMON /narray/ zbrin, zbrout, nfun, ncntl

! lookup arrays


      real*4     LnCap1hr(21,5) /105*1000./,     & ! Link Cap - Lane capacity funcl x areatp    
                 Speederfac(21,5) /105*1./,      & ! Link Spd - factor for spds > spd limit 
	             CycLen(21,5) /105*60./,         & ! IntX Del - cycle length
				 PkSpFac(21,5) /105*1./,         & ! Link Spd - factor estimated loaded spd
				 LocTrnSpFr(21,5) /105*0./,      & ! Link Spd - local bus free speed
				 XprTrnSpFr(21,5) /105*0./,      & ! Link Spd - express bus free speed
				 LocTrnSpPk(21,5) /105*0./,      & ! Link Spd - local bus peak speed
				 XprTrnSpPk(21,5) /105*0./,      & ! Link Spd - express bus peak speed
				 GrnPctFr(21,21) /441*0./,       & ! IntX Del - green percentage
				 Cap_Park(5) /5*1./,             & ! Link Cap - on-street parking factor
				 Cap_Ped(4) /4*1./,              & ! Link Cap - pedestrian activity factor
				 SpFr_Ped(4) /4*1./,             & ! Link spd - pedestrian activity factor
				 Cap_DevDn(4) /4*1./,            & ! Link cap - development density factor
				 SpFr_DevDn(4) /4*1./,           & ! Link Spd - development density factor
				 Cap_Drvwy(4)  /4*1./,           & ! Link Cap - driveway density factor
				 SpFr_Drvwy(4) /4*1./,           & ! Link Spd - driveway density factor
				 Cap_FacLn(9,3) /27*1./,         & ! Link cap - facility type x lanes
				 ZVD_cntl(6)  /6*0./,            & ! IntX Del - delay by control type
				 Delay_prhb(6) /6*1./,           & ! IntX Del - turn prohibitions
				 Delay_fac(9) /9*1./,            & ! IntX Del - facility type (signalized)
				 Delay_TLns(6) /6*1./,           & ! IntX Del - turn lanes factor
				 Delay_Prg(2) /2*1./,            & ! IntX Del - progressive signals factor
				 Cap_Cntl(6) /6*1./,             & ! Link Cap - cap fac for non-signalized int.
				 cappkfac /2.0/,                 & ! Capacity factor for peak period (currently 2 hrs)  
				 capmidfac /7.0/,                & ! Capacity factor for midday period  
				 capnitefac /9./,                & ! Capacity factor for night period
				 impwttime /0.6/,                & ! Link impedance - weight for time 
				 impwtdist /0.4/,                & ! Link impedance - weight for distance  
				 minspeed /10.0/,                & ! Minimum final speed on link
				 alpha(21,5,2) /210*0.15/,       & ! Highway delay coefficients - alpha (funcl x urban/rural * no.lanes) - default 0.15
				 beta(21,5,2)  /210*0.40/          ! Highway delay coefficients - beta  (funcl x urban/rural * no.lanes) - default 0.40


      COMMON /LOOKUP/ LnCap1hr, Speederfac, CycLen,                    &
	  			 PkSpFac, LocTrnSpFr, XprTrnSpFr,                      &
				 LocTrnSpPk, XprTrnSpPk, GrnPctFr,                     &
				 Cap_Park, Cap_Ped, SpFr_Ped,                          &
				 Cap_DevDn,SpFr_DevDn, Cap_Drvwy,                      &
				 SpFr_Drvwy, Cap_FacLn, ZVD_cntl,                      &  
				 Delay_prhb, Delay_fac, Delay_TLns,                    & 
				 Delay_Prg, Cap_Cntl,                                  &
				 cappkfac, capmidfac, capnitefac,                      &
				 impwttime, impwtdist, minspeed, alpha, beta


!  characteristics variable values


	  integer*4   maxfuncl /21/, maxat /5/, maxfac /9/,                         & 
	              legalfun(21) /1,2,3,4,5,6,7,8,9,22,23,24,25,30,40,82,83,84,85,90,92/
	  character*1 legalfac(9) /'F','E','R','D','M','B','T','C','U'/
	  character*1 legalcntl(7) /'T','L','S','F','Y','R','X'/
	  character*2 legalffn(14) /'IU','IR','FU','PU','PR','MU','MR','CU','CM','CR','LU','LR','TR','HO'/
	  character*1 legalprk(5) /'Y','N','A','P','B'/
	  character*1 legalhml(4) /'H','M','L','X'/
	  character*1 legallu(6) /'D','R','C','I','O','X'/
	  character*1 legalprhb(6) /'N','L','R','T','C','X'/
	  
	  character*10 funname(21) /'Freeway',                  & 
								'Expressway',               &
								'Class II',                 & 
								'Major',                    & 
								'Minor',                    & 
								'Collector',                &
								'Local',                    & 
								'Ramp',                     &
								'Frwy Ramp',                &
								'HOV2+',               & 
								'HOV3+',               &
								'HOT2+',                & 
								'HOT3+',                &
								'Rail',		                &  
								'Busway',                   &
								'HOV2acc',                  & 
								'HOV3acc',                  &  
								'HwyTrnConn',               & 
								'StationWlk',               & 
								'CenCon',                   & 
								'CenConTr'/,                &

                    atname(5)  /'       CBD',               &
					            '       OBD',               &
								'     Urban',               &
								'  Suburban',               &
								'     Rural'/,              &

                   parkname(5) /'Y:Park OK',                &
					            'N:No Park',                &
								'A:NoAMpark',               &
								'P:NoPMpark',               &
								'B:NoPeakPk'/,              &
 
                    facname(9) /'F:Freeway',                &
								'E:Xprssway',               &  
								'R:Ramp',                   & 
								'D:Div-NoBk',               & 
								'M:Div-Mbrk',               & 
								'B:Div-Lbay',               &
								'T:Und-Lbay',               & 
								'C:Und-cntL',               &
								'U:Und-no L' /,             &
 
                   prhbname(4) /'L:No left',                &
								'R:No right',               &  
								'T:No thru',                & 
								'C:No turns' /,             &
 
                   cntlname(6) /'T:Through',                &
								'L:Signal',                 &  
								'S:Stop',                   & 
								'F:4w stop',                & 
								'Y:Yield' ,                 & 
								'R:RoundAbt' /,             &
				
                    hmlname(4) /'H:High',                   &
								'M:Medium',                 &  
								'L:Low',                    & 
								'X:Prohibit' /              
											 
	  COMMON /legalval/ maxfuncl, maxat, maxfac,                                &
	                    legalfun, legalfac, legalcntl,                          & 
	                    legalffn,  legalprk, legalhml,                          &
						legallu, legalprhb,                                     &
						funname, atname, parkname,                              &
						facname, prhbname,cntlname,hmlname                               

                         
! TAZ areatype array

	  integer*4       tazat(30000) /30000*0/ 
      COMMON /at/     tazat


! Guideway speeds 

	  real*4       gdwytt(300,4) /1200 * 0./
	  integer*4    gdwyid(300) /300*0/, gwcnt /0/ 
      COMMON /gw/  gdwyid, gdwytt, gwcnt




!      PROGRAM ENTRY                                 
       


      call CntrlIn(fatal)
	  if (fatal) go to 900

!  Get lookup tables

      call lookupin(fatal, severe)
	  if (fatal) go to 900


! Get area type by TAZ

     call AreaType(severe)

!  Guideway speeds

     call Guideway


!  First pass through network - range checks, builds N arrays

	  call NetPass1(fatal, severe)
	  if (fatal) go to 900

!  All links in, go through node array, make logic checks

      call checkN(fatal)
	  if (fatal) go to 900

!  Call zbr for incoming / outgoing check 

      call zbr(fatal, severe)
	  if (fatal) go to 900


!  Call capspd - capacity speed 
!  second pass through network (needed to get node data for opposing funcl) 


      rewind fnetin
      call CAPSPD(fatal, severe)
	  if (fatal) go to 900
	  if (severe) go to 920 
      go to 980

!  Fatal error kill job

  900 continue
      write(msgout,9900)
      write(fmsgout,9900)
 9900 format('FATAL ERRORS, job terminated')
      rtn = 24
	  write(frtncd, 910) rtn
  910 format(i8)
      close	(5, disp='keep') 
      close	(6, disp='keep') 
      close	(7, disp='keep') 
      close	(8, disp='keep')
      close	(9, disp='keep') 
      close	(10, disp='keep') 
      close	(11, disp='keep') 
      close	(12, disp='keep') 
      close	(13, disp='keep') 
      close	(14, disp='keep') 
      close	(15, disp='keep') 
      close	(16, disp='keep') 
      close	(18, disp='keep') 
      STOP 

!     Severe warnings - job completed, warn user

  920 continue
      rtn = 8
	  write(frtncd, 910) rtn
      go to	990   	      
  
!     Normal end 

  980 continue
      rtn = 0
	  write(frtncd, 910) rtn
     			                                                                     
  990 continue                                                           
      write(msgout,9990)
 9990 format('All done')	   
      close	(5, disp='keep') 
      close	(6, disp='keep') 
      close	(7, disp='keep') 
      close	(8, disp='keep')
      close	(9, disp='keep') 
      close	(10, disp='keep') 
      close	(11, disp='keep') 
      close	(12, disp='keep') 
      close	(13, disp='keep') 
      close	(14, disp='keep') 
      close	(15, disp='keep') 
      close	(16, disp='keep') 
      close	(18, disp='keep') 
 	  STOP                                                               

      CONTAINS                                                                      

!********************************************************************************

      SUBROUTINE CntrlIn(fatal)               
!                                                                       
!  SUBROUTINE CntrlIn - READS PARAMETER AND OPTION CARDS - SETS UP         
!  PROGRAM STATE                                                        
!                                                                       
      IMPLICIT INTEGER(A-Z)                                             

! arguments

      logical*1     fatal

! files

      integer*4    fcntrlin,  fnetin, flookup, fnetout,                        &
	               ferrmsg, fwarnmsg, fmsgout, fnerr,                          &
				   fcntlout, fdctout, fatypein, fguidewayin, frtncd 
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout,        & 
				   fatypein, fguidewayin, frtncd 

                         
      LOGICAL*1    TRACE(10), LIST(3)                                      
      COMMON /OPT/ TRACE,LIST                                          

 
    
	  INTEGER*4    RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR    
	  LOGICAL*1    RTNSPD 
	  COMMON /PARAM/ RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR, RTNSPD             
	 
 	  character*80 IN05 /'parameter file'/,                                         &
	               IN10, IN11, IN12,  IN09, IN13,                                         &
				   OUT06, OUT07, OUT08, OUT14, OUT15, OUT16, OUT18

	  integer*4 i_var05 /0/, i_var06 /0/, i_var07 /0/, i_var08 /0/,                  & 
	            i_var10 /0/,                                                         &
				i_var11 /0/, i_var12 /0/, i_var14 /0/,                               & 
				i_var15 /0/, i_var16 /0/, i_var09 /0/, i_var13 /0/, i_var18                                               
	  
	  NAMELIST /INFILES/ IN09, IN10, IN11, IN12, IN13
	  NAMELIST /OUTFILES/ OUT06, OUT07, OUT08, OUT14, OUT15, OUT16, OUT18
	  NAMELIST /PARAM/ RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR, RTNSPD                                        
      NAMELIST /OPTION/ TRACE,LIST                                      
         

      integer*4 RC /0/, date_time(8)     
                                                                       
      character*20 VDATE/'ver 3.1, Dec-09-2011'/
	  character*12 clk1, clk2, clk3
	  character*4 yr
	  character*2 mo, day, h, m                                          

                  
!  CntrlIN ENTRY POINT                                                     

      IF (TRACE(1)) print 9001                                                      
 9001 format('Trace(1):  Subroutine CntrlIn entered')             

!                                                                       
! Open Files

      open (5, file=' ', err=805, iostat=i_var05, &
	      READONLY, status='OLD')


      read(5,NML=INFILES)
 	  read(5,NML=OUTFILES)
      read(5,NML=PARAM)	  	  
      read(5,NML=OPTION)	  	  
 
      open (6, file=OUT06, err=806, iostat=i_var06, status = 'REPLACE', recl = 254)
  	  
      open (7, file=OUT07, err=807, iostat=i_var07, status = 'REPLACE', recl = 254)

      open (8, file=OUT08, err=808, iostat=i_var08, status = 'REPLACE', recl = 254)

      open (9, file=IN09,  err=809, iostat=i_var09, READONLY, status='OLD')

      open (10, file=IN10, err=810, iostat=i_var10, READONLY, status='OLD',recl = 382)

      open (11, file=IN11, err=811, iostat=i_var11, READONLY, status='OLD')

      open (12, file=IN12, err=812, iostat=i_var12, READONLY, status='OLD')

      open (13, file=IN13, err=813, iostat=i_var13, READONLY, status='OLD')

      open (14, file=OUT14, err=814, iostat=i_var14, status = 'REPLACE', recl=530)

      open (15, file=OUT15, err=815, iostat=i_var15, status = 'REPLACE', recl=80)

      open (16, file=OUT16, err=816, iostat=i_var16, status = 'REPLACE', recl=80)

      open (18, file=OUT18, err=816, iostat=i_var18, status = 'REPLACE', recl=8)

 
   10 continue

	  call date_and_time(clk1, clk2, clk3, date_time)    
	  yr = clk1(1:4)
	  mo = clk1(5:6)
	  day = clk1(7:8)
	  h = clk2(1:2)
	  m = clk2(3:4)                                                           
      write (msgout,9009) VDATE, mo, day, yr, h, m
      write (fmsgout,9009) VDATE, mo, day, yr, h, m
	  write (ferrmsg, 9009) VDATE, mo, day, yr, h, m
	  write (fwarnmsg, 9009) VDATE, mo, day, yr, h, m
 9009 format('Metrolina Regional Model'/'CapSpd ',a20/'Run:',a2,'-',a2,'-',a4,', ',a2,':',a2)



      write(msgout, NML=INFILES)
      write(msgout, NML=OUTFILES)
	  write(msgout, NML=PARAM)
 	  write(msgout, NML=OPTION)
                                        
      write(fmsgout, NML=INFILES)
      write(fmsgout, NML=OUTFILES)
	  write(fmsgout, NML=PARAM)
 	  write(fmsgout, NML=OPTION)

      write (fmsgout,9010) BASEYEAR
 9010 format('Base year for model:', i5/)

      write (fmsgout,9012) RUNYEAR
 9012 format('CAPSPD run for year:', i5/)

      write (fmsgout,9015) SPDCAP, CAPYEAR 
 9015 format('Maximum speed limit for freeways: ', i3,' if RUNYEAR > ',i4/)


      if (RTNSPD) then 
	    write (fmsgout,9020)
	  else
	    write (fmsgout,9025)
	  end if
 9020 format('Run RETAINS PREVIOUSLY LOADED PEAK HIGHWAY AND TRANSIT TIMES')
 9025 format('All Peak Travel times are estimated')
                                                                       
  300 CONTINUE                                                          

      go to 900	 	 

! File error section

  805 fid = 5
      fatal = .true.
      print 9801,  fid, in05, i_var05
	  go to 890

  806 fid = 6
      fatal = .true.
      print 9801,  fid, OUT06, i_var06
	  go to 890

  807 fid = 7
      fatal = .true.
      print 9801,  fid, OUT07, i_var07
	  go to 890

  808 fid = 8
      fatal = .true.
      print 9801,  fid, OUT08, i_var08
	  go to 890

  809 fid = 9
      fatal = .true.
      print 9801,  fid, IN09, i_var09
	  go to 890

  810 fid = 10
      fatal = .true.
      print 9801,  fid, IN10, i_var10
	  go to 890

  811 fid = 11
      fatal = .true.
      print 9801,  fid, IN11, i_var11
	  go to 890

  812 fid = 12
      fatal = .true.
      print 9801,  fid, IN12, i_var12
	  go to 890

  813 fid = 13
      fatal = .true.
      print 9801,  fid, IN13, i_var13
	  go to 890

  814 fid = 14
      fatal = .true.
      print 9801,  fid, OUT14, i_var14
      go to 890

  815 fid = 15
      fatal = .true.
      print 9801,  fid, OUT15, i_var15
	  go to 890	

  816 fid = 16
      fatal = .true.
      print 9801,  fid, OUT16, i_var16
	  go to 890

  818 fid = 18
      fatal = .true.
      print 9801,  fid, OUT18, i_var18
	  go to 890

 9801 format('Fatal Error - cannot read file ',i3,' ', a80,/':  iostat=', i5, ' ****')
  
!  fatal close
	  
  890 continue

      close	(5, disp='keep') 
      close	(6, disp='keep') 
      close	(7, disp='keep') 
      close	(8, disp='keep') 
      close	(9, disp='keep') 
      close	(10, disp='keep') 
      close	(11, disp='keep') 
      close	(12, disp='keep') 
      close	(13, disp='keep') 
      close	(14, disp='keep') 
      close	(15, disp='keep') 
      close	(16, disp='keep') 
      close	(18, disp='keep') 
      RETURN 

!  clean return

 900 continue 
     RETURN                                                           

     END subroutine CntrlIn

!***********************************************************************************************
 
       SUBROUTINE emsg_i(eunit,enum,elev,ID,County, evar,emsg)

!  eunit is ID for calling subroutine (see Units below
!  enum is the numerical error ID generally related to line number
!  elev is error level F)atal, S)evere, W)arning
!  evar is the value of error
!  emsg is the message printed

!  arguments

       integer*4 eunit,enum, ID, County
	   integer*4 evar
       character*1 elev
	   character*40 emsg

!  local

       integer*4  fout
	   character*10 units(7) /'NetPass1', 'CheckN', 'zbr', 'lookupin', 'capspd','AreaType', 'GuideWay'/
	   character*10 lev

      integer*4    fcntrlin,  fnetin, flookup, fnetout,                        &
	               ferrmsg, fwarnmsg, fmsgout, fnerr,                          &
				   fcntlout, fdctout, fatypein, fguidewayin, frtncd
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout ,       &  
				   fatypein, fguidewayin, frtncd

       if (elev .eq. 'F') then 
	     lev = 'FATAL  '
         fout = ferrmsg
        else if (elev .eq. 'S') then
	     lev = 'Severe '
         fout = ferrmsg
       else 
	     lev = 'Warning'
         fout = fwarnmsg
	   endif

	   write(fout,100) lev, ID, County, evar, emsg, units(eunit), enum
   100 format(a7,1x,i10,i4,' var=',i8,2x,a40,1x,a10,i4)

       return
	   end subroutine emsg_i
!***********************************************************************************************

       SUBROUTINE emsg_r(eunit,enum,elev,ID,County, evar,emsg)

!  eunit is ID for calling subroutine (see Units below
!  enum is the numerical error ID generally related to line number
!  elev is error level F)atal, S)evere, W)arning
!  evar is the value of error
!  emsg is the message printed

!  arguments

       integer*4 eunit,enum, ID, County
	   real*4 evar
       character*1 elev
	   character*40 emsg

!  local

       integer*4  fout
	   character*10 units(7) /'NetPass1', 'CheckN', 'zbr', 'lookupin', 'capspd','AreaType', 'GuideWay'/
	   character*10 lev

      integer*4    fcntrlin,  fnetin, flookup, fnetout,                        &
	               ferrmsg, fwarnmsg, fmsgout, fnerr,                          &
				   fcntlout,fdctout, fatypein, fguidewayin, frtncd 
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout,        &
				   fatypein, fguidewayin, frtncd 

       if (elev .eq. 'F') then 
	     lev = 'FATAL  '
         fout = ferrmsg
        else if (elev .eq. 'S') then
	     lev = 'Severe '
         fout = ferrmsg
       else 
	     lev = 'Warning'
         fout = fwarnmsg
	   endif

	   write(fout,100) lev, ID, County, evar, emsg, units(eunit), enum
   100 format(a7,1x,i10,i4,' var=',f8.2,2x,a40,1x,a10,i4)

!Errlevl ID3456780 cty var=12345678  Message890123456789012345678901234567890 Unit567890 err

       return
	   end subroutine emsg_r

!***********************************************************************************************

       SUBROUTINE emsg_c(eunit,enum,elev,ID,County, evar,emsg)

!  eunit is ID for calling subroutine (see Units below
!  enum is the numerical error ID generally related to line number
!  elev is error level F)atal, S)evere, W)arning
!  evar is the value of error
!  emsg is the message printed

!  arguments

       integer*4 eunit,enum, ID, County
	   character*1 evar
       character*1 elev
	   character*40 emsg

!  local

       integer*4  fout
	   character*10 units(7) /'NetPass1', 'CheckN', 'zbr', 'lookupin', 'capspd','AreaType', 'GuideWay'/
	   character*10 lev

      integer*4    fcntrlin,  fnetin, flookup, fnetout,                        &
	               ferrmsg, fwarnmsg, fmsgout, fnerr,                          &
				   fcntlout, fdctout, fatypein, fguidewayin, frtncd 
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout,        &
				   fatypein, fguidewayin, frtncd 


       if (elev .eq. 'F') then 
	     lev = 'FATAL  '
         fout = ferrmsg
        else if (elev .eq. 'S') then
	     lev = 'Severe '
         fout = ferrmsg
       else 
	     lev = 'Warning'
         fout = fwarnmsg
	   endif

	   write(fout,100) lev, ID, County, evar, emsg, units(eunit), enum
   100 format(a7,1x,i10,i4,' var=',a1,9x,a40,1x,a10,i4)

       return
	   end subroutine emsg_c
!***********************************************************************************************

       SUBROUTINE emsg_c2(eunit,enum,elev,ID,County, evar,emsg)

!  eunit is ID for calling subroutine (see Units below
!  enum is the numerical error ID generally related to line number
!  elev is error level F)atal, S)evere, W)arning
!  evar is the value of error
!  emsg is the message printed

!  arguments

       integer*4 eunit,enum, ID, County
	   character*2 evar
       character*1 elev
	   character*40 emsg

!  local

       integer*4  fout
	   character*10 units(7) /'NetPass1', 'CheckN', 'zbr', 'lookupin', 'capspd','AreaType', 'GuideWay'/
	   character*10 lev

      integer*4    fcntrlin,  fnetin, flookup, fnetout,                        &
	               ferrmsg, fwarnmsg, fmsgout, fnerr,                          &
				   fcntlout, fdctout, fatypein, fguidewayin, frtncd
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout,        & 
				   fatypein, fguidewayin, frtncd

       if (elev .eq. 'F') then 
	     lev = 'FATAL  '
         fout = ferrmsg
        else if (elev .eq. 'S') then
	     lev = 'Severe '
         fout = ferrmsg
       else 
	     lev = 'Warning'
         fout = fwarnmsg
	   endif

	   write(fout,100) lev, ID, County, evar, emsg, units(eunit), enum
   100 format(a7,1x,i10,i4,' var=',a2,8x,a40,1x,a10,i4)

       return
	   end subroutine emsg_c2


!**********************************************************************************

	 SUBROUTINE AreaType(severe)                                                               

!     Read area type by TAZ file 

! arguments

      logical*1    severe

! files
      integer*4    fcntrlin,  fnetin, flookup, fnetout,                        &
	               ferrmsg, fwarnmsg, fmsgout, fnerr,                          &
				   fcntlout, fdctout, fatypein, fguidewayin, frtncd
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout,        &
				   fatypein, fguidewayin, frtncd

      LOGICAL*1    TRACE(10), LIST(3)                                      
      COMMON /OPT/ TRACE,LIST                                          

	  INTEGER*4    RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR    
	  LOGICAL*1    RTNSPD 
	  COMMON /PARAM/ RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR, RTNSPD             
	                                           

! TAZ areatype array

	  integer*4       tazat(30000) 
      COMMON /at/     tazat


! local variables 

      integer*4     atin /0/, aterr /0/, taz, atype, dummy /0/
	  character*1   W /'W'/, S /'S'/


      IF (TRACE(7)) print 9001                                                      
 9001 format('Trace(7):  Subroutine AreaType entered')             

 
  100 continue
      read(fatypein,9100,end=800) taz, atype
 9100 format(i10,i1)

     atin = atin + 1

!  check ranges 

  105 continue
      if (taz .gt. 0 .and. taz .lt. 30001) go to 110
	  aterr = aterr + 1
	  call emsg_i(6,105,S, dummy, taz, atype,'Illegal TAZ no.                         ') 
      go to 100
	  		  
  110 continue
      if (atype .gt. 0 .and. atype .lt. 6) go to 115
	  aterr = aterr + 1
	  call emsg_i(6,110,S,dummy, taz, atype,'Illegal area type                       ') 
      go to 100

  115 continue
      tazat(taz) = atype
      go to 100

!  all done, write messages and return to main 

  800 continue
      write (msgout, 9800) atin, aterr 
	  write (fmsgout, 9800) atin, aterr 
 9800 format(' Subroutine AreaType completed',/                       &
             '     TAZ records read:          ', i6,/,                & 
			 '     Severe errors              ', i6)

      if (aterr .gt.0) severe = .true. 

	  RETURN
      END subroutine AreaType


!**********************************************************************************

	 SUBROUTINE GuideWay                                                              

!     Read guideway travel times from guideway file 


! files
      integer*4    fcntrlin,  fnetin, flookup, fnetout,                        &
	               ferrmsg, fwarnmsg, fmsgout, fnerr,                          &
				   fcntlout, fdctout, fatypein, fguidewayin, frtncd
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout,        &
				   fatypein, fguidewayin, frtncd


      LOGICAL*1    TRACE(10), LIST(3)                                      
      COMMON /OPT/ TRACE,LIST                                          
         
	  INTEGER*4    RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR    
	  LOGICAL*1    RTNSPD 
	  COMMON /PARAM/ RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR, RTNSPD             

! Guideway speeds 

	  real*4       gdwytt(300,4)
	  integer*4    gdwyid(300), gwcnt 
      COMMON /gw/  gdwyid, gdwytt, gwcnt


! local variables 

      integer*4     gwin /0/, gwerr /0/, seq, id, dummy /0/
	  real*4        ab_time, ba_time, ab_nst, ba_nst 
	  character*1   W /'W'/
	  character*25  stnam, stnama, stnamb


      IF (TRACE(8)) print 9001                                                      
 9001 format('Trace(8):  Subroutine Guideway entered')             


      write(fmsgout, 9000)
 9000 format(///'Guideway speed overrides'/                                          & 
             '     ID Guideway',18x,'From',22x,'To',24x,'   Seq AB time BA time  ABnstp  BAnstp')

 
  100 continue
      read(fguidewayin,9100,end=800) id, stnam, stnama, stnamb, seq, ab_time, ba_time, ab_nst, ba_nst
 9100 format(i10,2x,3a25,i10,4f10.2)

     gwin = gwin + 1

!  check ranges 

  105 continue
      if (ab_time .gt. 0.0 .or. ab_time .lt. 60.) go to 110
	  gwerr = gwerr + 1
	  call emsg_r(7,105,W, ID, dummy, ab_time, 'Illegal guideway trav time (AB), ignored') 
      go to 100
	  		  
  110 continue
      if (ba_time .gt. 0.0 .or. ba_time .lt. 60.) go to 115
	  gwerr = gwerr + 1
	  call emsg_r(7,110,W, ID, dummy, ba_time, 'Illegal guideway trav time (BA), ignored') 
       go to 100
	  		  
  115 continue
      if (gwcnt .lt. 300) go to 120
	  gwerr = gwerr + 1
	  call emsg_i(7,115,W, ID, dummy, gwcnt, 'Max guideway links exceeded, ignored    ') 
      go to 100

  120 continue
      gwcnt = gwcnt + 1 
      gdwyid(gwcnt) = id
	  gdwytt(gwcnt,1) = ab_time
	  gdwytt(gwcnt,2) = ba_time
	  gdwytt(gwcnt,3) = ab_nst
	  gdwytt(gwcnt,4) = ba_nst

      write(fmsgout, 9120) gdwyid(gwcnt), stnam, stnama, stnamb, seq, gdwytt(gwcnt,1), gdwytt(gwcnt,2), gdwytt(gwcnt,3), gdwytt(gwcnt,4)
 9120 format(i8,3(1x,a25),i6,4f8.2)
      
	  go to 100

!  all done, write messages and return to main 

  800 continue
      write (msgout, 9800) gwin, gwerr 
      write (fmsgout, 9800) gwin, gwerr 
 9800 format(' Subroutine GuideWay completed',/                       &
             '     Guideway records read:     ', i6,/,                & 
			 '     Warnings                   ', i6)


	  RETURN
      END subroutine GuideWay


!**********************************************************************************

	 SUBROUTINE NetPass1(fatal, severe)                                                               

!     Read network first time, perform checks on valid ranges of variables


! parameters

	  logical*1      fatal, severe

! files
      integer*4    fcntrlin,  fnetin, flookup, fnetout,                        &
	               ferrmsg, fwarnmsg, fmsgout, fnerr,                          &
				   fcntlout, fdctout, fatypein, fguidewayin, frtncd
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout,        &
				   fatypein, fguidewayin, frtncd 

      LOGICAL*1    TRACE(10), LIST(3)                                      
      COMMON /OPT/ TRACE,LIST                                          
         
	  INTEGER*4    RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR   
	  LOGICAL*1    RTNSPD 
	  COMMON /PARAM/ RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR, RTNSPD             
                                                 
! node arrays

	  integer*4       zbrin(30000), zbrout(30000)
	  logical*1       nfun(30000,21), ncntl(30000,6)
      
	  COMMON /narray/ zbrin, zbrout, nfun, ncntl


!  characteristics variable values


	  integer*4    maxfuncl, maxat, maxfac, legalfun(21)
	  character*1  legalfac(9), legalcntl(7),  legalprk(5),                      &
	               legalhml(4), legallu(6), legalprhb(6)

	  character*2  legalffn(14)

	  character*10 funname(21), atname(5), parkname(5),                         & 
	               facname(9), prhbname(4), cntlname(6), hmlname(4) 
	
	  COMMON /legalval/ maxfuncl, maxat, maxfac,                                &
	                    legalfun, legalfac, legalcntl,                          & 
	                    legalffn,  legalprk, legalhml,                          &
						legallu, legalprhb,                                     &
						funname, atname, parkname,                              &
						facname, prhbname,cntlname,hmlname                               





! link record variables

!******************************************************************************

     integer*4     ID, Anode, Bnode, funcl,                               &
	                locclass1, locclass2, A_oppfuncl, B_oppfuncl,         & 
	                dir, lanesAB, lanesBA, spdlimit,                      &
	                A_LeftLns, A_ThruLns, A_RightLns,                     &  
					B_LeftLns, B_ThruLns, B_RightLns,                     &
					county, state, revln, taz                                          
	

      REAL*4	    length

	  character*1   factype, parking, pedactivty, developden,               &
	                drivewyden, landuse, A_Control, A_prohibit,             &
					B_Control, B_Prohibit,  revtime                       

	  character*2   fedfunc
      character*5   fedfunc_AQ

! added for version 2.1
      real*4      O_cap1AB, O_cap1BA, O_TTPkEstAB, O_TTPkEstBA,           &
				  O_TTPkPrevAB, O_TTPkPrevBA, O_TTPkAssnAB, O_TTPkAssnBA, &                                  
				  O_TTPkLocAB, O_TTPkLocBA, O_TTPkXprAB, O_TTPkXprBA,     &                                  
				  O_TTPkNStAB, O_TTPkNStBA, O_TTPkSkSAB, O_TTPkSkSBA,     &                                  
				  O_PkLocLUAB, O_PkLocLUBA, O_PkXprLUAB, O_PkXprLUBA
 


! counters and indexes

      integer*4     i,j, funndx, Actlndx, Bctlndx,                              &  
	                lin1 /0/, lerr /0/, lwarn /0/, nerr /0/, nwarn /0/, ferr /0/

! local variables
     
	  integer*4   Aintlns, Bintlns
	  logical*1   warn /.false./
	  character*1 F /'F'/, S /'S'/, W /'W'/


! NetPass1 entry


      IF (TRACE(1)) print 9001                                                      
 9001 format('Trace(1):  Subroutine NetPass1 entered')             

 
  100 continue
      read(fnetin,9100,end=800) ID, length, dir, Anode, Bnode,              &
 	                        funcl, fedfunc, fedfunc_AQ,                             &
							lanesAB, lanesBA,                                       &
							factype, spdlimit, parking, pedactivty,                 &
							developden, drivewyden, landuse,                        &
							A_LeftLns,A_ThruLns, A_RightLns,                        &		
							A_Control, A_Prohibit,                                  &
							B_LeftLns, B_ThruLns, B_RightLns,                       &
							B_Control, B_prohibit,                                  & 
							State, County, locclass1, locclass2,                    &
							revln, revtime, taz,                                    &
							O_cap1AB, O_cap1BA, O_TTPkEstAB, O_TTPkEstBA,           &
							O_TTPkPrevAB, O_TTPkPrevBA, O_TTPkAssnAB, O_TTPkAssnBA, &                                  
							O_TTPkLocAB, O_TTPkLocBA, O_TTPkXprAB, O_TTPkXprBA,     &                                  
							O_TTPkNStAB, O_TTPkNStBA, O_TTPkSkSAB, O_TTPkSkSBA,     &                                  
							O_PkLocLUAB, O_PkLocLUBA, O_PkXprLUAB, O_PkXprLUBA      
							                                 

 9100 format               (i10,   f10.0, i2,    i6,   i6,                & ! 1 ID
                            i8,    a2,    a5,                             & ! 2 funcl
							i8,    i8,                                    & ! 3 lanes
							a1,    i8,    a1,    a1,                      & ! 4 factyp
							a1,    a1,    a1,                             & ! 5 developden 
							i8,    i8,    i8,                             & ! 6 A_LeftLns
							a1,    a1,                                    & ! 7 A_Control
							i8,    i8,    i8,                             & ! 8 B_LeftLns
							a1,    a1,                                    & ! 9 B_Control
                            i8,    i8,    i8,    i8,                      & !State 
			     			i8,    a1,    i10,                            & !revln
							f10.0, f10.0, f10.0, f10.0,                   & !cap1AB (old stuff)
							f10.0, f10.0, f10.0, f10.0,                   & !TTPkPrevAB (all old)
							f10.0, f10.0, f10.0, f10.0,                   & !TTPkLocAB (all old)
							f10.0, f10.0, f10.0, f10.0,                   & !TTPkNStAB (all old)
							f10.0, f10.0, f10.0, f10.0)                     !PkLocLUAB (all old)


     lin1 = lin1 + 1


!  check ranges for input variables, some severe, some warnings

!  length - severe

  105 continue
      if (length .gt. 0.001) go to 110
	  severe = .true.
	  lerr = lerr + 1
	  call emsg_r(1,105,S,ID,County,length,'Zero length link                        ')
		  
!  dir - fatal

  110 continue
      if (dir .eq. -1 .or. dir .eq. 0 .or. dir .eq. 1) go to 115
	  fatal = .true.
	  ferr = ferr + 1
	  call emsg_i(1,110,F,ID,County,dir,'Illegal direction code                  ') 

!  anode - max (30000) is current array max - fatal 
 
  115 continue
      if (anode .gt.0 .and. anode .lt. 30001) go to 120
	  fatal = .true.
	  ferr = ferr + 1
	  call emsg_i(1,115,F,ID,County,Anode,'Anode out of range (0-30000)            ') 

!                 (efile,eunit,enum,elev,ID,County, evar,ename,emsg)

!  bnode - max (30000) is current array max - fatal

  120 continue
      if (bnode .gt.0 .and. bnode .lt. 30001) go to 125
	  fatal = .true.
	  ferr = ferr + 1
	  call emsg_i(1,120,F,ID,County,Bnode,'Bnode out of range (0-30000)            ') 


!  funcl - fatal  - uses funndx to locate funcl (count 1-21) - use default for node arrays

  125 continue
      do 127 funndx = 1, maxfuncl
	    if (funcl .eq. legalfun(funndx)) go to 130
  127 continue
      severe = .true.
	  lerr = lerr + 1
	  call emsg_i(1,125,S,ID,County,funcl,'Illegal funtional class (default = 6)   ') 
      funndx = 6

!  federal funcl - severe

  130 continue
      do 132 i = 1, 14
	    if (fedfunc .eq. legalffn(i)) go to 135
  132 continue
      severe = .true.
	  lerr = lerr + 1
	  call emsg_c2(1,130,S,ID,County,fedfunc,'Illegal federal funtional class         ') 
  
		 
!  lanes ab - severe / warning
 
  135 continue
      if (dir .eq. -1 .and. lanesAB .gt. 0) then
        severe = .true.
  	    lerr = lerr + 1
 	    call emsg_i(1,135,S,ID,County,lanesAB,'Dir = -1 (B->A) and lanesAB > 0         ') 
      endif

      if (dir .ne. -1 .and. lanesAB .gt. 6) then
        warn = .true.
  	    lwarn = lwarn + 1
 	    call emsg_i(1,136,W,ID,County,lanesAB,'LanesAB > 6                             ') 
	  endif	   	    

      if (dir .ne. -1 .and. lanesAB .le. 0) then 
	    severe = .true.
	    lerr = lerr + 1
 	    call emsg_i(1,137,S,ID,County,lanesAB,'Dir <> -1 and lanesAB = 0               ') 
      endif

!  lanes ba - severe / warning
 
  140 continue
      if (dir .eq. 1 .and. lanesBA .gt. 0) then
        severe = .true.
  	    lerr = lerr + 1
		call emsg_i(1,140,S,ID,County,lanesBA,'Dir = 1 (A->B) and lanesBA > 0          ') 
      endif

      if (dir .ne. 1 .and. lanesBA .gt. 6) then
        warn = .true.
  	    lwarn = lwarn + 1
 	    call emsg_i(1,141,W,ID,County,lanesBA,'LanesBA > 6                             ') 
	  endif	   	    

      if (dir .ne. 1 .and. lanesBA .le. 0) then 
	    severe = .true.
	    lerr = lerr + 1
 	    call emsg_i(1,142,S,ID,County,lanesAB,'Dir <> 1 and lanesBA = 0                ') 
      endif

!  facility type - severe

  145 continue
      do 147 i = 1, maxfac
	    if (factype .eq. legalfac(i)) go to 150
  147 continue
      severe = .true.
	  lerr = lerr + 1
      call emsg_c(1,145,S,ID,County,factype,'Illegal facility type                   ') 


!  speed limit - warning
!  freeway, ramps, HOV - spl between 45 and 70

  150 continue
      if ((funcl.eq.1.or.funcl.eq.2.or.funcl.eq.8.or.funcl.eq.22.or.funcl.eq.23.or.funcl.eq.82.or.funcl.eq.83) &
	       .and.(spdlimit.lt.45.or.spdlimit.gt.70)) then
        warn = .true.
  	    lwarn = lwarn + 1
 	    call emsg_i(1,150,W,ID,County,spdlimit,'High speed facility speed limit warning ') 
      endif

!  thoroughfare - spl between 20 and 55


      if ((funcl.eq.3.or.funcl.eq.4.or.funcl.eq.5.or.funcl.eq.6.or.funcl.eq.9).and.   &
	      (spdlimit.lt.20.or.spdlimit.gt.55)) then
        warn = .true.
  	    lwarn = lwarn + 1
 	    call emsg_i(1,151,W,ID,County,spdlimit,'Thoroughfare speed limit warning        ') 
      endif
 
!  local - spl between 20 and 55

      if (funcl.eq.7.and.(spdlimit.lt.20.or.spdlimit.gt.55)) then
        warn = .true.
  	    lwarn = lwarn + 1
	    call emsg_i(1,152,W,ID,County,spdlimit,'Local street speed limit warning        ') 
      endif

!  transit guideway - spl between 15 and 60

      if ((funcl.eq.30.or.funcl.eq.40).and.(spdlimit.lt.15.or.spdlimit.gt.60)) then
        warn = .true.
  	    lwarn = lwarn + 1
	    call emsg_i(1,153,W,ID,County,spdlimit,'Transit guideway speed limit warning    ') 
      endif
  
!  connector link spl between 10 and 20 

      if ((funcl.eq.90.or.funcl.eq.92).and.   &
	      (spdlimit.lt.10.or.spdlimit.gt.30)) then
        warn = .true.
  	    lwarn = lwarn + 1
	    call emsg_i(1,154,W,ID,County,spdlimit,'Connector link speed limit warning      ') 
      endif

!  parking - warning - will default to "N"

  155 continue
      do 157 i = 1, 5
	    if (parking .eq. legalprk(i)) go to 160
  157 continue
      warn = .true.
	  lwarn = lwarn + 1
      call emsg_c(1,155,W,ID,County,parking,'Bad on-street parking code              ') 


!  pedestrian activity - warning

  160 continue
      do 162 i = 1, 4
	    if (pedactivty .eq. legalhml(i)) go to 165
  162 continue
      warn = .true.
	  lwarn = lwarn + 1
      call emsg_c(1,160,W,ID,County,pedactivty,'Bad pedestrian activity code            ') 
	
!  development density - warning

  165 continue
      do 167 i = 1, 4
	    if (developden .eq. legalhml(i)) go to 170
  167 continue
      warn = .true.
	  lwarn = lwarn + 1
      call emsg_c(1,165,W,ID,County,developden,'Bad development density code            ') 

!  driveway density - warning

  170 continue
      do 172 i = 1, 4
	    if (drivewyden .eq. legalhml(i)) go to 175
  172 continue
      warn = .true.
	  lwarn = lwarn + 1
      call emsg_c(1,170,W,ID,County,drivewyden,'Bad driveway density code               ') 

!  land use code - warning

  175 continue
!      do 177 i = 1, 6
!	    if (landuse .eq. legallu(i)) go to 180
!  177 continue
!      warn = .true.
!	  lwarn = lwarn + 1
!      call emsg_c(1,175,W,ID,County,landuse,'Bad land use code                       ') 


!  lanes at A intersection - fewer than incoming or > 4 more than incoming warning  

  185 continue
      if (dir .eq. 1) go to 190
      Aintlns = A_LeftLns + A_ThruLns + A_RightLns
      if (Aintlns - lanesBA .ge. 0 .and. Aintlns - lanesBA .le. 4) go to 190
      warn = .true.
	  lwarn = lwarn + 1
	  write(fwarnmsg,9185) ID, county, lanesBA, A_LeftLns, A_ThruLns, A_RightLns
 9185 format('Warning ',i10,i4,' var=',i8,'  Anode IntX/lanesBA mismatch. L/T/R=',3i1,'   NetPass1   185')

!  Acontrol  - severe  - uses Actlndx to keep track of control, use default for n arrays


  190 continue
      if (dir .eq. 1) go to 195
      do 192 Actlndx = 1, 6
	    if (A_Control .eq. legalcntl(Actlndx)) go to 195
  192 continue
      severe = .true.
	  lerr = lerr + 1
      call emsg_c(1,190,S,ID,County,A_Control,'Bad Anode control (default=S (stop))    ') 
	  Actlndx = 3

!  A node prohibitions - warning

  195 continue
      if (dir .eq. 1) go to 200
      do 197 i = 1, 6
	    if (A_Prohibit .eq. legalprhb(i)) go to 200
  197 continue
      warn = .true.
	  lwarn = lwarn + 1
      call emsg_c(1,195,W,ID,County,A_Prohibit,'Bad Anode prohibitions                  ') 


!  lanes at B intersection - fewer than incoming or > 4 more than incoming warning  

  200 continue
      if (dir .eq. -1) go to 205
      Bintlns = B_LeftLns + B_ThruLns + B_RightLns
      if (Bintlns - lanesAB .ge. 0 .and. Bintlns - lanesAB .le. 4) go to 205
      warn = .true.
	  lwarn = lwarn + 1
	  write(fwarnmsg,9200) ID, county, lanesAB, B_LeftLns, B_ThruLns, B_RightLns
 9200 format('Warning ',i10,i4,' var=',i8,'  Bnode IntX/lanesAB mismatch. L/T/R=',3i1,'   NetPass1   200')

!  Bcontrol  - severe - uses Bctlndx to keep track of control  - use default for node arrays 

  205 continue
      if (dir .eq. -1) go to 210
      do 207 Bctlndx = 1, 6
	    if (B_Control .eq. legalcntl(Bctlndx)) go to 210
  207 continue
      severe = .true.
	  lerr = lerr + 1
      call emsg_c(1,205,S,ID,County,B_Control,'Bad Bnode control (default=S (stop))    ') 
	  Bctlndx = 3

!  B node prohibitions - warning

  210 continue
      if (dir .eq. -1) go to 215
      do 212 i = 1, 6
	    if (B_Prohibit .eq. legalprhb(i)) go to 215
  212 continue
      warn = .true.
	  lwarn = lwarn + 1
      call emsg_c(1,210,W,ID,County,B_Prohibit,'Bad Bnode prohibitions                  ') 

!  Local class 1 - nothing here yet

  215 continue

!  Local class 2 - nothing here yet 

  220 continue

!  Reversible lanes - nothing here yet

  225 continue

!  Reversible time - nothing here yet 

  230 continue

!  IF no fatal errors yet, add info to nodes arrays 
!
  300 continue
      if (fatal) go to 400

!  nfun - functional class - add regardless of link direction

      nfun(anode,funndx) = .true.
	  nfun(bnode,funndx) = .true.

!  control array - fill only if link approaches
!  v 2.4 - CENTROID CONNECTORS (funcl 90, 92 (funndx = 20,21)) NOT INCLUDED


!  zbr array - count ins and outs for zero balance test
  
      if (funndx .eq. 20 .or. funndx .eq. 21) go to 400

      if (trace(3)) write(fmsgout,9300) Anode, Bnode, Actlndx, Bctlndx, funndx
 9300 format('Trace(3) Fill node arrays: Nodes: ', 2i6, ' Controls: ',2i6,' fun:',i6)   
      if (dir .eq. 1) then
	    ncntl(Bnode,Bctlndx) = .true.
		zbrin(Bnode) = zbrin(Bnode) + 1
		zbrout(Anode) = zbrout(Anode) + 1
 
	  else if (dir .eq. -1) then
	    ncntl(Anode,Actlndx) = .true.
		zbrin(Anode) = zbrin(Anode) + 1
		zbrout(Bnode) = zbrout(Bnode) + 1
 
 	  else
	    ncntl(Bnode,Bctlndx) = .true.
		zbrin(Bnode) = zbrin(Bnode) + 1
		zbrout(Anode) = zbrout(Anode) + 1
	    ncntl(Anode,Actlndx) = .true.
		zbrin(Anode) = zbrin(Anode) + 1
		zbrout(Bnode) = zbrout(Bnode) + 1      
	  endif
          
  400 continue

!  Get next link record

      go to 100

!  all done, write messages and return to main 

  800 continue
      write (msgout, 9800) lin1, ferr, lerr, lwarn 
      write (fmsgout, 9800) lin1, ferr, lerr, lwarn 
 9800 format(' Subroutine NetPass1 completed',/                       &
             '     link records read:         ', i6,/,                & 
			 '     FATAL ERRORS on link file: ', i6,/,                &
			 '     SEVERE ERRORS on link file:', i6,/,                &
			 '     Warnings on link file      ', i6)



	  RETURN
      END subroutine NetPass1



!  ************************************************************************************

      subroutine checkN(fatal)   

!  Check for illegal combinations in node array 
!  Max can be changed by altering size of arrays                                                                     

! files
                                                                     
      integer*4    fcntrlin,  fnetin, flookup, fnetout,                        &
	               ferrmsg, fwarnmsg, fmsgout, fnerr,                          &
				   fcntlout, fdctout, fatypein, fguidewayin, frtncd
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout,        &
				   fatypein, fguidewayin, frtncd 

      LOGICAL*1    TRACE(10), LIST(3)                                      
      COMMON /OPT/ TRACE,LIST                                          
         
	  INTEGER*4    RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR   
	  LOGICAL*1    RTNSPD 
	  COMMON /PARAM/ RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR, RTNSPD             
                         
! node arrays

	  integer*4       zbrin(30000), zbrout(30000)
	  logical*1       nfun(30000,21), ncntl(30000,6)

      COMMON /narray/ zbrin, zbrout, nfun, ncntl

!  characteristics variable values


	  integer*4    maxfuncl, maxat, maxfac, legalfun(21)
	  character*1  legalfac(9), legalcntl(7),  legalprk(5),                      &
	               legalhml(4), legallu(6), legalprhb(6)

	  character*2  legalffn(14)

	  character*10 funname(21), atname(5), parkname(5),                         & 
	               facname(9), prhbname(4), cntlname(6), hmlname(4) 
	
	  COMMON /legalval/ maxfuncl, maxat, maxfac,                                &
	                    legalfun, legalfac, legalcntl,                          & 
	                    legalffn,  legalprk, legalhml,                          &
						legallu, legalprhb,                                     &
						funname, atname, parkname,                              &
						facname, prhbname,cntlname,hmlname                               




!  Arguments

	  logical*1			fatal 

!  Nodeerrors file

      integer*4			nendx1, nendx2, nefun1, nefun2
	  character*30		nedesc
 
!  Local variables

      integer*4			inerr(100,4) /400*0/, pfun(21) 
	  integer*4			maxcntl /6/
	  integer*4			ncnt1 /0/, ncnt2 /0/,  necnt /0/,                     & 
						errcnt /0/, warncnt /0/,                              &
						i,j, ei, ej, n, nc
      character*1       pcntl(6), blank /' '/
	  character*30		cnerr(100) /100*''/
	  logical*1			othcntl, totcntl
      logical*1			countit /.false./
	  logical*1         severe /.false./, warn /.false./
      

!			 Functional class
!			funndx	 funcl
!				 1	  1:	Freeway
!				 2	  2:	Expressway
!				 3	  3:	Class II major
!				 4	  4:	Major tfare
!				 5	  5:	Minor tfare
!				 6	  6:	Collector str
!				 7	  7:	Local Street
!				 8	  8:	Ramp
!				 9	  9:	Frontage Road
!				10	 22:	HOV 2+ freeway
!				11	 23:	HOV 3+ freeway
!               12   24:    HOV 2+ arterial
!               13   25:    HOV 3+ arterial
!				14	 30:	Rail (Tran Only)
!				15	 40:	Busway(TranOnly)
!				16	 82:	Hwy to HOV2+
!				17	 83:	Hwy to HOV3+
!				18	 84:	Hwy to Transit 
!               19   85:    Station walk
!				20	 90:	Centroid connect
!				21	 92:	Cenconn Transit
!                                                                       
!  CheckN Entry point                                                   

      IF (TRACE(1)) print 9001                                                      
 9001 format('Trace(1):  Subroutine CheckN entered')             


!  Read noderrors file, put into array.  Current max 100 errors

  300 continue
      read(fnerr,9300,end=400) nendx1, nendx2, nefun1, nefun2, nedesc
 9300 format(4i8,a30)
      if (necnt .gt. 100) go to 380
	  necnt = necnt + 1
	  inerr(necnt,1) = nendx1
	  inerr(necnt,2) = nendx2
	  inerr(necnt,3) = nefun1
	  inerr(necnt,4) = nefun2
	  cnerr(necnt) = nedesc
      go to 300

!  Too many error conditions - cut off at 100.  Keep reading

  380 continue
      write (fwarnmsg,9380) nefun1, nefun2, nedesc 
 9380 format(' Warning  Max error cards exceeded(100), card ignored', 2i4,1x,a30)
    go to 300


!  Nodeerrors file in, print array

  400 continue
      write(fmsgout,9400) necnt
 9400 format(' ',////,'Node Errors input file complete, records=',i4,/  &
             '    Funcl indices     Funcl nos.    Description')

      do 410 ei = 1, necnt
	    write(fmsgout,9410) ei, (inerr(ei,ej),ej=1,4), cnerr(ei)
 9410   format(i3,1x,2i6,4x,2i6,4x,a30)
  410 continue
	   
!  Big loop through node arrays. 
!  First (500s) - go through nfun array and check for illegal pairs

  500 continue
      do 690 n = 1, 30000

		frst = 1
		countit = .false.

! get first node in nfun
   
  510    continue
         if (.not.(nfun(n,frst))) go to 570
       
! found first node	

         countit = .true.
         if (frst .eq. maxfuncl) go to 580 
         scnd = frst + 1
		 
! look for second node
		 		  
  520    continue
		 if (.not.(nfun(n,scnd))) go to 560

! got two nodes - test against node error arrays.  
! pgm does not require nodeerror to be sorted, so test against both
! keep checking rest of file even if error found

    
  530   continue
        do 540 ei = 1, necnt
		  if ((frst .eq. inerr(ei,1) .and. scnd .eq. inerr(ei,2)) .or.       &
		      (scnd .eq. inerr(ei,1) .and. frst .eq. inerr(ei,2))) then
			warn = .true.
			warncnt = warncnt + 1
			write (fwarnmsg,9530) n, inerr(ei,3), inerr(ei,4), cnerr(ei)
 9530       format('Warning',i10, 2i4,1x, a30, ' Illegal funcl pair   CheckN     530')

            go to 560
          endif
  540   continue


! advance scnd counter - go back to 520

  560   continue
        scnd = scnd + 1
		if (scnd .gt. maxfuncl) go to 570
		go to 520
 
! advance frst counter - go back to top

  570   continue
        frst = frst + 1
		if (frst .gt. maxfuncl) go to 580
	    go to 510

! done, advance counter if any node found
	    
  580   continue
        if (countit) ncnt1 = ncnt1 + 1

! end of loop through nfun array
		   
  590 continue                                                                              

! check compatability of controls, issue warnings
! Controls
! 1 T  Through
! 2 L  Signal
! 3 S  Stop
! 4 F  4 way
! 5 Y  Yield
! 6 R  Round about
!
!  stop with no through

      if (ncntl(n,3) .and. .not.ncntl(n,1)) then
	    warncnt = warncnt + 1
        write (fwarnmsg, 9610) n
 9610   format('Warning Node',i10,' Stop sign and no through',24x,'CheckN     610')

      endif
	  
!  yield with no through

      if (ncntl(n,5) .and. .not.ncntl(n,1)) then
	    warncnt = warncnt + 1
        write (fwarnmsg, 9620) n
 9620   format('Warning Node',i10,' Yield and no through',28x,'CheckN     620')

      endif

! signal - all should be signal

      othcntl = ncntl(n,1) .and. ncntl(n,3) .and. ncntl(n,4) .and. ncntl(n,5) .and. ncntl(n,6)
      if (ncntl(n,2) .and. othcntl) then
	    warncnt = warncnt + 1
        write (fwarnmsg, 9630) n, (ncntl(n,i),i=1,6)
 9630   format('Warning Node',i10,' Signal AND other controls ',6(a1,1x),10x,'CheckN     630')

	  endif

! 4 way - all should be 4 way 

      othcntl = ncntl(n,1) .and. ncntl(n,2) .and. ncntl(n,3) .and. ncntl(n,5) .and. ncntl(n,6)
      if (ncntl(n,4) .and. othcntl) then
	    warncnt = warncnt + 1
        write (fwarnmsg, 9640) n, (ncntl(n,i),i=1,6)
 9640   format('Warning Node',i10,'  4way stop AND other controls ',6(a1,1x),7x,'CheckN     640')
 
	  endif

! round about - all should be round about

      othcntl = ncntl(n,1) .and. ncntl(n,2) .and. ncntl(n,3) .and. ncntl(n,4) .and. ncntl(n,5)
      if (ncntl(n,6) .and. othcntl) then
	    warncnt = warncnt + 1
        write (fwarnmsg, 9650) n, (ncntl(n,i),i=1,6)
 9650   format(' Warning Node',i10,'  Roundabout AND other controls ',6(a1,1x),6x,'CheckN     650')
	  endif

!  counter

      othcntl = ncntl(n,1) .and. ncntl(n,2) .and. ncntl(n,3) .and. ncntl(n,4) .and. &
	            ncntl(n,5) .and. ncntl(n,6)
      if (othcntl) ncnt2 = ncnt2 + 1 

!  write node control file

  660 continue	
      if (.not.countit) go to 690
      do 670 i = 1, maxcntl
	    if (ncntl(n,i)) then
		  pcntl(i) = legalcntl(i)
		else
          pcntl(i) = blank
        endif
  670 continue
      do 680 i = 1, maxfuncl
        if (nfun(n,i)) then
		  pfun(i) = legalfun(i)
        else
          pfun(i) = 0
        endif
  680 continue
      write(fcntlout,9680) n, (pcntl(i),i=1,maxcntl), (pfun(i),i=1,maxfuncl)
 9680 format(i8,6(1x,a1),20i3)

  
   	    	    
!  end of big loop

  690 continue




!  write messages and return

      write(msgout,9500) ncnt1, ncnt2, errcnt, warncnt
      write(fmsgout,9500) ncnt1, ncnt2, errcnt, warncnt
 9500 format('CheckN complete',/                                                 & 
             '  Nodes in nfun (regardeless of direction): ',i6,/                 &
			 '  Nodes in ncntl (approach required):       ',i6,/                 &
			 '  Severe errors in functional class check:  ',i6,/                 & 
			 '  Warnings in control check                 ',i6)	              
                                
!                                                                       
       
      RETURN                                                            
      END Subroutine CheckN                                                               

!***************************************************************************************                                                                       
                                                                                                             
      SUBROUTINE ZBR(fatal, severe)                                                 
!                                                                       
!     SUBROUTINE TO REPORT ZERO BALANCE ERRORS FROM N ARRAY             

! parameters

	  logical*1      fatal, severe

! files
                                                                     
      integer*4    fcntrlin,  fnetin, flookup, fnetout,                        &
	               ferrmsg, fwarnmsg, fmsgout, fnerr,                          &
				   fcntlout, fdctout, fatypein, fguidewayin, frtncd
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout,        &
				   fatypein, fguidewayin, frtncd

      LOGICAL*1    TRACE(10), LIST(3)                                      
      COMMON /OPT/ TRACE,LIST                                          
         
	  INTEGER*4    RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR    
	  LOGICAL*1    RTNSPD 
	  COMMON /PARAM/ RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR, RTNSPD             
                                                 
! node arrays

      common /narray/ zbrin, zbrout, nfun, ncntl
	  integer*4       zbrin(30000), zbrout(30000)
	  logical*1       nfun(30000,21), ncntl(30000,6)

                                                                       
!  local variables                                       
                                                                       
      INTEGER n,ncnt /0/, zbrerr /0/                                   
                                                                       
!  Entry

      IF (TRACE(1)) print 9001                                                      
 9001 format('Trace(1):  Subroutine ZBR entered')             

                                                                        
!  LOOP THROUGH ALL NODES                                               
                                                                       
      DO 790 n=1,30000                                                   
                                                                       
!   check counts of ins and outs if both zero, node is not in network                     
                                                                       
        if (zbrin(n) .eq. 0 .and. zbrout(n) .eq. 0) go to 790

!   node is in network, if both counts > 0, node is OK

        ncnt = ncnt + 1 
        if (zbrin(n) .gt. 0 .and. zbrout(n) .gt. 0) go to 790

!   ins and no outs or other way around - error

        zbrerr = zbrerr + 1
 		fatal = .true.  
        write (ferrmsg, 9700) n, zbrin(n), zbrout(n) 
 9700   format('FATAL ',i10,8x, ' Node ins-outs dont balance, ins:',i2,   &
               ' outs:',i2,10x,'ZBR        700')

  790 continue    
!  write messages and return

      write(msgout,9790) ncnt, zbrerr
      write(fmsgout,9790) ncnt, zbrerr
 9790 format('ZBR complete',/                                          & 
             '  Nodes in arrays: (directional): ',i6,/                 &
			 '  Zero balance errors:            ',i6)	              

      RETURN                                                            
      END Subroutine                                                    

!****************************************************************************************

      SUBROUTINE lookupin(fatal, severe) 

! Subroutine to read lookup tables, build arrays 

! files
                                                                     
      integer*4    fcntrlin,  fnetin, flookup, fnetout,                        &
	               ferrmsg, fwarnmsg, fmsgout, fnerr,                          &
				   fcntlout , fdctout,fatypein, fguidewayin, frtncd
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout,        &
				   fatypein, fguidewayin, frtncd

      LOGICAL*1    TRACE(10), LIST(3)                                      
      COMMON /OPT/ TRACE,LIST                                          
         
	  INTEGER*4    RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR    
	  LOGICAL*1    RTNSPD 
	  COMMON /PARAM/ RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR, RTNSPD             

! lookup arrays


      Real*4     LnCap1hr(21,5), Speederfac(21,5), CycLen(21,5),       & 
	             PkSpFac(21,5), LocTrnSpFr(21,5), XprTrnSpFr(21,5),    & 
				 LocTrnSpPk(21,5), XprTrnSpPk(21,5), GrnPctFr(21,21),  &
				 Cap_Park(5), Cap_Ped(4), SpFr_Ped(4),                 &
				 Cap_DevDn(4), SpFr_DevDn(4), Cap_Drvwy(4),            &
				 SpFr_Drvwy(4), Cap_FacLn(9,3), ZVD_cntl(6),           &
				 Delay_prhb(6), Delay_fac(9), Delay_TLns(6),           &
				 Delay_Prg(2), Cap_Cntl(6),                            &
				 cappkfac, capmidfac, capnitefac,                      &
				 impwttime, impwtdist, minspeed,                       &
				 alpha(21,5,2), beta(21,5,2)
				 
      COMMON /LOOKUP/ LnCap1hr, Speederfac, CycLen,                    &
	  			 PkSpFac, LocTrnSpFr, XprTrnSpFr,                      &
				 LocTrnSpPk, XprTrnSpPk, GrnPctFr,                     &
				 Cap_Park, Cap_Ped, SpFr_Ped,                          &
				 Cap_DevDn,SpFr_DevDn, Cap_Drvwy,                      &
				 SpFr_Drvwy, Cap_FacLn, ZVD_cntl,                      &  
				 Delay_prhb, Delay_fac, Delay_TLns,                    & 
				 Delay_Prg, Cap_Cntl,                                  &
				 cappkfac, capmidfac, capnitefac,                      &
				 impwttime, impwtdist, minspeed, alpha, beta

!  characteristics variable values


	  integer*4    maxfuncl, maxat, maxfac, legalfun(21)
	  character*1  legalfac(9), legalcntl(7),  legalprk(5),                      &
	               legalhml(4), legallu(6), legalprhb(6)

	  character*2  legalffn(14)

	  character*10 funname(21), atname(5), parkname(5),                         & 
	               facname(9), prhbname(4), cntlname(6), hmlname(4) 
	
	  COMMON /legalval/ maxfuncl, maxat, maxfac,                                &
	                    legalfun, legalfac, legalcntl,                          & 
	                    legalffn,  legalprk, legalhml,                          &
						legallu, legalprhb,                                     &
						funname, atname, parkname,                              &
						facname, prhbname,cntlname,hmlname                               



! arguments

      logical*1 fatal, severe

	   
! local variables
     
	  integer*4   i, j, fin, ain, ivar1, ivar2 
      real*4  rin(21) /21*0./, fac1, fac2
      character*10  cin, varname, eos /'      9999'/, linkid /'      link'/
	  character*1 var1, var2

	  integer*4 wcnt /0/ 

	  integer*4  funndx, atndx, facndx

	  logical*1  warn /.false./
      
      character*80 lkupdate

      IF (TRACE(1)) print 9001                                                      
 9001 format('Trace(1):  Subroutine LookupIn entered')             

 
!  Look up file contains several tables listed sequentially separated by 9999
!  Read a record - if first value looks OK, back up and read rest of record
!  Start with funcl * area type (8 variables)

	  read(flookup,9010) lkupdate
 9010 format(a80)

      write (msgout, 9020) lkupdate 
      write (fmsgout, 9020) lkupdate 
 9020 format(/'CAPSPD Look-up tables : version'/a80//)


  100 continue
      do 150 i = 1, maxfuncl * maxat

	    read(flookup,9110) fin, ain, (rin(j),j=1,8)
 9110   format(2i10,f10.0,f10.3,f10.3,5f10.3)

        if (trace(5)) write(fmsgout,9111) fin, ain, (rin(j),j=1,8)
 9111   format('Trace(5) 111: funcl x areatp: ', 2i4, f10.0, f10.3, f10.0, 5f10.3)

        do 115 funndx = 1, maxfuncl
	      if (fin .eq. legalfun(funndx)) go to 120
  115   continue
        warn = .true.
	    wcnt = wcnt + 1
	    write(fwarnmsg,9115) fin, ain, (rin(j), j= 1,8)
 9115   format('Warning Lookup 115: bad funcl lookup  ', 2f6.0, 8f8.2)
        go to 150

  120   continue
        do 125 atndx = 1, maxat
	      if (ain .eq. atndx) go to 130
  125   continue
        warn = .true.
	    wcnt = wcnt + 1
	    write(fmsgout,9125) fin, ain, (rin(j), j= 1,8)
 9125   format('Warning Lookup 125: BAD areatype lookup' ,2f6.0, 8f8.2)
        go to 150
 
  130   continue
        LnCap1hr(funndx,atndx) = rin(1)     
		Speederfac(funndx,atndx) = rin(2)
        CycLen(funndx, atndx) = rin(3)
        PkSpFac(funndx, atndx)  = rin(4)
	    LocTrnSpFr(funndx, atndx) = rin(5)
	    XprTrnSpFr(funndx, atndx) = rin(6)
	    LocTrnSpPk(funndx, atndx) = rin(7)
	    XprTrnSpPk(funndx, atndx) = rin(8)

        if (trace(5)) write(fmsgout,9131) funndx, atndx,                          &
		                    LnCap1hr(funndx,atndx), Speederfac(funndx,atndx),     &  
							CycLen(funndx, atndx),PkSpFac(funndx, atndx),         &
							LocTrnSpFr(funndx, atndx), XprTrnSpFr(funndx, atndx), &
							LocTrnSpPk(funndx, atndx),XprTrnSpPk(funndx, atndx) 
							 
 9131   format('Trace(5) 130: fun x at ndx:', 2i4, ' Cap:',f8.0,' Spdfac: ',f8.3, & 
                            ' Cyclen: 'f8.0,' PkSpfac:', f8.3,                     &  
							' Tran: LocFr/XprFr/LocPk/XprPk: ',4f8.0)           


  150 continue

      read(flookup,9150) cin
 9150 format(a10)

! opposing funcl

      do 190 i = 1, maxfuncl
	    read(flookup,9160) fin,(rin(j),j=1,21)
 9160   format(i10,21f10.2)

        if (trace(5)) write(fmsgout,9161) fin, (rin(j),j=1,21)
 9161   format('Trace(5) 161: funcl x oppfunc: ', i4, 21f5.2)

        do 165 funndx = 1, maxfuncl
	      if (fin .eq. legalfun(funndx)) go to 170
  165   continue
        warn = .true.
	    wcnt = wcnt + 1
        funndx = 5
	    write(fmsgout,9115) fin, ain, (rin(j), j= 1,7)
 9165   format('Warning Lookup 165: bad funcl in oppfuncl lookup', &
               2f6.0, 21f8.2)
  170   continue
        do 180 j = 1, maxfuncl
		  GrnPctFr(funndx,j)= rin(j)

  180   continue

          if (trace(5))                                                       &
		    write(fmsgout,9180) funndx, (GrnPctFr(funndx,j),j=1,maxfuncl)
 9180       format('Trace(5) 180: fun: ',i4,' grnpct: ',21f5.2)           


  190 continue

      read(flookup,9150) cin
 
! read the link variable factors

  200 continue
      read(flookup,9200, end=500) varname
 9200 format(a10)
	  if (varname .eq. eos) go to 500
	  backspace flookup
	  read(flookup,9210) varname, var1, var2, fac1, fac2
 9210 format(a10,t20,a1,t40,a1,2f10.3)

      if (trace(5)) write(fmsgout,9211) varname, var1, var2, fac1, fac2
 9211 format('Trace(5) 211: varname:',a10,' vars:', 2(1x,a1), ' facs:',2f8.3)
!
      if (varname .eq. 'parking') then
	    go to 220
      else if (varname .eq. 'pedactivit') then
	    go to 230
      else if (varname .eq. 'developden') then
	    go to 240
      else if (varname .eq. 'drivewyden') then
	    go to 250
      else if (varname .eq. 'control') then
	    go to 260
      else if (varname .eq. 'prohibit') then
	    go to 270
      else if (varname .eq. 'LeftLns') then
	    go to 280
      else if (varname .eq. 'RightLns') then
	    go to 290
      else if (varname .eq. 'progressiv') then
	    go to 300
      else if (varname .eq. 'factype') then
	    go to 310
      else if (varname .eq. 'cappkfac') then
	    go to 350
      else if (varname .eq. 'capmidfac') then
	    go to 355
      else if (varname .eq. 'capnitefac') then
	    go to 360
      else if (varname .eq. 'impwttime') then
	    go to 365
      else if (varname .eq. 'impwtdist') then
	    go to 370
      else if (varname .eq. 'minspeed') then
	    go to 380
       else 
	    go to 390
	  end if

! Parking

  220 continue
      do 225 i = 1, 5
	      if (var1 .eq. legalprk(i)) go to 228
  225   continue
        warn = .true.
	    wcnt = wcnt + 1
	    write(fmsgout,9225) varname, var1, fac2
 9225   format('WARNING Lookup 225: bad parking lookup', a10, 2x, a1, 2x, f10.3)
        go to 400
  
  228   continue
        Cap_Park(i)= fac2

        if (trace(5)) write(fmsgout,9228) var1, i, Cap_Park(i) 
 9228   format('Trace(5) 228: parking: var1=',a1,' index:',i4,' Cap_Park:',f8.3) 

        go to 400
		
! Pedestrian activity
  
  230 continue

       do 235 i = 1, 4
	      if (var1 .eq. legalhml(i)) go to 238
  235   continue
        warn = .true.
	    wcnt = wcnt + 1
	    write(fmsgout,9235) varname, var1, fac1, fac2
 9235   format('WARNING Lookup 235: bad ped activity lookup', a10, 2x, a1, 2x, 2f10.3)
        go to 400
  
  238   continue
        SpFr_Ped(i)= fac1
        Cap_Ped(i)= fac2

        if (trace(5)) write(fmsgout,9238) var1, i, SpFr_Ped(i), Cap_Ped(i) 
 9238   format('Trace(5) 238: ped activity: var1=',a1,' index: ',i4,    &
               ' SpFr_Ped:',f8.3,' Cap_Ped:',f8.3)           
 

        go to 400

	
! Development density
  
  240 continue
      do 245 i = 1, 4
	      if (var1 .eq. legalhml(i)) go to 248
  245   continue
        warn = .true.
	    wcnt = wcnt + 1
	    write(fmsgout,9245) varname, var1, fac1, fac2
 9245   format('WARNING Lookup 245: bad development density lookup', a10, 2x, a1, 2x, 2f10.3)
        go to 400
  
  248   continue
        SpFr_DevDn(i)= fac1
        Cap_DevDn(i)= fac2

        if (trace(5)) write(fmsgout,9248) var1, i, SpFr_DevDn(i), Cap_DevDn(i) 
 9248   format('Trace(5) 248: develop den: var1=',a1,' index: ',i4,    &
               ' SpFr_DevDn:',f8.3,' Cap_DevDn:',f8.3)           
 

        go to 400
! Driveway density
  
  250 continue
      do 255 i = 1, 4
	      if (var1 .eq. legalhml(i)) go to 258
  255   continue
        warn = .true.
	    wcnt = wcnt + 1
	    write(fmsgout,9255) varname, var1, fac1, fac2
 9255   format('WARNING Lookup 255: bad driveway density lookup', a10, 2x, a1, 2x, 2f10.3)
        go to 400
  
  258   continue
        SpFr_Drvwy(i)= fac1
        Cap_Drvwy(i)= fac2

        if (trace(5)) write(fmsgout,9258) var1, i, SpFr_Drvwy(i), Cap_Drvwy(i) 
 9258   format('Trace(5) 258: drive den: var1=',a1,' index: ',i4,    &
               ' SpFr_Drvwy:',f8.3,' Cap_Drvwy:',f8.3)           
 
        go to 400
		
! Control ZVD & control capacity factor
  
  260 continue
      if (var2 .eq. linkid) go to 265
      do 262 i = 1, 6
	      if (var1 .eq. legalcntl(i)) go to 264
  262   continue
        warn = .true.
	    wcnt = wcnt + 1
	    write(fmsgout,9260) varname, var1, fac1
 9260   format('WARNING Lookup 260: bad control lookup', a10, 2x, a1, 2x, f10.3)
        go to 400
  
  264   continue
        ZVD_cntl(i)	= fac1

        if (trace(5)) write(fmsgout,9264) var1, i, ZVD_cntl(i) 
 9264   format('Trace(5) 264: ZVD control: var1=',a1,' index: ',i4,    &
               ' ZVD_cntl:',f8.3)           

        go to 400

! Link factor for non-signalized intersections

  265 continue
      do 267 i = 1, 6
	      if (var1 .eq. legalcntl(i)) go to 269
  267   continue
        warn = .true.
	    wcnt = wcnt + 1
	    write(fmsgout,9265) varname, var1, fac2
 9265   format('WARNING Lookup 265: bad control lookup', a10, 2x, a1, 2x, f10.3)
        go to 400
  
  269   continue
        Cap_cntl(i)	= fac2

        if (trace(5)) write(fmsgout,9269) var1, i, Cap_cntl(i) 
 9269   format('Trace(5) 269: cap_control: var1=',a1,' index: ',i4,    &
               ' Cap_cntl:',f8.3)           

        go to 400
		
		
! Turn prohibitions
  
  270 continue
      do 275 i = 1, 5
	      if (var1 .eq. legalprhb(i)) go to 278
  275   continue
        warn = .true.
	    wcnt = wcnt + 1
	    write(fmsgout,9275) varname, var1, fac2
 9275   format('WARNING Lookup 275: bad turn prohibitions lookup', a10, 2x, a1, 2x, f10.3)
        go to 400
  
  278   continue
        Delay_prhb (i) = fac2

        if (trace(5)) write(fmsgout,9278) var1, i, Delay_prhb(i) 
 9278   format('Trace(5) 278: Delay for prohib: var1=',a1,' index: ',i4,    &
               ' Delay_prhb:',f8.3)           

        go to 400
		     
! Left turn lanes
! Turn lanes array  Delay_TLns(i(3),j(2)) 
!      i=1  One left turn lane signalized
!        2  One left turn lane unsignalized
!        3  2+ left turn lanes signalized
!        4  2+ left turn lanes unsignalized
!        5  1+ right turn lns signalized
!        6  1+ right turn lns unsignalized             
   
  280 continue
      if (var1 .ne. '1') go to 285
	  if (var2 .eq. 'S') then
		  Delay_TLns(1) = fac2 
	  else 
	      Delay_TLns(2) = fac2
      endif
	  go to 400
  285 if (var1 .ne. '2') go to 288
	  if (var2 .eq. 'S') then
		  Delay_TLns(3) = fac2 
	  else 
	      Delay_TLns(4) = fac2
      endif
	  go to 400

  288 continue
      warn = .true.
	  wcnt = wcnt + 1
	  write(fmsgout,9288) varname, var1, var2, fac2
 9288 format('WARNING Lookup 288: bad left turn lookup', a10, 2(2x, a1), 2x, f10.3)

      go to 400
  
! Right turn lanes - see note on left lanes above
  
  290 continue
      if (var2 .eq. 'S') then
	    Delay_TLns(5) = fac2 
	  else 
	    Delay_TLns(6) = fac2
      endif
	  go to 400

      warn = .true.
	  wcnt = wcnt + 1
	  write(fmsgout,9290) varname, var1, var2, fac2
 9290 format('WARNING Lookup 290: bad right turn lookup', a10, 2(2x, a1), 2x, f10.3)

       go to 400
  
! Progressive signals - don't have these coded yet
  
  300 continue
      if (var1 .eq. 'Y') then
	    Delay_Prg(1) = fac2 
      else if (var1 .eq. 'N') then 
	    Delay_Prg(2) = fac2
      else
        warn = .true.
 	    wcnt = wcnt + 1
	    write(fmsgout,9305) varname, var1, fac2
 9305   format('WARNING Lookup 305: bad progressive signals lookup', a10, 2x, a1, 2x,f10.3)
      endif

   	  go to 400
  
	
! Facility type - 3 capacity factors (based on lanes)  One signalized intersection delay factor
  
  310 continue
      do 315 i = 1, maxfac
	      if (var1 .eq. legalfac(i)) go to 318
  315 continue
      warn = .true.
	  wcnt = wcnt + 1
	  write(fmsgout,9315) varname, var1, var2, fac2
 9315 format('WARNING Lookup 315: bad facility type lookup', a10, 2(2x, a1), 2x,f10.3)
      go to 400

  318 continue
 

!  factype x "L" - signalized intersection delay

      if (var2 .eq. 'L') then
        Delay_fac(i) = fac2
        go to 400

!  factype x '1', '2', or '3' - lane capacity factors

	  else if (var2 .eq. '1') then
	    Cap_FacLn(i,1) = fac2
        j = 1
	  else if (var2 .eq. '2') then
	    Cap_FacLn(i,2) = fac2
        j = 2
	  else if (var2 .eq. '3') then
	    Cap_FacLn(i,3) = fac2
        j = 3
      else
        warn = .true.
  	    wcnt = wcnt + 1
	    write(fmsgout,9320) varname, var1, var2, fac2
 9320   format('WARNING Lookup 320: bad VAR2 for facility type lookup', a10, 2(2x, a1), 2x,f10.3)
      endif

      if (trace(5)) write(fmsgout,9321) var1, var2, i, Delay_fac(i), j, Cap_FacLn(i,j) 
 9321 format('Trace(5) 321: Delay funcl: var1=',a1,' var2=',a1,' index: ',i4,    &
               ' Delay_prhb:',f8.3,' By # lns: index=',i2,'  Cap_FacLn:',f8.3)           

      go to 400

!  Capacity factors - peak

  350 continue
	  if (fac2 .ge. 1. .and. fac2 .le. 5.) then
	    cappkfac = fac2
      else
        warn = .true.
  	    wcnt = wcnt + 1
	    write(fmsgout,9350) varname, fac2
 9350   format('WARNING Lookup 350: bad peak capacity', a10, f10.1,' default=2.0')
      endif
	  go to 400


!  Capacity factors - midday

  355 continue
	  if (fac2 .ge. 1. .and. fac2 .le. 10.) then
	    capmidfac = fac2
      else
        warn = .true.
  	    wcnt = wcnt + 1
	    write(fmsgout,9355) varname, fac2
 9355   format('WARNING Lookup 355: bad midday cap factor', a10, f10.1,' default=7.0')
      endif
	  go to 400

!  Capacity factors - night

  360 continue
	  if (fac2 .ge. 1. .and. fac2 .le. 15.) then
	    capnitefac = fac2
      else
        warn = .true.
  	    wcnt = wcnt + 1
	    write(fmsgout,9360) varname, fac2
 9360   format('WARNING Lookup 360: bad night capacity', a10, f10.1,' default=9.0')
      endif
	  go to 400

!  Impedance weight - time

  365 continue
	  if (fac2 .ge. 0. .and. fac2 .le. 10.) then
	    impwttime = fac2
      else
        warn = .true.
  	    wcnt = wcnt + 1
	    write(fmsgout,9365) varname, fac2
 9365   format('WARNING Lookup 365: bad time impedance weight (0-10)',           & 
              a10, f10.1,' default=0.6')
      endif
	  go to 400

!  Impedance weight - distance

  370 continue
	  if (fac2 .ge. 0. .and. fac2 .le. 10.) then
	    impwtdist = fac2
      else
        warn = .true.
  	    wcnt = wcnt + 1
	    write(fmsgout,9370) varname, fac2
 9370   format('WARNING Lookup 370: bad distance impedance weight (0-10)',       & 
             a10, f10.1,' default=0.4')
      endif
	  go to 400

!  Minimum speed 

  380 continue
	  if (fac1 .ge. 0. .and. fac1 .le. 25.) then
	    minspeed = fac1
      else
        warn = .true.
  	    wcnt = wcnt + 1
	    write(fmsgout,9380) varname, fac1
 9380   format('WARNING Lookup 380: bad minimum speed',       & 
             a10, f10.1,' default=10.0')
      endif
	  go to 400


! Missed on varname

  390 continue
      warn = .true.
	  wcnt = wcnt + 1
	  write(fmsgout,9390) varname, var1, var2, fac2
 9390 format('WARNING Lookup 390: bad varname: ', a10, 2(2x, a1), 2x, f10.3)

! End of section on link variable factors
		
  400 continue
      go to 200

! Highway delay coefficients - funcl x factype
!    - not all factype's are necessarily included - if left blank on worksheet,
!    (zero on input file), all of those funcl's are assessed same alpha / beta
 
  500 continue

      read(flookup,9500, end=700) varname  
 9500 format(a10)
	  if (varname .eq. eos) go to 700
	  backspace flookup
	  read(flookup,9510) fin, ivar1, ivar2, fac1, fac2
 9510 format(3i10,2f10.2)

      if (trace(5)) write(fmsgout,9511) fin, ivar1, ivar2, fac1, fac2
 9511 format('Trace(5) 511: highway delay coef: funcl:',i2,' atype: ', i2, ' lanes: ',i2, ' alpha / beta:',2f10.2)

! set funcl index

      do 515 funndx = 1, maxfuncl
	    if (fin .eq. legalfun(funndx)) go to 520
  515 continue
      warn = .true.
	  wcnt = wcnt + 1
	  write(fmsgout,9515) fin, ivar1, ivar2, fac1, fac2 
 9515 format('Warning Lookup 515: bad funcl in highway delay lookup  ', 3i4, 3x,  2f10.2, ' use defaults')
      go to 500

! ivar1 is area type, if 0 - fill all, 

  520 continue
      if (ivar1 .ge. 0 .and. ivar1 .le.5) go to 525
      warn = .true.
	  wcnt = wcnt + 1
	  write(fmsgout,9520) fin, ivar1, ivar2, fac1, fac2 
 9520 format('Warning Lookup 520: bad atype in highway delay lookup  ', 3i4, 3x,  2f10.2, ' use defaults')
      go to 500

! ivar2 is minimum no. of lanes (e.g. 3 is a multi-lane facility)  type, if 0 - fill all, 

  525 continue
      if (ivar2 .ge. 0 .and. ivar2 .le.10) go to 528
      warn = .true.
	  wcnt = wcnt + 1
	  write(fmsgout,9525) fin, ivar1, ivar2, fac1, fac2 
 9525 format('Warning Lookup 520: bad #lanes in highway delay lookup  ', 3i4, 3x,  2f10.2, ' use defaults')
      go to 500

! fill all area types with coefs

  528 continue
      if (ivar1 .gt. 0) go to 535
        do 530 i = 1, 5
	      if (ivar2 .lt. 3) then
		    alpha(funndx,i,1) = fac1
			beta(funndx,i,1) = fac2
			alpha(funndx,i,2) = fac1
			beta(funndx,i,2) = fac2
            j = 0       
	        if (trace(5)) write(fmsgout,9530) funndx,i, j, alpha(funndx,i,1), beta(funndx, i, 1)
            j = 3       
	        if (trace(5)) write(fmsgout,9530) funndx,i, j, alpha(funndx,i,2), beta(funndx, i, 2)
		  else
		    alpha(funndx,i,2) = fac1
			beta(funndx,i,2) = fac2
	        if (trace(5)) write(fmsgout,9530) funndx,i, ivar2, alpha(funndx,i,1), beta(funndx, i, 1)
		  endif


  530   continue 
 9530     format('Trace(5) 530: highway delay: funcl:', i3, ' atype:',i3,' lanes: ',i3, ' alpha/beta:',2(f10.2,2x))

        go to 500

! fill areatype specific  values

  535   continue
	      if (ivar2 .lt. 3) then
		    alpha(funndx,ivar1,1) = fac1
			beta(funndx,ivar1,1) = fac2
			alpha(funndx,ivar1,2) = fac1
			beta(funndx,ivar1,2) = fac2
            j = 0       
	        if (trace(5)) write(fmsgout,9530) funndx,ivar1, j, alpha(funndx,ivar1,1), beta(funndx, ivar1, 1)
            j = 3       
	        if (trace(5)) write(fmsgout,9530) funndx,ivar1, j, alpha(funndx,ivar1,2), beta(funndx, ivar1, 2)
		  else
		    alpha(funndx,ivar1,2) = fac1
			beta(funndx,ivar1,2) = fac2
	        if (trace(5)) write(fmsgout,9530) funndx,ivar1, ivar2, alpha(funndx,ivar1,2), beta(funndx, ivar1, 2)
		  endif

      go to 500

 
! Write reports

  700 continue
      if (.not.list(1)) go to 990

! Link variables first
! Lane capacity

      write(fmsgout,9700)
 9700 format(/////'Link Capacity lookup tables'//        &
             'Default Capacity per lane per hour'/)
      write(fmsgout,9702) (atname(j), j=1,maxat)
 9702 format('Funcl                          Area Type',/,16x,5a10)
      do 705 i = 1, maxfuncl
        write(fmsgout,9705), legalfun(i), funname(i), (LnCap1hr(i,j),j=1,maxat) 
  705 continue
 9705 format(i3,1x,a10,2x,5f10.0)

! Facility type x lanes capacity factor

      write(fmsgout,9710)
 9710 format(///'Facility type x no. of lanes capacity factor'/)
      write(fmsgout,9712) 
 9712 format('FacType                No. of lanes',/,                    &
             20x,'1 lane',3x,'2 lanes', 2x,'3+ lanes')
      do 715 i = 1, maxfac
        write(fmsgout,9715), facname(i), (Cap_FacLn(i,j),j=1,3) 
  715 continue
 9715 format(a10, 6x, 3f10.3)

! Parking capacity lookup factor

      write(fmsgout,9720)
 9720 format(///'On-street parking capacity factor',/,'Parking')
      write(fmsgout,9725), (parkname(i), Cap_Park(i), I=1,5) 
 9725 format(a10, 6x, f10.3)


! Pedestrian Activity lookup factor

      write(fmsgout,9730)
 9730 format(///'Pedestrian activity capacity factor',/,'Pedestrian Activity')
      write(fmsgout,9725), (hmlname(i), Cap_Ped(i), I=1,4) 

! Development density lookup factor

      write(fmsgout,9735)
 9735 format(///'Development density capacity factor',/,'Development density')
      write(fmsgout,9725), (hmlname(i), Cap_DevDn(i), I=1,4) 

! Driveway density lookup factor

      write(fmsgout,9740)
 9740 format(///'Driveway density capacity factor',/,'Driveway density')
      write(fmsgout,9725), (hmlname(i), Cap_Drvwy(i), I=1,4) 


! Link speed lookup tables
! Speeder fac

      write(fmsgout,9750)
 9750 format(/////'Link Speed lookup tables',//        &
             'Factor for average speed greater than speed limit')
      write(fmsgout,9702) (atname(j), j=1,maxat)
      do 752 i = 1, maxfuncl
        write(fmsgout,9752), legalfun(i), funname(i), (Speederfac(i,j),j=1,maxat) 
  752 continue
 9752 format(i3,1x,a10,2x,5f10.2)

! Pedestrian activity speed lookup factor

      write(fmsgout,9755)
 9755 format(///'Pedestrian Activity Speed lookup factor',/,'Pedestrian Activity')
      write(fmsgout,9725), (hmlname(i), SpFr_Ped(i), I=1,4) 
 
! Development density speed lookup factor

      write(fmsgout,9760)
 9760 format(///'Development Density Speed lookup factor',/,'Development Density')
      write(fmsgout,9725), (hmlname(i), SpFr_DevDn(i), I=1,4) 
 
! Driveway density speed lookup factor

      write(fmsgout,9765)
 9765 format(///'Driveway Density Speed lookup factor',/,'Driveway Density')
      write(fmsgout,9725), (hmlname(i), SpFr_Drvwy(i), I=1,4) 
 
  
! Peak speed factor

      write(fmsgout,9770)
 9770 format(///'Factor to estimate loaded (peak) speed ')
      write(fmsgout,9702) (atname(j), j=1,maxat)
      do 772 i = 1, maxfuncl
        write(fmsgout,9772), legalfun(i), funname(i), (PkSpFac(i,j),j=1,maxat) 
  772 continue
 9772 format(i3,1x,a10,2x,5f10.3)
  
  
! Local bus free speed

      write(fmsgout,9775)
 9775 format(///'Default local bus free speed (MPH): Speed capped at 90% mixed traffic speed')
      write(fmsgout,9702) (atname(j), j=1,maxat)
      do 777 i = 1, maxfuncl
        write(fmsgout,9752), legalfun(i), funname(i), (LocTrnSpFr(i,j),j=1,maxat) 
  777 continue
  
  
! Express bus free speed

      write(fmsgout,9780)
 9780 format(///'Default express bus free speed (MPH): Speed capped at 90% mixed traffic speed')
      write(fmsgout,9702) (atname(j), j=1,maxat)
      do 782 i = 1, maxfuncl
        write(fmsgout,9752), legalfun(i), funname(i), (XprTrnSpFr(i,j),j=1,maxat) 
  782 continue
  
  
! Local bus peak speed

      write(fmsgout,9785)
 9785 format(///'Default local bus peak speed (MPH): Speed capped at 90% mixed traffic speed')
      write(fmsgout,9702) (atname(j), j=1,maxat)
      do 787 i = 1, maxfuncl
        write(fmsgout,9752), legalfun(i), funname(i), (LocTrnSpPk(i,j),j=1,maxat) 
  787 continue
  
  
! Express bus peak speed

      write(fmsgout,9790)
 9790 format(///'Default express bus peak speed (MPH): Speed capped at 90% mixed traffic speed')
      write(fmsgout,9702) (atname(j), j=1,maxat)
      do 792 i = 1, maxfuncl
        write(fmsgout,9752), legalfun(i), funname(i), (XprTrnSpPk(i,j),j=1,maxat) 
  792 continue
  
 
! Intersection delay 
! Control ZVD 

      write(fmsgout,9800)
 9800 format(/////'Intersection Delay lookup tables',//        &
             'Default delay (seconds) by control'/)
      write(fmsgout,9805), (cntlname(i), ZVD_cntl(i), I=1,6) 
 9805 format(a10, 6x, f10.2,/)

  
! Default Cycle length

      write(fmsgout,9810)
 9810 format(///'Default cycle length (seconds)')
      write(fmsgout,9702) (atname(j), j=1,maxat)
      do 815 i = 1, maxfuncl
        write(fmsgout,9752), legalfun(i), funname(i), (CycLen(i,j),j=1,maxat) 
  815 continue
  
 
! Green percentage 

      write(fmsgout,9820)
 9820 format(///'Default green percentage of cycle - funcl x opposing funcl')
      write(fmsgout,9822) (j, j=1,maxfuncl)
 9822 format('Funcl                  Opposing functional class',/,16x,21i10)
      do 825 i = 1, maxfuncl
        write(fmsgout,9825), legalfun(i), funname(i), (GrnPctFr(i,j),j=1,maxfuncl) 
  825 continue
 9825 format(i3,1x,a10,2x,21f10.2)
  
! Intersection Delay factor - facility type for signalized intersections

      write(fmsgout,9830)
 9830 format(///'Intersection delay factor : Facility type factor @ signalized intersections',/,'FacType')
      write(fmsgout,9835), (facname(i), Delay_fac(i), I=1,9) 
 9835 format(a10, 6x, f10.2)

  
! Intersection delay factor - turn prohibitions at intersection

      write(fmsgout,9840)
 9840 format(///'Intersection delay factor: Turn prohibitions',/,'*_Prohibit')
      write(fmsgout,9835), (prhbname(i), Delay_prhb(i), I=1,4) 

  
! Intersection delay factor - turn lanes at intersections

      write(fmsgout,9850)
 9850 format(///'Intersection delay factor:  Turn lanes at intersection')    
  	  write(fmsgout,9855) (Delay_Tlns(i),i=1,6)
 9855 format('1 left turn lane,   signalized  ', f10.3,/,                      &
             '1 left turn lane,   unsignalized', f10.3,/,                      &
             '2+ left turn lanes, signalized  ', f10.3,/,                      & 
			 '2+ left turn lanes, unsignalized', f10.3,/,                      & 
			 '1+ right turn lane, signalized  ', f10.3,/,                      &
			 '1+ right turn lane, unsignalized', f10.3)


! Intersection delay factor - progressive signals

      write(fmsgout,9860)
 9860 format(///'Intersection delay factor:  progressive signals')
	  write(fmsgout,9865)  Delay_Prg(1), Delay_Prg(2)
 9865 format('On progression    ',f15.3,/,                                  &
             'Not on progression' f15.3)              
  
  
! Highway Assignment Delay Coefficients: funcl x area type * 2 / 3+ lanes 
! List everything for funcl 1-9, then only 2 and 5 for rest of funcls

      write(fmsgout,9870)
 9870 format(///'Highway Assignment Delay Coefficients : functional class * area type * 2/3+ lane facility')

      do 875 i = 1, 9
	    do 875 j = 1, maxat
          write(fmsgout,9875), legalfun(i), funname(i), j, atname(j), alpha(i,j,1), beta(i,j,1)  
          write(fmsgout,9876), legalfun(i), funname(i), j, atname(j), alpha(i,j,2), beta(i,j,2)  
  875 continue
      do 876 i = 10, maxfuncl
	    j = 2
        write(fmsgout,9875), legalfun(i), funname(i), j, atname(j), alpha(i,j,1), beta(i,j,1)  
        write(fmsgout,9876), legalfun(i), funname(i), j, atname(j), alpha(i,j,2), beta(i,j,2)  
	    j = 5
        write(fmsgout,9875), legalfun(i), funname(i), j, atname(j), alpha(i,j,1), beta(i,j,1)  
        write(fmsgout,9876), legalfun(i), funname(i), j, atname(j), alpha(i,j,2), beta(i,j,2)  
  876 continue


 9875 format(i3,1x,a10,i3,2x,a10,' 1-2 lane facility: alpha: ',f5.2,' beta: ',f5.2)
 9876 format(i3,1x,a10,i3,2x,a10,' 3+  lane facility: alpha: ',f5.2,' beta: ',f5.2)

   	                                                                         
  990 continue                                                           
 
      return

	  end subroutine lookupin 
                                                                      
!************************************************************************************

      SUBROUTINE CAPSPD(fatal, severe)                                           
                                                                       
!     CAPSPD:                                                           
!     VERSION 2004.1                                                       
!     ORIGINAL CAPSPD MODULE WRITTEN BY RICHARD L. MERRICK              
                                                                       
      IMPLICIT INTEGER (A-Z)                                            

! parameters

	  logical*1      fatal, severe

! files
                                                                     
      integer*4    fcntrlin,  fnetin, flookup, fnetout,                        &
	               ferrmsg, fwarnmsg, fmsgout, fnerr,                          &
				   fcntlout,fdctout, fatypein, fguidewayin, frtncd
      COMMON /FIL/ fcntrlin, fnetin, flookup, fnetout,                         &
	               ferrmsg, fwarnmsg,fmsgout, fnerr, fcntlout, fdctout,        &
				   fatypein, fguidewayin, frtncd

      LOGICAL*1    TRACE(10), LIST(3)                                      
      COMMON /OPT/ TRACE,LIST                                          
         
	  INTEGER*4    RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR   
	  LOGICAL*1    RTNSPD 
	  COMMON /PARAM/ RUNYEAR, SPDCAP, CAPYEAR, BASEYEAR, RTNSPD             
                                                  
! node arrays

	  integer*4       zbrin(30000), zbrout(30000)
	  logical*1       nfun(30000,21), ncntl(30000,6)

      COMMON /narray/ zbrin, zbrout, nfun, ncntl


! lookup arrays

      Real*4     LnCap1hr(21,5), Speederfac(21,5), CycLen(21,5),       & 
	             PkSpFac(21,5), LocTrnSpFr(21,5), XprTrnSpFr(21,5),    & 
				 LocTrnSpPk(21,5), XprTrnSpPk(21,5), GrnPctFr(21,21),  &
				 Cap_Park(5), Cap_Ped(4), SpFr_Ped(4),                 &
				 Cap_DevDn(4), SpFr_DevDn(4), Cap_Drvwy(4),            &
				 SpFr_Drvwy(4), Cap_FacLn(9,3), ZVD_cntl(6),           &
				 Delay_prhb(6), Delay_fac(9), Delay_TLns(6),           &
				 Delay_Prg(2), Cap_Cntl(6),                            &
				 cappkfac, capmidfac, capnitefac,                      &
				 impwttime, impwtdist, minspeed,                       &
				 alpha(21,5,2), beta(21,5,2)


      COMMON /LOOKUP/ LnCap1hr, Speederfac, CycLen,                    &
	  			 PkSpFac, LocTrnSpFr, XprTrnSpFr,                      &
				 LocTrnSpPk, XprTrnSpPk, GrnPctFr,                     &
				 Cap_Park, Cap_Ped, SpFr_Ped,                          &
				 Cap_DevDn,SpFr_DevDn, Cap_Drvwy,                      &
				 SpFr_Drvwy, Cap_FacLn, ZVD_cntl,                      &  
				 Delay_prhb, Delay_fac, Delay_TLns,                    & 
				 Delay_Prg, Cap_cntl,                                  &
				 cappkfac, capmidfac, capnitefac,                      &
				 impwttime, impwtdist, minspeed, alpha, beta

!  characteristics variable values

	  integer*4    maxfuncl, maxat, maxfac, legalfun(21)
      real*4       minalpha /0.0/, maxalpha /20.0/,                    &          
	               minbeta /0.0/,  maxbeta /20.0/
	  character*1  legalfac(9), legalcntl(7),  legalprk(5),            &
	               legalhml(4), legallu(6), legalprhb(6)

	  character*2  legalffn(14)

	  character*10 funname(21), atname(5), parkname(5),                & 
	               facname(9), prhbname(4), cntlname(6), hmlname(4) 
	
	  COMMON /legalval/ maxfuncl, maxat, maxfac,                                &
	                    legalfun, legalfac, legalcntl,                          & 
	                    legalffn,  legalprk, legalhml,                          &
						legallu, legalprhb,                                     &
						funname, atname, parkname,                              &
						facname, prhbname,cntlname,hmlname                               



! link record variables

      integer*4     ID, Anode, Bnode, funcl,                              &
	                locclass1, locclass2,  A_oppfunc, B_oppfunc,          & 
					projnum, count1, count1yr, count2, count2yr,          &
			        dir, lanesAB, lanesBA, spdlimit,                      &
	                A_LeftLns, A_ThruLns, A_RightLns,                     &  
					B_LeftLns, B_ThruLns, B_RightLns,                     &
					state, revln, County, lanes, taz, walkmode,           &
					SpdLimRun           


      REAL*4	    length,  AAWT, count1fac, count2fac,                  &
	                SPfreeAB, SPfreeBA, SPpeakAB, SPpeakBA,               &
					TTfreeAB, TTfreeBA, TTpeakAB, TTpeakBA,               &
   					TTLinkFrAB, TTLinkFrBA, TTLinkPkAB, TTLinkPkBA,       &  
					IntDelFr_A, IntDelFr_B, IntDelPk_A, IntDelPk_B,       &
					CapPk3hrAB, CapPk3hrBA, CapMidAB, CapMidBA,           &
					CapNightAB, CapNightBA, Cap1hrAB, Cap1hrBA,           &
					TTPkEstAB, TTPkEstBA, TTPkPrevAB, TTPkPrevBA,         &
					TTPkAssnAB, TTPkAssnBA, TTPkLocAB, TTPkLocBA,         &
					TTPkXprAB, TTPkXprBA, TTFrLocAB, TTFrLocBA,           &
					TTFrXprAB, TTFrXprBA, TTwalkAB, TTwalkBA,             & 
					netalpha, netbeta, TTbikeAB, TTbikeBA,                &
					PkLocLUAB, PkLocLUBA, PkXprLUAB, PkXprLUBA,           &
					TTPkNStAB, TTPkNStBA, TTFrNStAB, TTFrNStBA,           &
					TTPkSkSAB, TTPkSkSBA, TTFrSkSAB, TTFrSkSBA   


	  character*1   factype, parking, pedactivty, developden,               &
	                drivewyden, landuse, A_Control, A_prohibit,             &
					B_Control, B_Prohibit,  revtime                       

	  character*2   fedfunc
	  character*4   count1type, count2type 
      character*5   fedfunc_AQ
	  character*20  Strname, A_CrossStr, B_CrossStr, SecondNam
      character*172 endofrec 


! TAZ areatype array

	  integer*4       tazat(30000) 
      COMMON /at/     tazat

! Guideway speeds 

	  real*4       gdwytt(300,4)
	  integer*4    gdwyid(300), gwcnt 
      COMMON /gw/  gdwyid, gdwytt, gwcnt



! counters and indices
   
      integer*4   i, j, ii, jj, k, ifun, ifac, iat, ipark, idevden, idrvwy,        & 
	              ipedact, icntrl, iprhb, ioppfun, iprgrss /2/,                 & 
                  lin2 /0/, linAB /0/, linBA /0/, lwarn /0/ 

! local variables
!			 Functional class
!				rank	funndx	 funcl
!				 1			 1	  1:	Freeway
!				 4			 2	  2:	Expressway
!				 5			 3	  3:	Class II major
!				 6			 4	  4:	Major tfare
!				 9			 5	  5:	Minor tfare
!				14			 6	  6:	Collector str
!				16			 7	  7:	Local Street
!				17			 8	  8:	Ramp
!				15			 9	  9:	Frontage Road
!				 2			10	 22:	HOV 2+ freeway
!				 3			11	 23:	HOV 3+ freeway
!                7          12   24:    HOV 2+ arterial 
!                8          13   25:    HOV 3+ arterial
!				12			14	 30:	Rail (Tran Only)
!				13			15	 40:	Busway(TranOnly)
!				10			16	 82:	HOV 2+ access 
!				11			17	 83:	Hwy 3+ access
!				18			18	 84:	Hwy to Transit 
!               21		    19   85:    Station walk
!				19			20	 90:	Centroid connect
!				20			21	 92:	Cenconn Transit
     
	  integer*4   funclrank(21) /1,4,5,6,9,14,16,17,15,2,3,7,8,12,13,10,11,18,21,19,20/
	  integer*4   oppfac, oppfun, lnsndx

	  logical*1   warn /.false./
 
      real*4      spl, tottime, grntime, redtime, zvd, zvd1, zvd2,             &
				  SPFrLinkAB, SPFrLinkBA, TTatspl,                             &
                  lfac, rfac, TTtran
				   
      character*1 F /'F'/, S /'S'/, W /'W'/
 
      integer*4	  numlinks(21,6) /126*0/,    num1wT(21,6) /126*0/,             &
	              num1w1(10,6) /60*0/,       num1w2(10,6) /60*0/,              &
				  num1w3(10,6) /60*0/    
      real*4	  linkmiles(21,6) /126*0./,  linkmiles1(10,6) /60*0./,         &
				  linkmiles2(10,6) /60*0./,  linkmiles3(10,6) /60*0./,         &   
	              lanemiles(21,6) /126*0./,                                    & 
				  capT(21,6) /126*0./,       cap1(10,6) /60*0./,               &
				  cap2(10,6) /60*0./,        cap3(10,6) /60*0./,               &
				  TTfrT(21,6) /126*0./,      TTfr1(10,6) /60*0./,              &
				  TTfr2(10,6) /60*0./ ,      TTfr3(10,6) /60*0./,              & 
				  TTpkT(21,6) /126*0./,      TTpk1(10,6) /60*0./,              &
				  TTpk2(10,6) /60*0./,       TTpk3(10,6) /60*0./,              &
				  TTLfrT(21,6) /126*0./,     TTLpkT(21,6) /126*0./,            & 
				  T(21,6),                   roadmiles(21,6) /126*0./,         &
				  splTT(21,6) /126*0./

! added for version 2.1
	 real*4       O_cap1AB, O_cap1BA, O_TTPkEstAB, O_TTPkEstBA,           &
				  O_TTPkPrevAB, O_TTPkPrevBA, O_TTPkAssnAB, O_TTPkAssnBA, &                                  
				  O_TTPkLocAB, O_TTPkLocBA, O_TTPkXprAB, O_TTPkXprBA,     &                                  
				  O_TTPkNStAB, O_TTPkNStBA, O_TTPkSkSAB, O_TTPkSkSBA,     &                                  
				  O_PkLocLUAB, O_PkLocLUBA, O_PkXprLUAB, O_PkXprLUBA

     integer*4    replnum /0/
	 logical*1    repl
	  

     
!  CAPSPD ENTRY POINT                                                   

      IF (TRACE(1)) print 9001                                                      
 9001 format('Trace(1):  Subroutine Capspd entered')             

!  Second pass through network                          
!  Read statement includes previously assigned data - all old fields start O_   
!        JWM 4/7/06                                     

  100 continue
      read(fnetin,9100,end=850) ID, length, dir, Anode, Bnode,                      &
 	                        funcl, fedfunc, fedfunc_AQ,                             &
							lanesAB, lanesBA,                                       &
							factype, spdlimit, parking, pedactivty,                 &
							developden, drivewyden, landuse,                        &
							A_LeftLns,A_ThruLns, A_RightLns,                        &		
							A_Control, A_Prohibit,                                  &
							B_LeftLns, B_ThruLns, B_RightLns,                       &
							B_Control, B_prohibit,                                  & 
							State, County, locclass1, locclass2,                    &
							revln, revtime, taz,                                    &
							O_cap1AB, O_cap1BA, O_TTPkEstAB, O_TTPkEstBA,           &
							O_TTPkPrevAB, O_TTPkPrevBA, O_TTPkAssnAB, O_TTPkAssnBA, &                                  
							O_TTPkLocAB, O_TTPkLocBA, O_TTPkXprAB, O_TTPkXprBA,     &                                  
							O_TTPkNStAB, O_TTPkNStBA, O_TTPkSkSAB, O_TTPkSkSBA,     &                                  
							O_PkLocLUAB, O_PkLocLUBA, O_PkXprLUAB, O_PkXprLUBA     
						                                 

 9100 format               (i10,   f10.0, i2,    i6,   i6,                & ! 1 ID
                            i8,    a2,    a5,                             & ! 2 funcl
							i8,    i8,                                    & ! 3 lanes
							a1,    i8,    a1,    a1,                      & ! 4 factyp
							a1,    a1,    a1,                             & ! 5 developden 
							i8,    i8,    i8,                             & ! 6 A_LeftLns
							a1,    a1,                                    & ! 7 A_Control
							i8,    i8,    i8,                             & ! 8 B_LeftLns
							a1,    a1,                                    & ! 9 B_Control
                            i8,    i8,    i8,    i8,                      & !State 
			     			i8,    a1,    i10,                            & !revln
							f10.0, f10.0, f10.0, f10.0,                   & !cap1AB (old stuff)
							f10.0, f10.0, f10.0, f10.0,                   & !TTPkPrevAB (all old)
							f10.0, f10.0, f10.0, f10.0,                   & !TTPkLocAB (all old)
							f10.0, f10.0, f10.0, f10.0,                   & !TTPkNStAB (all old)
							f10.0, f10.0, f10.0, f10.0)                     !PkLocLUAB (all old)


        lin2 = lin2 + 1
         

!  zero out variables

        SPFreeAB = 0.0                                                        
        SPFreeBA = 0.0                                                        
        SPPeakAB = 0.0                                                        
        SPPeakBA = 0.0                                                        
        TTFreeAB = 0.0                                                        
        TTFreeBA = 0.0                                                        
        TTPeakAB = 0.0                                                        
        TTPeakBA = 0.0                                                        
   	  	TTLinkFrAB = 0.0
		TTLinkFrBA = 0.0
		TTLinkPkAB = 0.0
		TTLinkPkBA = 0.0
		IntDelFr_A = 0.0 
		IntDelFr_B = 0.0 
		IntDelPk_A = 0.0 
		IntDelPk_B = 0.0
		CapPk3hrAB = 0.0 
		CapPk3hrBA = 0.0 
		CapMidAB = 0.0 
		CapMidBA = 0.0
		CapNightAB = 0.0 
		CapNightBA = 0.0 
		Cap1hrAB = 0.0 
		Cap1hrBA = 0.0
		TTPkEstAB = 0.0 
		TTPkEstBA = 0.0 
		TTPkPrevAB = 0.0 
		TTPkPrevBA = 0.0
		TTPkAssnAB = 0.0 
		TTPkAssnBA = 0.0 
		TTPkLocAB = 0.0 
		TTPkLocBA = 0.0     
		TTPkXprAB = 0.0 
		TTPkXprBA = 0.0 
		TTFrLocAB = 0.0
		TTFrLocBA = 0.0
		TTFrXprAB = 0.0 
		TTFrXprBA = 0.0 
		TTwalkAB = 0.0 
		TTwalkBA = 0.0							
        netalpha = 0.0
		netbeta = 0.0
		TTbikeAB = 999.0
		TTbikeBA = 999.0
		walkmode = 0
		PkLocLUAB = 0.0
		PkLocLUBA = 0.0
		PkXprLUAB = 0.0
		PkXprLUBA = 0.0
		TTPkNStAB = 0.0 
		TTPkNStBA = 0.0 
		TTFrNStAB = 0.0 
		TTFrNStBA = 0.0 
		TTPkSkSAB = 0.0 
		TTPkSkSBA = 0.0 
		TTFrSkSAB = 0.0 
		TTFrSkSBA = 0.0 


!  Non-directional variables - set lookup array indices
!  funcl, default =6 (collector)

        do 105 ifun = 1, maxfuncl
	      if (funcl .eq. legalfun(ifun)) go to 110
  105   continue
	    ifun = 6
	    lwarn = lwarn + 1
 	    call emsg_i(5,105,W,ID,County,funcl,'Illegal funcl, default=6(collector)     ') 



!  area type - pull from tazat file.       
!  Must be legal TAZ or fatal error (3/17/09)

  110   continue
        if (taz .le. 0 .or. taz .gt. 30000) go to 112

		iat = tazat(taz)
        if (iat .gt. 0 .and. iat .lt. 6) go to 114

!  bad taz on link record - kill 

  112   continue
	    ferr = ferr + 1
		fatal = .true.
 	    call emsg_i(5,112,F,ID,County,taz,'No match in taz/atype lookup ')

  114   continue

!  facility type, default = U, undivided

!  v.2.9 - Funcl = 85 - Station walk - accumulate counts, then on to fixed values

  115   continue
        if (legalfun(ifun) .eq. 85) go to 170


        do 118 ifac = 1, maxfac
	      if (factype .eq. legalfac(ifac)) go to 120
  118   continue
	    ifac = 9
	    lwarn = lwarn + 1
        call emsg_c(5,115,W,ID,County,factype,'Illegal factype, default=U(undivided)   ') 

!  speed limit, default, freeway, expressway = 55, all others = 35
!  v 2.4 - Adjust base year speed limit for rural 55 MPH roads that are now suburban
!          only for funcl 4,5,6,7

  120   continue

        if (spdlimit .ge. 10. .and. spdlimit .le. 80.) then
  	      SPL = float(spdlimit) 
          SpdLimRun = spdlimit          
        else
	      lwarn = lwarn + 1
          call emsg_i(5,120,W,ID,County,spdlimit,'Illegal Spd limit, def(frwy=55,oth=35)  ') 

      if (legalfun(ifun) .eq. 1  .or. legalfun(ifun) .eq. 2) then
	        SPL = 55.
			SpdLimRun = 55
   	      else
	        SPL = 35.
			SpdLimRun = 35
          endif
		endif

! v 2.4 speed limit adjustment

        if (RUNYEAR .ge. BASEYEAR .and.                                  &
	       (legalfun(ifun) .eq. 4 .or. legalfun(ifun) .eq. 5 .or.        &
		    legalfun(ifun) .eq. 6 .or. legalfun(ifun) .eq. 7) .and.      &
		    iat .lt. 5 .and. SpdLimit .gt. 49.0) then
  	      SPL = 45.0
		  SpdLimRun = 45 
	      lwarn = lwarn + 1
          call emsg_i(5,122,W,ID,County,SpdLimit,'Ex-rural speed reduced to 45.           ') 
        endif
  

! v 2.5 freeway speed limit adjustment


        if (RUNYEAR .ge. CAPYEAR .and.                                   & 
           (legalfun(ifun) .eq. 1  .or. legalfun(ifun) .eq. 2 .or.       &
            legalfun(ifun) .eq. 3  .or.                                  &
 	        legalfun(ifun) .eq. 22 .or. legalfun(ifun) .eq. 23 .or.      &
		    legalfun(ifun) .eq. 24 .or. legalfun(ifun) .eq. 25) .and.    &
		   (iat .lt. 5 .or. County .eq. 119) .and.                                          &
		    SpdLimit .gt. SPDCAP) then
  	      SPL = SPDCAP
		  SpdLimRun = SPDCAP 
	      lwarn = lwarn + 1
          call emsg_i(5,123,W,ID,County,SpdLimit,'Urban freeway speed reduced to SPDCAP.  ') 
        endif
  


!  parking - default "N" (no parking)

  125   continue
        do 128 ipark = 1, 5
	      if (parking .eq. legalprk(ipark)) go to 130
  128   continue
	    ipark = 2
	    lwarn = lwarn + 1
        call emsg_c(5,125,W,ID,County,parking,'Illegal parking code, default=N (none)  ') 

!  pedestrian activity - default = 'L' (low)

  130   continue
        do 133 ipedact = 1, 4
	      if (pedactivty .eq. legalhml(ipedact)) go to 135
  133   continue
	    ipedact = 3
	    lwarn = lwarn + 1
        call emsg_c(5,130,W,ID,County,pedactivty,'Illegal ped activity code, default=L    ') 
	
!  development density - default = L (low)

  135   continue
        do 138 idevden = 1, 4
	      if (developden .eq. legalhml(idevden)) go to 140
  138   continue
	    idevden = 3
	    lwarn = lwarn + 1
        call emsg_c(5,135,W,ID,County,developden,'Illegal develop density code, default=L ') 

!  driveway density - default = L (low)

  140   continue
        do 143 idrvwy = 1, 4
	      if (drivewyden .eq. legalhml(idrvwy)) go to 145
  143   continue
	    idrvwy = 3
	    lwarn = lwarn + 1
        call emsg_c(5,140,W,ID,County,drivewyden,'Illegal driveway density code, default=L') 

!  length - minimum 0.01

  145   continue
        if (length .gt. 0.01) go to 150
		lwarn = lwarn + 1
        call emsg_r(5,145,W,ID,County,length,'Minimum length set to 0.01 mi           ') 
	    length = 0.01

!  highway delay coefficients 
!  alpha and beta arrays are funcl * areatype * 2/3+ lane facilities (20,5,2)

  150   continue
        if (dir.eq.0.and.lanesAB + lanesBA .gt. 2) then
		  k = 2
		else if (dir .lt. 0 .and. lanesBA .gt. 1) then
		  k = 2
		else if (dir .gt. 0 .and. lanesAB .gt. 1) then 
		  k = 2
		else 
		  k = 1
		endif
        netalpha = alpha(ifun,iat,k)
        netbeta = beta(ifun,iat,k)
 		
!  Accumulate statistics for reports

  170   continue
        numlinks(ifun, iat) = numlinks(ifun,iat) + 1
        roadmiles(ifun,iat) = roadmiles(ifun,iat) + length  

!  trace

        if (trace(6))                                                               &
		write(fmsgout, 9170) ID, length, ifun, funcl, iat, ifac, factype,   &
							 ipark, parking, ipedact, pedactivty,                   &
							 idevden, developden,idrvwy, drivewyden 
							 
 9170   format('Trace(6) CAPSPD 170',i10,' Global inputs',                          &  
               ', Length:',f5.2,', Funcl:',2i4,', Areatp:',i2,                     &
               ', Factype:',i2,1x,a1,', Parking:',i2,1x,a1,	                	    &		  
               ', Ped_act:',i2,1x,a1,', Dev_Den:',i2,1x,a1,               		    &		  
               ', Drvwy_den:',i2,1x,a1)

!  v.2.9 - Funcl = 85 - Station walk - assign fixed values

          if (legalfun(ifun) .eq. 85) go to 830

!  A->B direction first, skip if B->A link
                                                                        
          if (dir .lt. 0) go to 500       
		  linAB = linAB + 1

!         B node characteristics 
	  		 
          if (bnode .gt. 0 .and. bnode .lt. 30001) go to 210

!           bad b node node number - default stop sign and oppfun = 6

          B_oppfunc = 6
		  icntrl = 3
		  ioppfun = 6           
 	      lwarn = lwarn + 1
          call emsg_i(5,200,W,ID,County,Bnode,'Bad BNODE, set control=S, oppfunc=6     ') 
          go to 230

!          get b node opposing functional class.  All funcl from approaching links in
!          nfun array.  Find "highest" ranking funcl other than current links funcl
!          (array funclrank).  Otherwise, use same funcl

  210       continue
			oppmax = 0
            oppfun = 0
			do 215 j = 1, maxfuncl
			  if (.not.nfun(Bnode,j)) go to 215
			  if (j .eq. ifun) go to 215
			  if (funclrank(j) .gt. oppmax) then
			    oppmax = funclrank(j)
				ioppfun = j
              endif
  215       continue
            if (oppfun .gt. 0) then
			  B_oppfunc = legalfun(oppfun)
			  ioppfun = j
            else
			  B_oppfunc = funcl
			  ioppfun = ifun 
			endif

!           B node control - default = S

  220       continue
            do 223 icntrl = 1, 6
	          if (B_Control .eq. legalcntl(icntrl)) go to 225
  223       continue
	        icntrl = 3
	        lwarn = lwarn + 1
            call emsg_c(5,220,W,ID,County,B_Control,'Bad B_Control, default=S (stop)         ') 

!           If signal (2), round about (6) or 4 way stop (4) also at node - 
!           default to that control - in that order
!           v 2.4 - Centroid connectors adjusted, but do not get warning

 
  225       continue
            if (icntrl.ne.2 .and. ncntl(Bnode,2)) then
              icntrl = 2

		      if (legalfun(ifun) .lt. 90) then
			    warn = lwarn + 1
                call emsg_c(5,225,W,ID,County,B_Control,'but signal found at B node, default=L   ') 
              endif

            elseif (icntrl.ne.6 .and. ncntl(Bnode,6)) then
              icntrl = 6

		      if (legalfun(ifun) .lt. 90) then
		        lwarn = lwarn + 1
                call emsg_c(5,226,W,ID,County,B_Control,'but roundabout found at B node,default=R') 
              endif

            elseif (icntrl.ne.4 .and. ncntl(Bnode,4)) then
              icntrl = 4

		      if (legalfun(ifun) .lt. 90) then
		        lwarn = lwarn + 1
                call emsg_c(5,227,W,ID,County,B_Control,'but 4-way found at B node, default=F    ') 
              endif
            endif

!           prohibitions on B node - default = N

  230       continue
            do 233 iprhb= 1, 6
	          if (B_Prohibit .eq. legalprhb(iprhb)) go to 235
  233       continue
	        iprhb = 3
	        lwarn = lwarn + 1
            call emsg_c(5,230,W,ID,County,B_Prohibit,'Bad B prohibitions, default=N (none)    ')

!           lanes ab - if zero - make it one lane

  235       continue
            if (lanesAB .lt. 1) then
		      lwarn = lwarn + 1
              call emsg_i(5,235,W,ID,County,LanesAB,'Dir<>-1, LanesAB will default to 1      ')
              lanesAB = 1.0
			endif

!  lnsndx - index to cap_facln array (factype x lanes)

			if (lanesAB .gt. 3) then 
			  lnsndx = 3
            else 
			  lnsndx = lanesAB
            endif

           if (trace(6))                                                               &
   		   write(fmsgout, 9236) ID, ioppfun, B_oppfunc,                                &  
		                     icntrl, B_Control,                                        &
							 iprhb, B_Prohibit,                                        &
                             lnsndx

 9236   format('Trace(6) CAPSPD 236',i10,' AB inputs',                                 & 
               ', Oppfun:',2i4, ', Control:',i2,1x,a1,                               &
               ', Turn prohibit:',i2,1x,a1,', Lnsndx:',i2)

!  Hourly Link capacity (units = veh / hr)

		    Cap1hrAB = LnCap1hr(ifun,iat) *                             &    
		               float(lanesAB) *                                     &
			    	   Cap_FacLn(ifac, lnsndx) *                            & 
	                   Cap_Cntl(icntrl) *                                   &
				       Cap_Park(ipark) *                                    &
				       Cap_Ped(ipedact) *                                   &
				       Cap_DevDn(idevden) *                                 &
				       Cap_Drvwy(idrvwy)	         

!  MAX hourly lane capacity: 2200 freeway, 2000 surface

            if (legalfun(ifun) .eq. 1  .or. legalfun(ifun) .eq. 2 .or.      &
                legalfun(ifun) .eq. 3  .or.                                 &
 	            legalfun(ifun) .eq. 22 .or. legalfun(ifun) .eq. 23 .or.     &
		        legalfun(ifun) .eq. 24 .or. legalfun(ifun) .eq. 25) then    
               Cap1hrAB = min(Cap1hrAB, 2200. * float(lanesAB))
			else
			   CAP1hrAB = min(Cap1hrAB, 2000. * float(lanesAB))
			endif
       

        if (trace(6))                                                               &
		write(fmsgout, 9237) ID, Cap1hrAB, LnCap1hr(ifun,iat), lanesAB,             &  
		                     Cap_FacLn(ifac, lnsndx), Cap_Cntl(icntrl),             &
							 Cap_Park(ipark), Cap_Ped(ipedact),                     &
                             Cap_DevDn(idevden), Cap_Drvwy(idrvwy)  

 9237   format('Trace(6) CAPSPD 237',i10,                                           &  
               ' Cap1hrAB:', f8.1, ', LnCap:',f8.1,                                &
               ', Lanes:',i2,', Factyp/ln:',f6.3,', Control:',f6.3                  &
			   ', Parking:', f6.3, ', PedAct:',f6.3,                                &
			   ', DevDen:', f6.3, ', Drvwy den:',f6.3)

!  Free speed - link (units = MPH)

            SPFrLinkAB = spl *                                              &
			             Speederfac(ifun,iat) *                             &
						 SpFr_Ped(ipedact) *                                &
						 SpFr_DevDn(idevden) *                              &
						 SpFr_Drvwy(idrvwy)

        if (trace(6))                                                               &
		write(fmsgout, 9238) ID, SPFrLinkAB, spl,Speederfac(ifun,iat),              &  
		                     SpFr_Ped(ipedact), SpFr_DevDn(idevden),                 &
							 SpFr_Drvwy(idrvwy), PkSpFac(ifun,iat)                                      
  
 9238   format('Trace(6) CAPSPD 238',i10,                                          &  
               ' SpFrLinkAB:', f8.1, ', spl:',f8.1,                                &
               ', Speederfac:',f6.3,', PedAct:',f6.3,', DevDen:',f6.3,             &
			   ', Drvwy den:',f6.3,', Peakfac:',f6.3)


!  Nonsignalized Intersection delay (units = seconds) - 

             if (icntrl .eq. 2) go to 300 

			 IntDelFr_B = ZVD_cntl(icntrl) *                                &
			              Delay_prhb(iprhb) 

!  turn lanes

            lfac = 1.0
	        if (B_LeftLns .eq. 1) then
			    lfac = Delay_Tlns(2)
              else if (B_LeftLns .gt. 1) then
			    lfac = Delay_TLns(4)
            endif

			rfac = 1.0      
            if (B_RightLns .ge. 1) rfac = Delay_TLns(6)

		    IntDelFr_B = IntDelFr_B * lfac * rfac

            if (trace(6))                                                          &
  		    write(fmsgout, 9239) ID, IntDelFr_B, ZVD_cntl(icntrl),                 &   
				             Delay_prhb(iprhb), lfac, rfac                             
  
 9239   format('Trace(6) CAPSPD 239',i10,' Unsignalized IntDelFr_B:', f8.2,         &  
               ' ZVD_cntl:', f6.3, ', Delay_prhb:',f6.3,                           &
               ', lfac:',f6.3,', rfac:',f6.3)


            go to 400

!  Signalized intersection

  300       continue
			tottime = cyclen(ifun,iat)
			grntime = tottime * grnpctfr(ifun,ioppfun)
			redtime = tottime - grntime
			zvd = (redtime / tottime) * ((redtime / 2.0) + 0.0)


!  factors  - Progressive signals (Delay_prg) not yet coded. 
!             iprgrss set to 2 above (not progressive), factor = 1.0

            IntDelFr_B = zvd *                                             &
                         Delay_prhb(iprhb) *                               &
						 Delay_fac(ifac) *                                 & 
						 Delay_Prg(iprgrss)

!  turn lanes

            lfac = 1.0
	        if (B_LeftLns .eq. 1) then
			    lfac = Delay_Tlns(1)
              else if (B_LeftLns .gt. 1) then
			    lfac = Delay_TLns(3)
            endif

			rfac = 1.0      
            if (B_RightLns .ge. 1) rfac = Delay_TLns(5)

		    IntDelFr_B = IntDelFr_B * lfac * rfac

!  Capacity factor

            Cap1hrAB = Cap1hrAB * GrnPctFr(ifun, ioppfun)

            if (trace(6))                                                          &
  		    write(fmsgout, 9300) ID, IntDelFr_B, tottime, grntime, redtime, zvd,   &
			       Delay_prhb(iprhb), Delay_fac(ifac), Delay_Prg(iprgrss),         &
				   lfac, rfac, Cap1hrAB                             
  
 9300   format('Trace(6) CAPSPD 239',i10,' Signalized IntDelFr_B:', f8.2,           &  
               ', time/red/green:', 3f6.1,', Zvd:',f6.3,                           &
			   ', Delay_prhb:',f6.3, ', Delay_fac:',f6.3,', Delay_Prg:',f6.3,      &
               ', lfac:',f6.3,', rfac:',f6.3,', Cap1hr:',f8.1)



!  calculate output variables for AB
!  Capacity by TOD

  400       continue
			CapPk3hrAB = Cap1hrAB * cappkfac
			CapMidAB =   Cap1hrAB * capmidfac
		    CapNightAB = Cap1hrAB * capnitefac 

!  link travel time - free and peak first

		    TTLinkFrAB = (length / SpFrLinkAB) * 60.
		    TTLinkPkAB = TTLinkFrAB / PkSpFac(ifun,iat)

!  Peak intersection delay - add capacity back in for no peak parking (A,P,B)

			IntDelPk_B = IntDelFr_B / PkSpFac(ifun, iat)
			if (parking .eq. 'A' .or. parking .eq. 'P' .or. parking .eq. 'B')       &
			   IntDelPk_B = IntDelPk_B * (1 / Cap_Park(ipark))

!  Composite (link & intersection) free travel time (minutes) and speed (MPH).  
!  Check for minimum speed.  If less - factor link and intersection proportionally 

            TTFreeAB = TTLinkFrAB + (IntDelFr_B / 60.)
            SPFreeAB = length / (TTfreeAB / 60.)
            TTatspl = length / (float(spdlimit) / 60.)
 
  
    		if (SPFreeAB .ge. minspeed) go to 420

		      lwarn = lwarn + 1
              call emsg_r(5,410,W,ID,County,SPFreeAB,'AB free speed < minimum. Minimum applied')

              pctlink = TTLinkFrAB / TTFreeAB 
              SPFreeAB = minspeed
              TTFreeAB = length / (minspeed / 60.)                                                      
			  TTLinkFrAB = TTFreeAB * pctlink
			  IntDelFr_B = (TTFreeAB - TTLinkFrAB) * 60. 

!  Composite (link & intersection) peak travel time (minutes) and speed (MPH).  
!  Check for minimum speed.  If less - factor link and intersection proportionally 


  420       continue
	        TTPkEstAB = TTLinkPkAB + (IntDelPk_B / 60.)                                                       
            SPPeakAB = length / (TTPkEstAB / 60.)

            if (SPPeakAB .ge. minspeed) go to 430

		      lwarn = lwarn + 1
              call emsg_r(5,420,W,ID,County,SPPeakAB,'AB peak speed < minimum. Minimum applied')

              pctlink = TTLinkPkAB / TTPkEstAB 
              SPPeakAB = minspeed
              TTPkEstAB = length / (minspeed / 60.)                                                      
			  TTLinkPkAB = TTPkEstAB * pctlink
			  IntDelPk_B = (TTPkEstAB - TTLinkPkAB) * 60. 

 
!  Feedback loop travel time and transit speeds.  Set initial values to estimated 
!  Retain look-up transit speed (PkLocLUAB, PkXprLUAB) for revision to speeds in 
!  feedback loop (McLelland, Aug 15)
!
!  Add Peak and offpeak Non-stop transit speed - set equal to peak or free speed
! 
  430       continue

            TTPkPrevAB = TTPkEstAB
			TTPkAssnAB = TTPkEstAB
			TTPeakAB = TTPkEstAB

            if (LocTrnSpFr(ifun, iat) .gt.0.) then     
			  TTtran = length / (LocTrnSpFr(ifun, iat) / 60.) 
			  TTFrLocAB = max(TTfreeAB / 0.90, TTtran)

!              write(6,9431) ID, length, ifun, iat, LocTrnSpFr(ifun,iat), TTfreeAB, TTFrLocAB, TTtran
! 9431         format('ID:', i10,' AB len=',f8.2, ' fun/at:',2i4,' lookup:',f6.2, ' ttfr:',f8.2, 'ttfrloc:',f8.2,' tttran:',f8.2)

            else
			  TTFrLocAB = 0.
			endif
			
			if (XprTrnSpFr(ifun, iat) .gt. 0.) then  
			  TTtran = length / (XprTrnSpFr(ifun, iat) / 60.) 
			  TTFrXprAB = max(TTfreeAB / 0.90, TTtran)
			else
			  TTFrXprAB = 0.
			endif

			if (LocTrnSpPk(ifun, iat) .gt. 0.) then
			  TTtran = length / (LocTrnSpPk(ifun, iat) / 60.) 
			  TTPkLocAB = max(TTPkEstAB / 0.90, TTtran)
			  PkLocLUAB = TTtran
			else
			  TTPkLocAB = 0.
			  PkLocLUAB = 0.
            endif

			if (XprTrnSpPk(ifun, iat) .gt. 0.) then
			  TTtran = length / (XprTrnSpPk(ifun, iat) / 60.) 
			  TTPkXprAB = max(TTPkEstAB / 0.90, TTtran)
			  PkXprLUAB = TTtran
            else
			  TTPkXprAB = 0.
			  PkXprLUAB = 0.
			endif

!   Peak and offpeak Non-stop transit speed - set equal to peak or free speed
!   Skip stop transit speeds - set to avg of local and express speeds 
!   McLelland - Dec. 29, 2005

            TTPkNStAB = TTPkAssnAB 
			TTFrNStAB = TTfreeAB 

            TTPkSkSAB = (TTPkLocAB + TTPkXprAB) / 2.0
		    TTFrSkSAB = (TTFrLocAB + TTFrXprAB) / 2.0

! Bike travel time (7 mph) - but no faster than TTfree
! No bikes on freeways, HOV, or guideways

      if (legalfun(ifun) .eq. 1  .or.                             &
	      legalfun(ifun) .eq. 22 .or. legalfun(ifun) .eq. 23 .or. &
		  legalfun(ifun) .eq. 24 .or. legalfun(ifun) .eq. 25 .or. &
		  legalfun(ifun) .eq. 30 .or. legalfun(ifun) .eq. 40) then  

		TTbikeAB = 999.
      else
		TTbikeAB = max(length * 8.57, TTfreeAB)
      endif



!YOJOE
!  GuideWay speed overrides
!  must be legal guideway (funcl=22  HOV 2+ - transit speeds only,
!                          funcl=23  HOV 3+ - transit speeds only,
!                          funcl=24  HOV 3+ - transit speeds only,
!                          funcl=25  HOV 3+ - transit speeds only,
!                          funcl=30  Rail, - all speeds 
!                          funcl=40  BRT - all speeds

            if (.not.(legalfun(ifun) .eq. 22 .or. legalfun(ifun) .eq. 23 .or. &
			          legalfun(ifun) .eq. 24 .or. legalfun(ifun) .eq. 25 .or. &
					  legalfun(ifun) .eq. 30 .or. legalfun(ifun) .eq. 40)) go to 450 
			do 442 j = 1, gwcnt
			  if (ID .eq. gdwyid(j)) then
			    TTPkLocAB = gdwytt(j,1)
				TTPkXprAB = TTPkLocAB
				TTFrLocAB = TTPkLocAB
				TTFrXprAB = TTPkLocAB

                TTPkNStAB = gdwytt(j,3)
				TTFrNStAB = gdwytt(j,3)

                TTPkSkSAB = (TTPkLocAB + TTPkXprAB) / 2.0
				TTFrSkSAB = (TTFrLocAB + TTFrXprAB) / 2.0

				if (legalfun(ifun) .eq. 22 .or. legalfun(ifun) .eq. 23 .or. &
				    legalfun(ifun) .eq. 24 .or. legalfun(ifun) .eq. 25) go to 445
				TTfreeAB   = TTPkLocAB
				TTpeakAB   = TTPkLocAB
				TTPkEstAB  = TTPkLocAB
				TTPkPrevAB = TTPkLocAB
				TTPkAssnAB = TTPkLocAB
				SPfreeAB = length / (TTfreeAB / 60.)
				SPpeakAB = length / (TTpeakAB / 60.)
                go to 445
              endif
  442       continue
            go to 450
  445       continue 			  
!            if (trace(6))                                                          &
  		    write(fmsgout, 9445) ID, legalfun(ifun), length, TTPkLocAB, TTfreeAB, SPfreeAB
 9445       format('Trace(6) CAPSPD 445',i10,' AB Guideway Speed override, funcl=', i3,   &  
              ' length', f6.2,' TT guideway / all traffic:', 2f8.2,', SPfree:',f6.2)

  450       continue





!  Accumulate statistics for reports

            linkmiles(ifun,iat) = linkmiles(ifun,iat) + length 
            num1wT(ifun,iat) =    num1wT(ifun,iat) + 1

			if (ifun .lt. 10) then
			  if (lnsndx .eq. 1) then 
  		        linkmiles1(ifun,iat) = linkmiles1(ifun,iat) + length
                num1w1(ifun,iat) =    num1w1(ifun,iat) + 1
			  else if (lnsndx .eq. 2) then 
  		        linkmiles2(ifun,iat) = linkmiles2(ifun,iat) + length
                num1w2(ifun,iat) =    num1w2(ifun,iat) + 1
			  else 
  		        linkmiles3(ifun,iat) = linkmiles3(ifun,iat) + length
                num1w3(ifun,iat) =    num1w3(ifun,iat) + 1
              endif
            endif

			lanemiles(ifun,iat) = lanemiles(ifun,iat) + (length * lanesAB) 
			capT(ifun,iat) = capT(ifun,iat) + Cap1hrAB 
			TTfrT(ifun,iat) = TTfrT(ifun,iat) + TTfreeAB 
			TTpkT(ifun,iat) = TTpkT(ifun,iat) + TTPkEstAB 
			TTLfrT(ifun,iat) = TTLfrT(ifun,iat) + TTLinkFrAB 
			TTLpkT(ifun,iat) = TTLpkT(ifun,iat) + TTLinkPkAB 
            splTT(ifun,iat)  = splTT(ifun,iat) + TTatspl

			if (ifun .lt. 10) then
			  if (lnsndx .eq. 1) then 
			    cap1(ifun,iat) = cap1(ifun,iat) + Cap1hrAB
			    TTfr1(ifun,iat) = TTfr1(ifun,iat) + TTFreeAB
			    TTpk1(ifun,iat) = TTpk1(ifun,iat) + TTPkEstAB
			  
			  else if (lnsndx .eq. 2) then 
			    cap2(ifun,iat) = cap2(ifun,iat) + Cap1hrAB
			    TTfr2(ifun,iat) = TTfr2(ifun,iat) + TTFreeAB
			    TTpk2(ifun,iat) = TTpk2(ifun,iat) + TTPkEstAB
			  
			  else 
			    cap3(ifun,iat) = cap3(ifun,iat) + Cap1hrAB
				TTfr3(ifun,iat) = TTfr3(ifun,iat) + TTFreeAB
			    TTpk3(ifun,iat) = TTpk3(ifun,iat) + TTPkEstAB
              endif
            endif


!  AB done - repeat for BA

  500     continue  

!  Skip if AB only link

          if (dir .gt. 0) go to 800
		  linBA = linBA + 1


!         A node characteristics 
		 
          if (Anode .gt. 0 .and. Anode .lt. 30001) go to 510

!           bad A node node number - default stop sign  and oppfun = 6

          A_oppfunc = 6
		  icntrl = 3
		  ioppfun = 6           
 	      lwarn = lwarn + 1
          call emsg_i(5,500,W,ID,County,Anode,'Bad ANODE, set control=S, oppfunc=6     ') 
		  go to 530

!          get a node opposing functional class.  All funcl from approaching links in
!          nfun array.  Find "highest" ranking funcl other than current links funcl
!          (array funclrank).  Otherwise, use same funcl

  510       continue
			oppmax = 0
            oppfun = 0
			do 515 j = 1, maxfuncl
			  if (.not.nfun(Anode,j)) go to 515
			  if (j .eq. ifun) go to 515
			  if (funclrank(j) .gt. oppmax) then
			    oppmax = funclrank(j)
				ioppfun = j
              endif
  515       continue
            if (oppfun .gt. 0) then
			  A_oppfunc = legalfun(oppfun)
			  ioppfun = j
            else
			  A_oppfunc = funcl
			  ioppfun = ifun 
			endif

!           Anode control - default = S

  520       continue
            do 523 icntrl = 1, 6
	          if (A_Control .eq. legalcntl(icntrl)) go to 525
  523       continue
	        icntrl = 3
	        lwarn = lwarn + 1
            call emsg_c(5,520,W,ID,County,A_Control,'Bad A_Control, default=S (stop)         ') 


!           If signal (2), round about (6) or 4 way stop (4) also at node - 
!           default to that control - in that order
!           v 2.4 - Centroid connectors adjusted, but do not get warning
 
  525       continue
            if (icntrl.ne.2 .and. ncntl(Anode,2)) then
              icntrl = 2

		      if (legalfun(ifun) .lt. 90) then
		        lwarn = lwarn + 1
                call emsg_c(5,525,W,ID,County,A_Control,'but signal found at A node, default=L   ') 
              endif

            elseif (icntrl.ne.6 .and. ncntl(Anode,6)) then
              icntrl = 6

		      if (legalfun(ifun) .lt. 90) then
		        lwarn = lwarn + 1
                call emsg_c(5,526,W,ID,County,A_Control,'but roundabout found at A node,default=R') 
              endif

            elseif (icntrl.ne.4 .and. ncntl(Anode,4)) then
              icntrl = 4

		      if (legalfun(ifun) .lt. 90) then
		        lwarn = lwarn + 1
                call emsg_c(5,527,W,ID,County,A_Control,'but 4-way found at A node, default=F'   ) 
              endif
            endif


!           prohibitions on A node - default = N

  530       continue
            do 533 iprhb= 1, 6
	          if (A_Prohibit .eq. legalprhb(iprhb)) go to 535
  533       continue
	        iprhb = 3
	        lwarn = lwarn + 1
            call emsg_c(5,530,W,ID,County,A_Prohibit,'Bad A prohibitions, default=N (none)    ')

!           lanes ab - if zero - make it one lane

  535       continue
            if (lanesBA .lt. 1) then
		      lwarn = lwarn + 1
              call emsg_i(5,235,W,ID,County,LanesAB,'Dir<>1, LanesBA will default to 1       ')
              lanesBA = 1.0
			endif

!  lnsndx - index to cap_facln array (factype x lanes)

			if (lanesBA .gt. 3) then 
			  lnsndx = 3
            else 
			  lnsndx = lanesBA
            endif

           if (trace(6))                                                               &
   		   write(fmsgout, 9536) ID, ioppfun, A_oppfunc,                                &  
		                     icntrl, A_Control,                                        &
							 iprhb, A_Prohibit,                                        &
                             lnsndx   

 9536   format('Trace(6) CAPSPD 536',i10,' BA inputs',                                 & 
               ', Oppfun:',2i4, ', Control:',i2,1x,a1,                             &
               ', Turn prohibit:',i2,1x,a1,', Lnsndx:',i2)

!  Hourly Link capacity (units = veh / hr)

		    Cap1hrBA = LnCap1hr(ifun,iat) *                             &    
		               float(lanesBA) *                                     &
			    	   Cap_FacLn(ifac, lnsndx) *                            & 
	                   Cap_Cntl(icntrl) *                                   &
				       Cap_Park(ipark) *                                    &
				       Cap_Ped(ipedact) *                                   &
				       Cap_DevDn(idevden) *                                 &
				       Cap_Drvwy(idrvwy)	         

!  MAX hourly lane capacity: 2200 freeway, 2000 surface

            if (legalfun(ifun) .eq. 1  .or. legalfun(ifun) .eq. 2 .or.      &
                legalfun(ifun) .eq. 3  .or.                                 &
 	            legalfun(ifun) .eq. 22 .or. legalfun(ifun) .eq. 23 .or.     &
		        legalfun(ifun) .eq. 24 .or. legalfun(ifun) .eq. 25) then    
               Cap1hrBA = min(Cap1hrBA, 2200. * float(lanesBA))             
			else                                                            
			   CAP1hrBA = min(Cap1hrBA, 2000. * float(lanesBA))             
            endif

        if (trace(6))                                                               &
		write(fmsgout, 9537) ID, Cap1hrBA, LnCap1hr(ifun,iat), lanesBA,             &  
		                     Cap_FacLn(ifac, lnsndx), Cap_Cntl(icntrl),             &
							 Cap_Park(ipark), Cap_Ped(ipedact),                     &
                             Cap_DevDn(idevden), Cap_Drvwy(idrvwy)  

 9537   format('Trace(6) CAPSPD 537',i10,                                           &  
               ' Cap1hrBA:', f8.1, ', LnCap:',f8.1,                                &
               ', Lanes:',i2,', Factyp/ln:',f6.3,', Control:',f6.3                  &
			   ', Parking:', f6.3, ', PedAct:',f6.3,                                &
			   ', DevDen:', f6.3, ', Drvwy den:',f6.3)

!  Free speed - link (units = MPH)

            SPFrLinkBA = spl *                                              &
			             Speederfac(ifun,iat) *                         &
						 SpFr_Ped(ipedact) *                                &
						 SpFr_DevDn(idevden) *                              &
						 SpFr_Drvwy(idrvwy)

        if (trace(6))                                                               &
		write(fmsgout, 9538) ID, SPFrLinkBA, spl,Speederfac(ifun,iat),              &  
		                     SpFr_Ped(ipedact), SpFr_DevDn(idevden),                 &
							 SpFr_Drvwy(idrvwy), PkSpFac(ifun,iat)                                      
  
 9538   format('Trace(6) CAPSPD 538',i10,                                          &  
               ' SpFrLinkBA:', f8.1, ', spl:',f8.1,                                &
               ', Speederfac:',f6.3,', PedAct:',f6.3,', DevDen:',f6.3,             &
			   ', Drvwy den:',f6.3,', Peakfac:',f6.3)

!  Nonsignalized Intersection delay (units = seconds) - 

             if (icntrl .eq. 2) go to 600 

			 IntDelFr_A = ZVD_cntl(icntrl) *                                       &
			              Delay_prhb(iprhb) 

!  turn lanes

            lfac = 1.0
	        if (A_LeftLns .eq. 1) then
			    lfac = Delay_Tlns(2)
              else if (A_LeftLns .gt. 1) then
			    lfac = Delay_TLns(4)
            endif

			rfac = 1.0      
            if (A_RightLns .ge. 1) rfac = Delay_TLns(6)

		    IntDelFr_A = IntDelFr_A * lfac * rfac

            if (trace(6))                                                           &
  		    write(fmsgout, 9539) ID, IntDelFr_A, ZVD_cntl(icntrl),                  & 
			             Delay_prhb(iprhb), lfac, rfac                             
  
 9539   format('Trace(6) CAPSPD 539',i10,' Unsignalized IntDelFr_A:', f8.2,         &  
               ' ZVD_cntl:', f6.3, ', Delay_prhb:',f6.3,                            &
               ', lfac:',f6.3,', rfac:',f6.3)



            go to 700

!  Signalized intersection

  600       continue
			tottime = cyclen(ifun,iat)
			grntime = tottime * grnpctfr(ifun,ioppfun)
			redtime = tottime - grntime
			zvd = (redtime / tottime) * ((redtime / 2.0) + 0.0)


!  factors  - Progressive signals (Delay_prg) not yet coded. 
!             iprgrss set to 2 above (not progressive), factor = 1.0

            IntDelFr_A = zvd *                                             &
                         Delay_prhb(iprhb) *                               &
						 Delay_fac(ifac) *                                 & 
						 Delay_Prg(iprgrss)

!  turn lanes

            lfac = 1.0
	        if (A_LeftLns .eq. 1) then
			    lfac = Delay_Tlns(1)
              else if (A_LeftLns .gt. 1) then
			    lfac = Delay_TLns(3)
            endif

			rfac = 1.0      
            if (A_RightLns .ge. 1) rfac = Delay_TLns(5)

		    IntDelFr_A = IntDelFr_A * lfac * rfac


!  Capacity factor

            Cap1hrBA = Cap1hrBA * GrnPctFr(ifun, ioppfun)


            if (trace(6))                                                          &
  		    write(fmsgout, 9600) ID, IntDelFr_A, tottime, grntime, redtime, zvd,   &
			       Delay_prhb(iprhb), Delay_fac(ifac), Delay_Prg(iprgrss),         &
				   lfac, rfac, Cap1hrBA                             
  
 9600   format('Trace(6) CAPSPD 600',i10,' Signalized IntDelFr_A:', f8.2,           &  
               ', time/red/green:', 3f6.1,', Zvd:',f6.3,                           &
			   ', Delay_prhb:',f6.3, ', Delay_fac:',f6.3,', Delay_Prg:',f6.3,      &
               ', lfac:',f6.3,', rfac:',f6.3,', Cap1hr:',f8.1)


!  calculate output variables for BA
!  Capacity by TOD

  700       continue
			CapPk3hrBA = Cap1hrBA * cappkfac
			CapMidBA =   Cap1hrBA * capmidfac
		    CapNightBA = Cap1hrBA * capnitefac 

!  link travel time - free and peak first

		    TTLinkFrBA = (length / SpFrLinkBA) * 60.
		    TTLinkPkBA = TTLinkFrBA / PkSpFac(ifun,iat)

!  Peak intersection delay - add capacity back in for no peak parking (A,P,B)

			IntDelPk_A = IntDelFr_A / PkSpFac(ifun, iat)
			if (parking .eq. 'A' .or. parking .eq. 'P' .or. parking .eq. 'B')       &
			   IntDelPk_A = IntDelPk_A * (1 / Cap_Park(ipark))

!  Composite (link & intersection) free travel time (minutes) and speed (MPH).  
!  Check for minimum speed.  If less - factor link and intersection proportionally 

            TTFreeBA = TTLinkFrBA + (IntDelFr_A / 60.)
            SPFreeBA = length / (TTfreeBA / 60.)
            TTatspl = length / (float(spdlimit) / 60.)
  
    		if (SPFreeBA .ge. minspeed) go to 720

		      lwarn = lwarn + 1
              call emsg_r(5,710,W,ID,County,SPFreeBA,'BA free speed < minimum. Minimum applied')

              pctlink = TTLinkFrBA / TTFreeBA 
              SPFreeBA = minspeed
              TTFreeBA = length / (minspeed / 60.)                                                      
			  TTLinkFrBA = TTFreeBA * pctlink
			  IntDelFr_A = (TTFreeBA - TTLinkFrBA) * 60. 

!  Composite (link & intersection) peak travel time (minutes) and speed (MPH).  
!  Check for minimum speed.  If less - factor link and intersection proportionally 

  720       continue
            TTPkEstBA = TTLinkPkBA + (IntDelPk_A / 60.)                                                       
            SPPeakBA = length / (TTPkEstBA / 60.)

            if (SPPeakBA .ge. minspeed) go to 730

		      lwarn = lwarn + 1
              call emsg_r(5,720,W,ID,County,SPPeakBA,'BA peak speed < minimum. Minimum applied')

              pctlink = TTLinkPkBA / TTPkEstBA 
              SPPeakBA = minspeed
              TTPkEstBA = length / (minspeed / 60.)                                                      
			  TTLinkPkBA = TTPkEstBA * pctlink
			  IntDelPk_A = (TTPkEstBA - TTLinkPkBA) * 60. 

			   
!  Feedback speeds and transit speeds, set feedbacks to estimated for initial run
!  Retain look-up transit speed (PkLocLUBA, PkXprLUBA) for revision to speeds in 
!  feedback loop (McLelland, Aug 15)

  730       continue
			TTPeakBA = TTPkEstBA
			TTPkPrevBA = TTPkEstBA
			TTPkAssnBA = TTPkEstBA

            if (LocTrnSpFr(ifun, iat) .gt.0.) then     
			  TTtran = length / (LocTrnSpFr(ifun, iat) / 60.) 
			  TTFrLocBA = max(TTfreeBA / 0.90, TTtran)

!            write(6,9731) ID, length, ifun, iat, LocTrnSpFr(ifun,iat), TTfreeBA, TTFrLocBA, TTtran
! 9731       format('ID:',i10,' BA len=',f8.2, ' fun/at:',2i4,' lookup:',f6.2, ' ttfr:',f8.2, 'ttfrloc:',f8.2,' tttran:',f8.2)

            else
			  TTFrLocBA = 0.
			endif
			
			if (XprTrnSpFr(ifun, iat) .gt. 0.) then  
			  TTtran = length / (XprTrnSpFr(ifun, iat) / 60.) 
			  TTFrXprBA = max(TTfreeBA / 0.90, TTtran)
			else
			  TTFrXprBA = 0.
			endif

			if (LocTrnSpPk(ifun, iat) .gt. 0.) then
			  TTtran = length / (LocTrnSpPk(ifun, iat) / 60.) 
			  TTPkLocBA = max(TTPkEstBA / 0.90, TTtran)
			  PkLocLUBa = TTtran
			else
			  TTPkLocBA = 0.
			  PkLocLUBA = 0.
            endif

			if (XprTrnSpPk(ifun, iat) .gt. 0.) then
			  TTtran = length / (XprTrnSpPk(ifun, iat) / 60.) 
			  TTPkXprBA = max(TTPkEstBA / 0.90, TTtran)
              PkXprLUBA = TTtran
            else
			  TTPkXprBA = 0.
			  PkXprLUBA = 0.
			endif


!   Peak and offpeak Non-stop transit speed - set equal to peak or free speed
!   Skip stop transit speeds set to average of local and express speeds 
!   McLelland - Dec. 29, 2005

            TTPkNStBA = TTPkAssnBA 
			TTFrNStBA = TTfreeBA 

            TTPkSkSBA = (TTPkLocBA + TTPkXprBA) / 2.0
		    TTFrSkSBA = (TTFrLocBA + TTFrXprBA) / 2.0

! Bike travel time (7 mph) - but no faster than TTfree
! No bikes on freeways, HOV, or guideways.  

      if (legalfun(ifun) .eq. 1  .or.                             &
	      legalfun(ifun) .eq. 22 .or. legalfun(ifun) .eq. 23 .or. &
		  legalfun(ifun) .eq. 24 .or. legalfun(ifun) .eq. 25 .or. &
		  legalfun(ifun) .eq. 30 .or. legalfun(ifun) .eq. 40) then  

		TTbikeBA = 999.
      else
		TTbikeBA = max(length * 8.57, TTfreeBA)
      endif



!  GuideWay speed overrides
!  must be legal guideway (funcl=22  HOV 2+ - transit speeds only,
!                          funcl=23  HOV 3+ - transit speeds only,
!                          funcl=24  HOV 3+ - transit speeds only,
!                          funcl=25  HOV 3+ - transit speeds only,
!                          funcl=30  Rail, - all speeds 
!                          funcl=40  BRT - all speeds

            if (.not.(legalfun(ifun) .eq. 22 .or. legalfun(ifun) .eq. 23 .or. &
			          legalfun(ifun) .eq. 24 .or. legalfun(ifun) .eq. 25 .or. &
					  legalfun(ifun) .eq. 30 .or. legalfun(ifun) .eq. 40)) go to 750 
			do 742 j = 1, gwcnt
			  if (ID .eq. gdwyid(j)) then
			    TTPkLocBA = gdwytt(j,2)
				TTPkXprBA = TTPkLocBA
				TTFrLocBA = TTPkLocBA
				TTFrXprBA = TTPkLocBA

                TTPkNStBA = gdwytt(j,4)
				TTFrNStBA = gdwytt(j,4)

                TTPkSkSBA = (TTPkLocBA + TTPkXprBA) / 2.0
				TTFrSkSBA = (TTFrLocBA + TTFrXprBA) / 2.0

				if (legalfun(ifun) .eq. 22 .or. legalfun(ifun) .eq. 23 .or. &
				    legalfun(ifun) .eq. 24 .or. legalfun(ifun) .eq. 25) go to 745

				TTfreeBA   = TTPkLocBA
				TTpeakBA   = TTPkLocBA
				TTPkEstBA  = TTPkLocBA
				TTPkPrevBA = TTPkLocBA
				TTPkAssnBA = TTPkLocBA
				SPfreeBA = length / (TTfreeBA / 60.)
				SPpeakBA = length / (TTpeakBA / 60.)
                go to 745
              endif
  742       continue
            go to 750
  745       continue 			  
!            if (trace(6))                                                          &
  		    write(fmsgout, 9745) ID, legalfun(ifun), length, TTPkLocBA, TTfreeBA, SPfreeBA
 9745       format('Trace(6) CAPSPD 745',i10,' BA Guideway Speed override, funcl=', i3,   &  
               ' length', f6.2,' TT guideway / all traffic:', 2f8.2,', SPfree:',f6.2)

  750       continue






!  Accumulate statistics for reports

            linkmiles(ifun,iat) = linkmiles(ifun,iat) + length 
            num1wT(ifun,iat) =    num1wT(ifun,iat) + 1

			if (ifun .lt. 10) then
			  if (lnsndx .eq. 1) then 
  		        linkmiles1(ifun,iat) = linkmiles1(ifun,iat) + length
                num1w1(ifun,iat) =    num1w1(ifun,iat) + 1
			  else if (lnsndx .eq. 2) then 
  		        linkmiles2(ifun,iat) = linkmiles2(ifun,iat) + length
                num1w2(ifun,iat) =    num1w2(ifun,iat) + 1
			  else 
  		        linkmiles3(ifun,iat) = linkmiles3(ifun,iat) + length
                num1w3(ifun,iat) =    num1w3(ifun,iat) + 1
              endif
            endif


			lanemiles(ifun,iat) = lanemiles(ifun,iat) + (length * lanesBA) 
			capT(ifun,iat) =   capT(ifun,iat) +   Cap1hrBA 
			TTfrT(ifun,iat) =  TTfrT(ifun,iat) +  TTfreeBA 
			TTpkT(ifun,iat) =  TTpkT(ifun,iat) +  TTPkEstBA 
			TTLfrT(ifun,iat) = TTLfrT(ifun,iat) + TTLinkFrBA 
			TTLpkT(ifun,iat) = TTLpkT(ifun,iat) + TTLinkPkBA 
            splTT(ifun,iat)  = splTT(ifun,iat) + TTatspl

			if (ifun .lt. 10) then
			  if (lnsndx .eq. 1) then 
			    cap1(ifun,iat) = cap1(ifun,iat) + Cap1hrBA
			    TTfr1(ifun,iat) = TTfr1(ifun,iat) + TTFreeBA
			    TTpk1(ifun,iat) = TTpk1(ifun,iat) + TTPKEstBA

			  else if (lnsndx .eq. 2) then 
			    cap2(ifun,iat) =  cap2(ifun,iat) +  Cap1hrAB
			    TTfr2(ifun,iat) = TTfr2(ifun,iat) + TTFreeBA
			    TTpk2(ifun,iat) = TTpk2(ifun,iat) + TTPkEstBA
			  
			  else 
			    cap3(ifun,iat) =  cap3(ifun, iat) +  Cap1hrAB
			    TTfr3(ifun,iat) = TTfr3(ifun,iat) + TTFreeBA
			    TTpk3(ifun,iat) = TTpk3(ifun,iat) + TTPkEstBA
			  endif
            endif


! Done with BA direction 

  800 continue

! Walk travel time (3 mph) - not directional
! No walking on freeways, HOV, or guideways.  
! Walkmode = 10 for ok links, 0 for freeways, etc.

      if (legalfun(ifun) .eq. 1  .or.                             &
	      legalfun(ifun) .eq. 22 .or. legalfun(ifun) .eq. 23 .or. &
		  legalfun(ifun) .eq. 24 .or. legalfun(ifun) .eq. 25 .or. &
		  legalfun(ifun) .eq. 30 .or. legalfun(ifun) .eq. 40) then  

		TTwalkAB = 999.
		TTwalkBA = 999.
		walkmode = 0
      else
	    TTwalkAB = length * 20.
		TTwalkBA = length * 20.
		walkmode = 10
      endif


! v.2.1 additions - keep old peak feedback traveltimes 
! April, 2006
! If RTNSPD (keep old speeds is true) - check new calcs vs old replace those that need replacing 

      repl = .false. 
      if (.not.RTNSPD) go to 840 

! AB dir - first check if old TTPeak is 0 (added link), use new stuff, else
!  check cap1hr, TTpeak and ttpkloc are the same, if so, write new.  If not, keep set of old times

      if (dir .lt. 0) go to 810

! if old ttpkassn is 0, new link - use new data

        if (.not.(O_TTPkAssnAB .gt. 0)) then 
		  repl = .true. 
		  go to 810
        end if

!  If cap, or TTpkest are different, link has changed - use new data

        if (abs(cap1hrAB-O_cap1AB) > 0.02 .or. abs(TTPkEstAB-O_TTPkEstAB) > 0.02) then
		  repl = .true.
		  go to 810
        end if

!  Keep old peak travel times


  805     continue
          TTPeakAB = O_TTPkAssnAB
		  TTPkPrevAB = O_TTPkPrevAB
		  TTPkAssnAB = O_TTPkAssnAB
		  TTPkLocAB = O_TTPkLocAB
		  TTPkXprAB = O_TTPkXprAB
		  TTPkNStAB = O_TTPkNStAB
		  TTPkSkSAB = O_TTPkSkSAB		   

! BA direction - same set of checks as AB

  810 continue 
      if (dir .gt. 0) go to 820

! if old ttpeak is 0, new link - use new data

        if (.not.(O_TTPkAssnBA .gt. 0)) then 
		  repl = .true. 
		  go to 820
        end if

!  If cap, TTpeakest or ttpkloclu are different, link has changed - use new data

        if (abs(cap1hrBA-O_cap1BA) > 0.02 .or. abs(TTPkEstBA - O_TTPkEstBA) > 0.02) then
		  repl = .true.
		  go to 820
		end if

!  Keep old peak travel times


  815     continue
          TTPeakBA = O_TTPkAssnBA
		  TTPkPrevBA = O_TTPkPrevBA
		  TTPkAssnBA = O_TTPkAssnBA
		  TTPkLocBA = O_TTPkLocBA
		  TTPkXprBA = O_TTPkXprBA
		  TTPkNStBA = O_TTPkNStBA
		  TTPkSkSBA = O_TTPkSkSBA		   

! if old times were NOT written, put comment in log file

  820 continue
      if (repl) then
	    replnum = replnum + 1
		write(fmsgout, 9820) replnum, ID, dir, ifun, TTpeakAB, TTpeakBA, TTPkLocAB, TTPkLocBA
 9820   format(i6, ' NEW data only for ID=',i8,' dir=',i2,' funcl=',i2,' TTpeak=',2f8.2,' TTpkLoc=',2f8.2)
      end if		      
      go to 840

! v. 2.9 Funcl = 85 - Walk to transit station - flat time of 1 minute

  830 continue
	  SPfreeAB = 3.0
	  SPpeakAB = 3.0
      TTfreeAB = 1.0
      TTpeakAB = 1.0
      TTPkEstAB = 1.0
      TTPkAssnAB = 1.0
      TTPkLocAB = 1.0
      TTPkXprAB = 1.0
      TTPkNStAB = 1.0
	  TTPkSkSAB = 1.0
      TTFrLocAB = 1.0
      TTFrXprAB = 1.0
      TTFrNStAB = 1.0
	  TTFrSkSAB = 1.0
      TTwalkAB = 1.0
	  TTbikeAB = 1.0
	  SPfreeBA = 3.0
	  SPpeakBA = 3.0
      TTfreeBA = 1.0
      TTpeakBA = 1.0
      TTPkEstBA = 1.0
      TTPkAssnBA = 1.0
      TTPkLocBA = 1.0
      TTPkXprBA = 1.0
      TTPkNStBA = 1.0
	  TTPkSkSBA = 1.0
      TTFrLocBA = 1.0
      TTFrXprBA = 1.0
      TTFrNStBA = 1.0
	  TTFrSkSBA = 1.0
      TTwalkBA = 1.0
	  TTbikeBA = 1.0
	  walkmode = 10
	  netalpha = 0.15
	  netbeta = 4.00
	  

! WRITE record

  840 continue

      write(fnetout, 9840)  ID,                                             & 
							SPfreeAB, SPfreeBA, SPpeakAB, SPpeakBA,         &
				        	TTfreeAB, TTfreeBA, TTpeakAB, TTpeakBA,         &
   	  				        TTLinkFrAB, TTLinkFrBA, TTLinkPkAB, TTLinkPkBA, &  
					        IntDelFr_A, IntDelFr_B, IntDelPk_A, IntDelPk_B, &
					        CapPk3hrAB, CapPk3hrBA, CapMidAB, CapMidBA,     &
					        CapNightAB, CapNightBA, Cap1hrAB, Cap1hrBA,     &
					        TTPkEstAB, TTPkEstBA, TTPkPrevAB, TTPkPrevBA,   &
					        TTPkAssnAB, TTPkAssnBA, TTPkLocAB, TTPkLocBA,   &
					        TTPkXprAB, TTPkXprBA, TTFrLocAB, TTFrLocBA,     &
					        TTFrXprAB, TTFrXprBA, TTwalkAB, TTwalkBA,       &
							netalpha, netbeta,    iat,      TTbikeAB,       &  
							TTbikeBA, walkmode,                             &
							PkLocLUAB, PkLocLUBa, PkXprLUAB, PkXprLUBA,     &
							TTPkNStAB, TTPkNStBA, TTFrNStAB, TTFrNStBA,     &    	
							TTPkSkSAB, TTPkSkSBA, TTFrSkSAB, TTFrSkSBA,     &
							SpdLimRun    	

 9840                format(i10,                                          & !ID
                            f10.4, f10.4, f10.4, f10.4,                   & !SPfreeAB
							f10.5, f10.5, f10.5, f10.5,                   & !TTfreeAB
							f10.5, f10.5, f10.5, f10.5,                   & !TTLinkfrAB
							f10.5, f10.5, f10.5, f10.5,                   & !IntDelFr_A
							f10.2, f10.2, f10.2, f10.2,                   & !CapPk3hrAB
							f10.2, f10.2, f10.2, f10.2,                   & !CapNightAB
							f8.4,  f8.4,  f8.4,  f8.4,                    & !TTPkestAB
							f8.4,  f8.4,  f8.4,  f8.4,                    & !TTPkAssnAB
							f8.4,  f8.4,  f8.4,  f8.4,                    & !TTPkXprAB
							f8.4,  f8.4,  f8.4,  f8.4,                    & !TTFrXprAB
							f8.4,  f8.4,  i8,    f8.4,                    & !netalpha
							f8.4,  i8,                                    & !TTbikeBA
							f8.4,  f8.4,  f8.4,  f8.4,                    & !PkLocLUAB
							f8.4,  f8.4,  f8.4,  f8.4,                    & !TTPkNStAB
							f8.4,  f8.4,  f8.4,  f8.4,                    & !TTPkSkSAB
							i8)                                             !SpdLimRun

 
! get next record
 
      go to 100                               
 

  850 continue                                                          

! WRITE dictionary file 

      write(fdctout,9850) 
 9850 format('Metrolina Capspeed OUT File'/'530'/                          &
             '"ID",I,1,10,0,10,0,,,"",,Blank,'/                            &
             '"SPfreeAB",R,11,10,0,10,4,,,"",,Blank,'/                     & 
             '"SPfreeBA",R,21,10,0,10,4,,,"",,Blank,'/                     & 
             '"SPpeakAB",R,31,10,0,10,4,,,"",,Blank,'/                     &
             '"SPpeakBA",R,41,10,0,10,4,,,"",,Blank,'/                     &
             '"TTfreeAB",R,51,10,0,10,5,,,"",,Blank,'/                     &  
             '"TTfreeBA",R,61,10,0,10,5,,,"",,Blank,'/                     & 
             '"TTpeakAB",R,71,10,0,10,5,,,"",,Blank,'/                     &
             '"TTpeakBA",R,81,10,0,10,5,,,"",,Blank,'/                     & 
             '"TTLinkFrAB",R,91,10,0,10,5,,,"",,Blank,'/                   & 
             '"TTLinkFrBA",R,101,10,0,10,5,,,"",,Blank,'/                  &
             '"TTLinkPkAB",R,111,10,0,10,5,,,"",,Blank,'/                  & 
             '"TTLinkPkBA",R,121,10,0,10,5,,,"",,Blank,'/                  &
             '"IntDelFr_A",R,131,10,0,10,2,,,"",,Blank,'/                  &
             '"IntDelFr_B",R,141,10,0,10,2,,,"",,Blank,'/                  &
             '"IntDelPk_A",R,151,10,0,10,2,,,"",,Blank,'/                  & 
             '"IntDelPk_B",R,161,10,0,10,2,,,"",,Blank,'/                  &
             '"CapPk3hrAB",R,171,10,0,10,2,,,"",,Blank,'/                  &
             '"CapPk3hrBA",R,181,10,0,10,2,,,"",,Blank,'/                  &
             '"CapMidAB",R,191,10,0,10,2,,,"",,Blank,'/                    & 
             '"CapMidBA",R,201,10,0,10,2,,,"",,Blank,'/                    & 
             '"CapNightAB",R,211,10,0,10,2,,,"",,Blank,'/                  &  
             '"CapNightBA",R,221,10,0,10,2,,,"",,Blank,'/                  & 
             '"Cap1hrAB",R,231,10,0,10,2,,,"",,Blank,'/                    &
             '"Cap1hrBA",R,241,10,0,10,2,,,"",,Blank,'/                    & 
             '"TTPkEstAB",R,251,8,0,8,4,,,"",,Blank,'/                   &
             '"TTPkEstBA",R,259,8,0,8,4,,,"",,Blank,'/                   & 
             '"TTPkPrevAB",R,267,8,0,8,4,,,"",,Blank,'/                  &
             '"TTPkPrevBA",R,275,8,0,8,4,,,"",,Blank,'/                  & 
             '"TTPkAssnAB",R,283,8,0,8,4,,,"",,Blank,'/                  &
             '"TTPkAssnBA",R,291,8,0,8,4,,,"",,Blank,'/                  &
             '"TTPkLocAB",R,299,8,0,8,4,,,"",,Blank,'/                   &
             '"TTPkLocBA",R,307,8,0,8,4,,,"",,Blank,'/                   &
             '"TTPkXprAB",R,315,8,0,8,4,,,"",,Blank,'/                   &
             '"TTPkXprBA",R,323,8,0,8,4,,,"",,Blank,'/                   &
             '"TTFrLocAB",R,331,8,0,8,4,,,"",,Blank,'/                   &
             '"TTFrLocBA",R,339,8,0,8,4,,,"",,Blank,'/                   &
             '"TTFrXprAB",R,347,8,0,8,4,,,"",,Blank,'/                   &
             '"TTFrXprBA",R,355,8,0,8,4,,,"",,Blank,'/                   &
             '"TTwalkAB",R,363,8,0,8,4,,,"",,Blank,'/                    &
             '"TTwalkBA",R,371,8,0,8,4,,,"",,Blank,'/                    & 
             '"alpha",R,379,8,0,8,4,,,"",,Blank,'/                       &
             '"beta",R,387,8,0,8,4,,,"",,Blank,'/                        &
             '"areatp",I,395,8,0,8,0,,,"",,Blank,'/                      &
             '"TTbikeAB",R,403,8,0,8,4,,,"",,Blank,'/                    &
             '"TTbikeBA",R,411,8,0,8,4,,,"",,Blank,'/                    &  
             '"walkmode",I,419,8,0,8,0,,,"",,Blank,'/                    &
             '"PkLocLUAB",R,427,8,0,8,4,,,"",,Blank,'/                   &
             '"PkLocLUBA",R,435,8,0,8,4,,,"",,Blank,'/                   &
             '"PkXprLUAB",R,443,8,0,8,4,,,"",,Blank,'/                   &
             '"PkXprLUBA",R,451,8,0,8,4,,,"",,Blank,'/                   &
             '"TTPkNStAB",R,459,8,0,8,4,,,"",,Blank,'/                   &
             '"TTPkNStBA",R,467,8,0,8,4,,,"",,Blank,'/                   &
             '"TTFrNStAB",R,475,8,0,8,4,,,"",,Blank,'/                   &
             '"TTFrNStBA",R,483,8,0,8,4,,,"",,Blank,'/                   &
             '"TTPkSkSAB",R,491,8,0,8,4,,,"",,Blank,'/                   &
             '"TTPkSkSBA",R,499,8,0,8,4,,,"",,Blank,'/                   &
             '"TTFrSkSAB",R,507,8,0,8,4,,,"",,Blank,'/                   &
             '"TTFrSksBA",R,515,8,0,8,4,,,"",,Blank,'/                   &                   
             '"SpdLimRun",I,523,8,0,8,0,,,"",,Blank,'/)                          
			 
			                     



!  Totals on summary arrays 


      ii = maxfuncl + 1
      jj = maxat + 1

      do 860 i = 1, maxfuncl
	    do 860 j = 1, maxat
	      numlinks(ii,j)  = numlinks(ii,j)  + numlinks(i,j)
	      numlinks(i,jj)  = numlinks(i,jj)  + numlinks(i,j)
		  numlinks(ii,jj) = numlinks(ii,jj) + numlinks(i,j)

	      num1wT(ii,j)  = num1wT(ii,j)  + num1wT(i,j)
	      num1wT(i,jj)  = num1wT(i,jj)  + num1wT(i,j)
		  num1wT(ii,jj) = num1wT(ii,jj) + num1wT(i,j)

  		  roadmiles(ii,j)  = roadmiles(ii,j)  + roadmiles(i,j)
		  roadmiles(i,jj)  = roadmiles(i,jj)  + roadmiles(i,j)
		  roadmiles(ii,jj) = roadmiles(ii,jj) + roadmiles(i,j)

  		  linkmiles(ii,j)  = linkmiles(ii,j)  + linkmiles(i,j)
		  linkmiles(i,jj)  = linkmiles(i,jj)  + linkmiles(i,j)
		  linkmiles(ii,jj) = linkmiles(ii,jj) + linkmiles(i,j)

		  lanemiles(ii,j)  = lanemiles(ii,j)  + lanemiles(i,j)
		  lanemiles(i,jj)  = lanemiles(i,jj)  + lanemiles(i,j)
		  lanemiles(ii,jj) = lanemiles(ii,jj) + lanemiles(i,j)

		  capT(ii,j)  = capT(ii,j)  + capT(i,j)
		  capT(i,jj)  = capT(i,jj)  + capT(i,j)
		  capT(ii,jj) = capT(ii,jj) + capT(i,j)

		  TTfrT(ii,j)  = TTfrT(ii,j)  + TTfrT(i,j)
		  TTfrT(i,jj)  = TTfrT(i,jj)  + TTfrT(i,j)
		  TTfrT(ii,jj) = TTfrT(ii,jj) + TTfrT(i,j)

		  TTpkT(ii,j)  = TTpkT(ii,j)  + TTpkT(i,j)
		  TTpkT(i,jj)  = TTpkT(i,jj)  + TTpkT(i,j)
		  TTpkT(ii,jj) = TTpkT(ii,jj) + TTpkT(i,j)

		  TTLfrT(ii,j)  = TTLfrT(ii,j)  + TTLfrT(i,j)
		  TTLfrT(i,jj)  = TTLfrT(i,jj)  + TTLfrT(i,j)
		  TTLfrT(ii,jj) = TTLfrT(ii,jj) + TTLfrT(i,j)

		  TTLpkT(ii,j)  = TTLpkT(ii,j)  + TTLpkT(i,j)
		  TTLpkT(i,jj)  = TTLpkT(i,jj)  + TTLpkT(i,j)
		  TTLpkT(ii,jj) = TTLpkT(ii,jj) + TTLpkT(i,j)

		  splTT(ii,j)  = splTT(ii,j)  + splTT(i,j)
		  splTT(i,jj)  = splTT(i,jj)  + splTT(i,j)
		  splTT(ii,jj) = splTT(ii,jj) + splTT(i,j)

   860 continue

! roadway links only totals

     ii = 10
     jj = maxat + 1
     do 870 i = 1, 9
	   do 870 j = 1, maxat
		 linkmiles1(ii,j)  = linkmiles1(ii,j)  + linkmiles1(i,j)
		 linkmiles1(i,jj)  = linkmiles1(i,jj)  + linkmiles1(i,j)
		 linkmiles1(ii,jj) = linkmiles1(ii,jj) + linkmiles1(i,j)

		 linkmiles2(ii,j)  = linkmiles2(ii,j) +  linkmiles2(i,j)
		 linkmiles2(i,jj)  = linkmiles2(i,jj) +  linkmiles2(i,j)
		 linkmiles2(ii,jj) = linkmiles2(ii,jj) + linkmiles2(i,j)

		 linkmiles3(ii,j)  = linkmiles3(ii,j) +  linkmiles3(i,j)
		 linkmiles3(i,jj)  = linkmiles3(i,jj) +  linkmiles3(i,j)
		 linkmiles3(ii,jj) = linkmiles3(ii,jj) + linkmiles3(i,j)

		  cap1(ii,j)  = cap1(ii,j)  + cap1(i,j)
		  cap1(i,jj)  = cap1(i,jj)  + cap1(i,j)
		  cap1(ii,jj) = cap1(ii,jj) + cap1(i,j)

		  cap2(ii,j)  = cap2(ii,j)  + cap2(i,j)
		  cap2(i,jj)  = cap2(i,jj)  + cap2(i,j)
		  cap2(ii,jj) = cap2(ii,jj) + cap2(i,j)

		  cap3(ii,j)  = cap3(ii,j)  + cap3(i,j)
		  cap3(i,jj)  = cap3(i,jj)  + cap3(i,j)
		  cap3(ii,jj) = cap3(ii,jj) + cap3(i,j)

		  TTfr1(ii,j)  = TTfr1(ii,j)  + TTfr1(i,j)
		  TTfr1(i,jj)  = TTfr1(i,jj)  + TTfr1(i,j)
		  TTfr1(ii,jj) = TTfr1(ii,jj) + TTfr1(i,j)

		  TTfr2(ii,j)  = TTfr2(ii,j)  + TTfr2(i,j)
		  TTfr2(i,jj)  = TTfr2(i,jj)  + TTfr2(i,j)
		  TTfr2(ii,jj) = TTfr2(ii,jj) + TTfr2(i,j)

		  TTfr3(ii,j)  = TTfr3(ii,j)  + TTfr3(i,j)
		  TTfr3(i,jj)  = TTfr3(i,jj)  + TTfr3(i,j)
		  TTfr3(ii,jj) = TTfr3(ii,jj) + TTfr3(i,j)

		  TTpk1(ii,j)  = TTpk1(ii,j)  + TTpk1(i,j)
		  TTpk1(i,jj)  = TTpk1(i,jj)  + TTpk1(i,j)
		  TTpk1(ii,jj) = TTpk1(ii,jj) + TTpk1(i,j)

		  TTpk2(ii,j)  = TTpk2(ii,j)  + TTpk2(i,j)
		  TTpk2(i,jj)  = TTpk2(i,jj)  + TTpk2(i,j)
		  TTpk2(ii,jj) = TTpk2(ii,jj) + TTpk2(i,j)

		  TTpk3(ii,j)  = TTpk3(ii,j)  + TTpk3(i,j)
		  TTpk3(i,jj)  = TTpk3(i,jj)  + TTpk3(i,j)
		  TTpk3(ii,jj) = TTpk3(ii,jj) + TTpk3(i,j)

	      num1w1(ii,j)  = num1w1(ii,j)  + num1w1(i,j)
	      num1w1(i,jj)  = num1w1(i,jj)  + num1w1(i,j)
		  num1w1(ii,jj) = num1w1(ii,jj) + num1w1(i,j)

	      num1w2(ii,j)  = num1w2(ii,j)  + num1w2(i,j)
	      num1w2(i,jj)  = num1w2(i,jj)  + num1w2(i,j)
		  num1w2(ii,jj) = num1w2(ii,jj) + num1w2(i,j)

	      num1w3(ii,j)  = num1w3(ii,j)  + num1w3(i,j)
	      num1w3(i,jj)  = num1w3(i,jj)  + num1w3(i,j)
		  num1w3(ii,jj) = num1w3(ii,jj) + num1w3(i,j)


   870 continue

		 
!  Reports

      write(fmsgout, 9890) lin2, linAB, linBA, lwarn
 9890 format(////'CAPSPD complete',/,                               &
             '  Total link records        ', i6,/                   & 
			 '  AB direction link records:', i6,/                   &
			 '  BA direction link records:', i6,/,                  &
			 '  Warnings issued:          ', i6)	   

!  Number of links

      
      write(fmsgout,9900)
 9900 format(/////'CAPSPD final statistics',//        &
             'Number of links'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
 9902 format('Funcl                          Area Type',/,16x, 5a10,'     TOTAL')
      do 905 i = 1, maxfuncl
        write(fmsgout,9905), legalfun(i), funname(i), (numlinks(i,j),j=1,maxat+1) 
  905 continue
      write(fmsgout,9906) (numlinks(maxfuncl+1,j),j=1,maxat+1) 
 9905 format(i3,1x,a10,2x,6i10)
 9906 format(9x,'TOTAL',2x,6i10)

!  Link miles

      write(fmsgout,9910)
 9910 format(//'Roadway miles'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 915 i = 1, maxfuncl
        write(fmsgout,9915), legalfun(i), funname(i), (roadmiles(i,j),j=1,maxat+1) 
  915 continue
      write(fmsgout,9916) (roadmiles(maxfuncl+1,j),j=1,maxat+1) 
 9915 format(i3,1x,a10,2x,6f10.2)
 9916 format(9x,'TOTAL',2x,6f10.2)

!  Lane miles

      write(fmsgout,9920)
 9920 format(//'Lane miles'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 925 i = 1, maxfuncl
        write(fmsgout,9915), legalfun(i), funname(i), (lanemiles(i,j),j=1,maxat+1) 
  925 continue
      write(fmsgout,9916) (lanemiles(maxfuncl+1,j),j=1,maxat+1) 

!  Avg Capacity - total 

      do 930 i = 1, maxfuncl+1
	    do 930 j = 1, maxat+1
          if (num1wT(i,j) .gt. 0.) then
 		    T(i,j) = capT(i,j) / num1wT(i,j)
          else
		    T(i,j) = 0.
          endif
  930 continue

      write(fmsgout,9930)
 9930 format(//'Average hourly capacity (All facilities)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 935 i = 1, maxfuncl
        write(fmsgout,9935), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
  935 continue
      write(fmsgout,9936) (T(maxfuncl+1,j),j=1,maxat+1) 
 9935 format(i3,1x,a10,2x,6f10.0)
 9936 format(9x,'TOTAL',2x,6f10.0)
 
!  Avg Capacity - 1 lane (directional)

      do 940 i = 1, 10
	    do 940 j = 1, maxat + 1 
          if (num1w1(i,j) .gt. 0.) then
 		    T(i,j) = cap1(i,j) / num1w1(i,j)
          else
		    T(i,j) = 0.
          endif
  940 continue

      write(fmsgout,9940)
 9940 format(//'Average hourly capacity - 1 lane (by direction)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 945 i = 1, 9
        write(fmsgout,9935), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
  945 continue
      write(fmsgout,9936) (T(10,j),j=1,maxat+1) 

!  Avg Capacity - 2 lane (directional)

      do 950 i = 1, 10
	    do 950 j = 1, maxat + 1
          if (num1w2(i,j) .gt. 0.) then
 		    T(i,j) = cap2(i,j) / num1w2(i,j)
          else
		    T(i,j) = 0.
          endif
  950 continue

      write(fmsgout,9950)
 9950 format(//'Average hourly capacity - 2 lanes(by direction)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 955 i = 1, 9
        write(fmsgout,9935), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
  955 continue
     write(fmsgout,9936) (T(10,j),j=1,maxat+1) 

!  Avg Capacity - 3+lane (directional)

      do 960 i = 1, 10
	    do 960 j = 1, maxat + 1
          if (num1w3(i,j) .gt. 0.) then
 		    T(i,j) = cap3(i,j) / num1w3(i,j)
          else
		    T(i,j) = 0.
          endif

  960 continue
      write(fmsgout,9960)
 9960 format(//'Average hourly capacity - 3+ lanes(by direction)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 965 i = 1, 9
        write(fmsgout,9935), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
  965 continue
      write(fmsgout,9936) (T(10,j),j=1,maxat+1) 

!  Avg Free speed - total 

      do 970 i = 1, maxfuncl + 1
	    do 970 j = 1, maxat + 1
          if (TTfrT(i,j) .gt. 0.) then
            T(i,j) = linkmiles(i,j) / (TTfrT(i,j) / 60.)
          else
		    T(i,j) = 0.
          endif
  970 continue

      write(fmsgout,9970)
 9970 format(//'Average free speed (All facilities)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 975 i = 1, maxfuncl
        write(fmsgout,9975), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
  975 continue
      write(fmsgout,9976) (T(maxfuncl+1,j),j=1,maxat+1) 
 9975 format(i3,1x,a10,2x,6f10.1)
 9976 format(9x,'TOTAL',2x,6f10.1)

 
!  Avg free speed - 1 lane (directional)

      do 980 i = 1, 10
	    do 980 j = 1, maxat + 1
          if (TTfr1(i,j) .gt. 0.) then
            T(i,j) = linkmiles1(i,j) / (TTfr1(i,j) / 60.)
          else
		    T(i,j) = 0.
          endif
  980 continue

      write(fmsgout,9980)
 9980 format(//'Average free speed - 1 lane (by direction)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 985 i = 1, 9
        write(fmsgout,9975), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
  985 continue
      write(fmsgout,9976) (T(10,j),j=1,maxat+1) 

!  Avg free speed - 2 lanes (directional)

      do 990 i = 1, 10
	    do 990 j = 1, maxat + 1
          if (TTfr2(i,j) .gt. 0.) then
            T(i,j) = linkmiles2(i,j) / (TTfr2(i,j) / 60.)
          else
		    T(i,j) = 0.
          endif
  990 continue

      write(fmsgout,9990)
 9990 format(//'Average free speed - 2 lanes (by direction)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 995 i = 1, 9
        write(fmsgout,9975), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
  995 continue
      write(fmsgout,9976) (T(10,j),j=1,maxat+1) 

!  Avg free speed - 3+ lanes (directional)

      do 1000 i = 1, 10
	    do 1000 j = 1, maxat + 1
          if (TTfr3(i,j) .gt. 0.) then
            T(i,j) = linkmiles3(i,j) / (TTfr3(i,j) / 60.)
          else
		    T(i,j) = 0.
          endif
 1000 continue

      write(fmsgout,1003)
 1003 format(//'Average free speed - 3+ lanes (by direction)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 1005 i = 1, 9
        write(fmsgout,9975), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
 1005 continue
      write(fmsgout,9976) (T(10,j),j=1,maxat+1) 

!  Avg loaded speed - total 

      do 1010 i = 1, maxfuncl + 1
	    do 1010 j = 1, maxat + 1
          if (TTpkT(i,j) .gt. 0.) then
            T(i,j) = linkmiles(i,j) / (TTpkT(i,j) / 60.)
          else
		    T(i,j) = 0.
          endif
 1010 continue

      write(fmsgout,1011)
 1011 format(//'Average estimated loaded speed (All facilities)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 1015 i = 1, maxfuncl
        write(fmsgout,9975), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
 1015 continue
      write(fmsgout,9976) (T(maxfuncl+1,j),j=1,maxat+1) 
 
!  Avg loaded speed - 1 lane (directional)

      do 1020 i = 1, 10
	    do 1020 j = 1, maxat + 1
          if (TTpk1(i,j) .gt. 0.) then
            T(i,j) = linkmiles1(i,j) / (TTpk1(i,j) / 60.)
          else
		    T(i,j) = 0.
          endif
 1020 continue

      write(fmsgout,1021)
 1021 format(//'Average estimated loaded speed - 1 lane (by direction)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 1025 i = 1, 9
        write(fmsgout,9975), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
 1025 continue
      write(fmsgout,9976) (T(10,j),j=1,maxat+1) 

!  Avg loaded speed - 2 lanes (directional)

      do 1030 i = 1, 10
	    do 1030 j = 1, maxat + 1
          if (TTpk2(i,j) .gt. 0.) then
            T(i,j) = linkmiles2(i,j) / (TTpk2(i,j) / 60.)
          else
		    T(i,j) = 0.
          endif
 1030 continue

      write(fmsgout,1031)
 1031 format(//'Average estimated loaded speed - 2 lanes (by direction)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 1035 i = 1, 9
        write(fmsgout,9975), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
 1035 continue
      write(fmsgout,9976) (T(10,j),j=1,maxat+1) 

!  Avg loaded speed - 3+ lanes (directional)

      do 1040 i = 1, 10
	    do 1040 j = 1, maxat + 1
          if (TTpk3(i,j) .gt. 0.) then
            T(i,j) = linkmiles3(i,j) / (TTpk3(i,j) / 60.)
          else
		    T(i,j) = 0.
          endif
 1040 continue

      write(fmsgout,1041)
 1041 format(//'Average estimated loaded speed - 3+ lanes (by direction)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 1042 i = 1, 9
        write(fmsgout,9915), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
 1042 continue
      write(fmsgout,9916) (T(10,j),j=1,maxat+1) 


!  Avg speed limit  - total 

      do 1043 i = 1, maxfuncl + 1
	    do 1043 j = 1, maxat + 1
          if (splTT(i,j) .gt. 0.) then
            T(i,j) = linkmiles(i,j) / (splTT(i,j) / 60.)
          else
		    T(i,j) = 0.
          endif
 1043 continue

      write(fmsgout,1044)
 1044 format(//'Average speed limit (All facilities)'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 1045 i = 1, maxfuncl
        write(fmsgout,9975), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
 1045 continue
      write(fmsgout,9976) (T(maxfuncl+1,j),j=1,maxat+1) 


!  Pct intersection delay to total delay - free speed

      do 1050 i = 1, maxfuncl + 1
	    do 1050 j = 1, maxat + 1
          if (TTfrT(i,j) .gt. 0.) then
            T(i,j) = (1- (TTLfrT(i,j) / TTfrT(i,j))) * 100.
          else
		    T(i,j) = 0.
          endif
 1050 continue

      write(fmsgout,1051)
 1051 format(//'Free speed - percentage of total travel time at intersection'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 1055 i = 1, maxfuncl
        write(fmsgout,9975), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
 1055 continue
      write(fmsgout,9976) (T(maxfuncl+1,j),j=1,maxat+1) 
 
!  Pct intersection delay to total delay - load speed

      do 1060 i = 1, maxfuncl + 1
	    do 1060 j = 1, maxat + 1
          if (TTpkT(i,j) .gt. 0.) then
            T(i,j) = (1- (TTLpkT(i,j) / TTpkT(i,j))) * 100.
          else
		    T(i,j) = 0.
          endif
 1060 continue

      write(fmsgout,1061)
 1061 format(//'Estimated loaded speed - percentage of total travel time at intersection'/)
      write(fmsgout,9902) (atname(j), j=1,maxat)
      do 1065 i = 1, maxfuncl
        write(fmsgout,9975), legalfun(i), funname(i), (T(i,j),j=1,maxat+1) 
 1065 continue
      write(fmsgout,9976) (T(maxfuncl+1,j),j=1,maxat+1) 
 
      END subroutine CAPSPD                                                                       

      END program
