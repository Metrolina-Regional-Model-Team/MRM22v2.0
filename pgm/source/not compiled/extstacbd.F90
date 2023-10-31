! * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
!                                                                       
!                   P R O G R A M :   E X T S T A C B D                         
!                                                                       
!                     VERSION  2.1 -  Feb., 2015                         
!                CHARLOTTE DEPARTMENT OF TRANSPORTATION                 
!                                                                       
!    Job to calculate closest external station and time to CBD files 
!    for input to trip generation model.
!
!    Must have completed highway skims before running

!    compile from \metrolina\pgm.  Must have caliper matrix dll and
!    lib files in pgm directory  (calipermtxf.lib, calipermtxf.dll,
!    shw32.dll)

!    command > df source\extstacbd calipermtxf.lib /list /fpscomp:general
!              /fpscomp:filesfromcmd

!    Search skim matrix for shortest path to an external station and  
!    CBD - CBD is set by a proxy taz on the Square (BofA).  Paths
!    are built by travel time.  Shortest is shortest distance 
!    v.1.2 - corrected problem reading possible integer field from SPMAT
!             used f10.0 instead of 10.2 in read stmt.
!            also added time and date block
!    v.2.0 - added Caliper matrix routines
!    v2.1 - changed proxy taz 10 10003 to match TA3461 & TAZ 3521
!           (was 10011 in TAZ2999 structure) (AHG - Feb 4, 2015)
!
!    McLelland,   Sept 29, 2006  - stored in extstacbd.f90

!    TransCad matrix routines

implicit none
   

      interface
      subroutine MTXF_INITMATDLL(ptc_status)
      integer ptc_status
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_INITMATDLL
      end subroutine
      end interface
      
      interface
      integer*2 function MTXF_CLEAR(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_CLEAR
      end function
      end interface

      interface
      integer*2 function MTXF_CLOSEFILE(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_CLOSEFILE
      end function
      end interface

      interface
      integer*2 function MTXF_CREATECACHE(m, Typ, apply, nSize)
      integer m
      integer Typ
      integer apply
      integer nSize
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_CREATECACHE
      end function
      end interface

      interface
      subroutine MTXF_DESTROYCACHE(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_DESTROYCACHE
      end subroutine
      end interface

      interface
      integer*2 function MTXF_DISABLECACHE(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_DISABLECACHE
      end function
      end interface

      interface
      integer*2 function MTXF_DONE(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_DONE
      end function
      end interface

      interface
      integer*2 function MTXF_ENABLECACHE(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_ENABLECACHE
      end function
      end interface

      interface
      integer*4 function MTXF_GETBASENCOLS(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETBASENCOLS
      end function
      end interface

      interface
      integer*4 function MTXF_GETBASENROWS(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETBASENROWS
      end function
      end interface

      interface
      integer*2 function MTXF_GETBASEVECTOR(m, iPos, dim, Array)
      integer m
      integer iPos
      integer dim
      real*8  Array(:)
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETBASEVECTOR
      end function
      end interface

      interface
      integer*2 function MTXF_GETCORE(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETCORE
      end function
      end interface

      interface
      integer*2 function MTXF_GETCURRENTINDEXPOS(m, dim)
      integer m
      integer dim
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETCURRENTINDEXPOS
      end function
      end interface

      interface
      integer*2 function MTXF_GETELEMENT(m, idRow, idCol, p)
      integer m
      integer idRow
      integer idCol
      real*8  p
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETELEMENT
      end function
      end interface

      interface
      integer*2 function MTXF_GETIDS(m, dim, ids)
      integer m
      integer dim
      integer ids (:)
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETIDS
      end function
      end interface

      interface
      subroutine MTXF_GETLABEL(m, iCore, szLabel)
      integer m
      integer iCore
      character*80 szLabel
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETLABEL
      end subroutine
      end interface

      interface
      integer*4 function MTXF_GETNCOLS(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETNCOLS
      end function
      end interface

      interface
      integer*2 function MTXF_GETNCORES(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETNCORES
      end function
      end interface

      interface
      integer*4 function MTXF_GETNROWS(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETNROWS
      end function
      end interface

      interface
      integer*2 function MTXF_GETVECTOR(m, ID, dim, Array)
      integer m
      integer ID
      integer dim
      real*8  Array(:)
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETVECTOR
      end function
      end interface

      interface
      integer*2 function MTXF_ISCOLMAJOR(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_ISCOLMAJOR
      end function
      end interface

      interface
      integer*2 function MTXF_ISFILEBASED(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_ISFILEBASED
      end function
      end interface

      interface
      integer*2 function MTXF_ISREADONLY(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_ISREADONLY
      end function
      end interface

      interface
      integer*2 function MTXF_ISSPARSE(m)
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_ISSPARSE
      end function
      end interface

      interface
      integer*4 function MTXF_LOADFROMFILE(szFileName, FileBased)
      character*260 szFileName
      integer FileBased
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_LOADFROMFILE
      end function
      end interface

      interface
      integer*2 function MTXF_OPENFILE(m, fRead)
      integer m
      integer fRead
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_OPENFILE
      end function
      end interface

      interface
      integer*2 function MTXF_SAVETOFILE(m, szFileName)
      integer m
      character*260 szFileName
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_SAVETOFILE
      end function
      end interface

      interface
      integer*2 function MTXF_SETBASEVECTOR(m, iPos, dim, Array)
      integer m
      integer iPos
      integer dim
      real*8  Array(:)
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_SETBASEVECTOR
      end function
      end interface

      interface
      integer*2 function MTXF_SETCORE(m, iCore)
      integer m
      integer iCore
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_SETCORE
      end function
      end interface

      interface
      integer*2 function MTXF_SETELEMENT(m, idRow, idCol, p)
      integer m
      integer idRow
      integer idCol
      real*8  p
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_SETELEMENT
      end function
      end interface

      interface
      integer*2 function MTXF_SETINDEX(m, dim, iIdx)
      integer m
      integer dim
      integer iIdx
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_SETINDEX
      end function
      end interface

      interface
      integer*2 function MTXF_SETVECTOR(m, ID, dim, Array)
      integer m
      integer ID
      integer dim
      real*8  Array(:)
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_SETVECTOR
      end function
      end interface

      interface
      subroutine MTXF_GETMATRIXTYPE(szType, m)
      character*80 szType
      integer m
      !DEC$ ATTRIBUTES DLLIMPORT :: MTXF_GETMATRIXTYPE
      end subroutine
      end interface


! TransCad Matrix variables
                                              
      integer tc_status
      integer m1, i, j, k, rtn
	  integer nrows, ncols
      integer filebased 
      character*80 spmat
      character*80 mtxtype
	  integer*4, allocatable :: rowID(:)
      integer*4, allocatable :: colID(:) 
      real*8,    allocatable :: RowLen(:)
	  logical*1, allocatable :: extstaflag(:)
          
      
!  TAZ selection sets

      integer*4    extsta(100) /100*0/, cbdproxy /10003/, proxyID /1/	                                                  
    
!  Local variables

      integer*4    loext /999999/, hiext /0/, cursta,                     &
	               ext(200) /200*0/, numext /0/, startext, stopext

	  real*4       curmin   
	  integer*4    printit /100/
      logical*1    first 


!  Run date and time

      integer*4    date_time(8)     
                                                                       
      character*20 VDATE/'ver 2.0, 09-29-2006'/
	  character*12 clk1, clk2, clk3
	  character*4  yr
	  character*2  mo, day, h, m                                          

				  

!  File variables

	  character*80 in05 /'parameter file'/,                                 &
	               out06, out14, out15, out16, out17, out18 
	  integer*4    fid, i_var05 /0/, i_var06 /0/, i_var14 /0/, i_var15 /0/, &
	               i_var16 /0/, i_var17 /0/, i_var18 /0/ 
	  logical*1    fatal /.false./

	  NAMELIST /INFILES/ spmat
	  NAMELIST /OUTFILES/ out06, out14, out15, out16, out17, out18     
	  NAMELIST /PARAM/ extsta, cbdproxy                                   
                                                                       
                                                                       
! Open Files

      open (5, file=' ', err=805, iostat=i_var05, READONLY, status='OLD')

      read(5,NML=INFILES)
 	  read(5,NML=OUTFILES)
	  read(5,NML=PARAM)

 
!&OUTFILES OUT06='report\extstacbd.txt',
!          OUT14='ext\dist_to_closest_extsta.asc', 
!          OUT15='ext\dist_to_closest_extsta.dct',
!          OUT16='landuse\dist_to_cbd.asc',
!          OUT17='landuse\dist_to_cbd.dct'
!          OUT18='report\return_code_extstacbd.txt'

      open (6, file=OUT06, err=806, iostat=i_var06, status = 'REPLACE', recl = 132)
  	  
      open (14, file=OUT14, err=814, iostat=i_var14, status = 'REPLACE', recl=30)

      open (15, file=OUT15, err=815, iostat=i_var15, status = 'REPLACE', recl=80)

      open (16, file=OUT16, err=816, iostat=i_var16, status = 'REPLACE', recl=30)

      open (17, file=OUT17, err=817, iostat=i_var17, status = 'REPLACE', recl=80)

      open (18, file=OUT18, err=818, iostat=i_var18, status = 'REPLACE', recl=8)

   10 continue

!  Time and date

	  call date_and_time(clk1, clk2, clk3, date_time)    
	  yr = clk1(1:4)
	  mo = clk1(5:6)
	  day = clk1(7:8)
	  h = clk2(1:2)
	  m = clk2(3:4)                                                           
      write (6,9002) VDATE, mo, day, yr, h, m
 9002 format('Metrolina Regional Model'/'ExtstaCBD ',a20/'Run:',a2,'-',a2,'-',a4,', ',a2,':',a2)


      write(6, NML=INFILES)
      write(6, NML=OUTFILES)
	  write(6, NML=PARAM)


! Open SPMAT matrix, get row and column IDs (TAZ) and allocate arrays
! Must append char(0) - C null char to indicate end of file name.  Also must have
! double \\ characters - TransCad 
! open length skim core (2nd core, ID = 1 under C counting standard 0,1,2)
 
      call MTXF_INITMATDLL(tc_status)
 
      spmat = trim(spmat)//char(0) 

      write(6,8995) spmat
 8995 format('Trace: matfile:',A80)

      filebased = 0
      m1 = MTXF_LoadFromFile(spmat, filebased)
  
      if (m1 .eq. 0) call tcerror(m1, 'Load matrix',spmat)

      call MTXF_CreateCache(m1, 0, 1,  90000)
 
      call MTXF_GetMatrixType(mtxtype, m1)

	  rtn = MTXF_SetCore(m1,1)
	  if (rtn .ne. 0) call tcerror(rtn, 'Set matrix core', spmat)

      nrows =  MTXF_GetNRows(m1)
      ncols =  MTXF_GetNCols(m1)

      allocate(rowID(1:nrows))
      allocate(colID(1:ncols))

      call MTXF_GetIDs(m1, 0, rowID)
      call MTXF_GetIDs(m1, 1, colID)
 
      allocate(RowLen(1:ncols))

	  allocate(extstaflag(1:nrows))      

     
! fill array of external stations based on param file
! input is allowed in old UTPS form 100,-111 as a range from 100 to 111
! up to 200 stations are allowed in current form
! minimum and maximum station number set to speed processing of large file
 
      do 40 i = 1, 100

	    if (numext .gt. 200) then
		  write(6,9010)
 9010     format( 'ERROR:  Maximum no. of external stations (200) exceeded.'/   &
                  '        Run Dead.  Either cut no. of stations or        '/   &
			      '        recompile with higher max. no. of stations.     ')
		  go to 890
        end if

!       Positive no.  - add station to ext array.  Check min and and max

	    if (extsta(i) .gt. 0) then 
		  startext = extsta(i)
          numext = numext + 1
		  ext(numext) = extsta(i)
		  if (ext(numext) .lt. loext) loext = ext(numext)
		  if (ext(numext) .gt. hiext) hiext = ext(numext)
  	      write(6,9005) i, extsta(i), numext, ext(numext), loext, hiext
 9005     format( 'trace: i/extsta:', 6i8)


!       Negative no.  - set range and fill all between after couple of error checks

        else if (extsta(i) .lt. 0) then
		  stopext = abs(extsta(i))
  	      write(6,9005) i, extsta(i), numext, ext(numext), loext, hiext

		  if (startext .eq. 0) then
		    write(6, 9020) extsta(i) 
 9020		format ( 'ERROR:  Cannot start with end of range.  Run Dead:  ', i10)
            go to 890
          end if

		  if (stopext .lt. startext) then
		    write(6, 9030) startext, extsta(i) 
 9030		format ( 'ERROR:  Illegal range in extsta.  Run Dead:  ', 2i10)
            go to 890
          end if
 
	      do j = startext + 1, stopext
 	  	    numext = numext + 1
	        if (numext .gt. 200) then
		      write(6,9010)
		      go to 890
            end if
			ext(numext) = j
   	        write(6,9006) i, extsta(i), numext, ext(numext), startext, stopext
 9006       format( 'trac2: i/extsta:', 6i8)
          end do
		  if (ext(numext) .gt. hiext) hiext = ext(numext)
        end if
   40 continue
	  
	  if (numext .eq. 0) then
	    write(6, 9040) 
 9040   format( 'ERROR :  No external stations coded.  Run Dead')
		go to 890
      end if
   		 
	  write (6,9050) numext, loext, hiext
 9050 format( 'External Station listing. No. stations=',i4/           &
              '   Lowest station no.', i6,' Highest station no.', i6) 
	  do i = 1, numext
        write(6, 9060) i, ext(i)
	  end do		  	 
 9060 format(10x,i4,i10) 	  

!     Initialize flag array
      do j = 1, ncols
	    extstaflag(j) = .false.
	  end do

! read spmat matrix

      first = .true.
  100 continue
      do 190 i=1, nrows

! reset distance to station 
	    curmin = 999.	  
        cursta = 0

	    if (mod(i,printit) .eq. 0 .or. i .eq. nrows) then
		  write(*,9105) i, rowID(i)
 9105     format('+',' Processing row=',i6, ' TAZ=',i6)
        end if
        
		call MTXF_GETVECTOR(m1, rowID(i), 0, RowLen)

! first row in - set extstaflag and colID of cbdproxy

        if (.not.first) go to 120
        do j=1, ncols
		  if (colID(j) .eq. cbdproxy) proxyID = j
          do k = 1,numext
		    if (colID(j) .eq. ext(k)) extstaflag(j) = .true.
		  end do
		end do
		first = .false.

  120   continue

! write len to cbd file.  cbdproxy is taz in cbd used for len
! for that taz, len is zero (it is null in spmat)
 
        if (RowID(i) .eq. cbdproxy) RowLen(i) = 0.
        write(16,9120) rowID(i), cbdproxy, RowLen(proxyID)
 9120   format(2i10,f10.6)
     
! find minimum distance to an external station

        do j =1, ncols
		  if (extstaflag(j)) then
		    if (RowLen(j) .lt. curmin .and. RowID(i) .ne. colID(j)) then
			  curmin = RowLen(j)
			  cursta = colID(j)
			end if
		  end if
		end do

! write closest extsta to file

	    write(14, 9120) rowID(i), cursta, curmin

  190 continue

! write dictionary files
      write(15,9200)
      write(17,9200)

 9200 format(' '/'30'/                         &
             '"From",I,1,10,0,10,0,,,"",,,'/   &
             '"To",I,11,10,0,10,0,,,"",,,'/    &
             '"Len",F,21,10,0,10,6,,,"",,,')

      print *

      go to 900

! File error section

  805 fid = 5
      fatal = .true.
      print 9801,  fid, in05, i_var05
      write(6,9801) fid, in05, i_var05
	  go to 890

  806 fid = 6
      fatal = .true.
      print 9801,  fid, out06, i_var06
      write(6,9801) fid, out06, i_var06
	  go to 890

  814 fid = 14
      fatal = .true.
      print 9801,  fid, out14, i_var14
      write(6,9801) fid, out14, i_var14
	  go to 890

  815 fid = 15
      fatal = .true.
      print 9801,  fid, out15, i_var15
      write(6,9801) fid, out15, i_var15
	  go to 890

  816 fid = 16
      fatal = .true.
      print 9801,  fid, out16, i_var16
      write(6,9801) fid, out16, i_var16
	  go to 890

  817 fid = 17
      fatal = .true.
      print 9801,  fid, out17, i_var17
      write(6,9801) fid, out17, i_var17
	  go to 890

  818 fid = 18
      fatal = .true.
      print 9801,  fid, out18, i_var18
      write(6,9801) fid, out18, i_var18
	  go to 890

 9801 format( 'ERROR:  File problem, file:',i3,' ', a80,/':  iostat=', i5, ' Run Dead')

!  fatal close
	  
  890 continue

      call MTXF_Done(m1)

      rtn = 24
      write(18, 9901) rtn

	  write(6,9890)
      close	(5, disp='keep') 
      close	(6, disp='keep') 
      close	(14, disp='keep') 
      close	(15, disp='keep') 
      close	(16, disp='keep') 
      close	(17, disp='keep') 
      close	(18, disp='keep') 
      print 9890 
 9890 format(' Abnormal stop')
      stop 24

! normal close
  900 continue

      call MTXF_Done(m1)

      rtn = 0
      write(18, 9901) rtn

	  write(6,9900)
      close	(5, disp='keep') 
      close	(6, disp='keep') 
      close	(14, disp='keep') 
      close	(15, disp='keep') 
      close	(16, disp='keep') 
      close	(17, disp='keep') 
      close	(18, disp='keep') 
      print 9900 

 9900 format(' Normal stop')
 9901 format(i8)
      stop 0
	  end                                                               
!
!
!  Error message subroutine
! 
      subroutine tcerror(errcode, step, fname)

	  integer errcode
	  character*20 step
	  character*260 fname

      character*60 errmsg
	  integer i

	  ! TransCad Matrix error messages

      integer tcerrcnt /43/
      integer tcerr(43)                                         &
	     /  -1,  -2,  -3,  -4,  -5,  -6,  -7,  -8,  -9, -10,    &
	       -11, -12, -13, -14, -15, -16, -17, -18, -19, -20,    &
	       -21, -22, -23, -24, -25, -26, -27, -28, -29, -30,    &
	       -31, -32, -33, -34, -35, -36, -37, -38, -39, -40,    &
	       -41, -42,-950 /                                             
      character*60 tcmsg(43)                                    &
				/'Database not opened',							& !  -1
				 'Invalid set',									& !  -2
				 'Invalid record',								& !  -3
				 'Invalid database',							& !  -4
				 'Invalid field name',							& !  -5 
				 'Invalid db_address',							& !  -6
				 'No current record',							& !  -7
				 'Set has no current owner',					& !  -8
				 'Set has no current member',					& !  -9
				 'Key value required',							& ! -10
				 'Invalid lock type',							& ! -11
				 'Record is owner of non-empty set(s)',			& ! -12
				 'Record is member of set(s)',					& ! -13
				 'Member already owned',						& ! -14
				 'Field is a compound key',						& ! -15
				 'Record not connected to set',					& ! -16
				 'Field is not a valid key',					& ! -17
				 'Record not legal owner of set',				& ! -18
				 'Record not legal member of set',				& ! -19
				 'Error in d_setpages (db open or bad param)',	& ! -20
				 'Incompatible dictionary file',				& ! -21
				 'Illegal attempt to delete system record',		& ! -22
				 'Attempt to lock previously locked rec or set',& ! -23
				 'Attempt to access unlocked record or set',	& ! -24
				 'Transaction id not be supplied',				& ! -25
				 'Transaction already active',					& ! -26
				 'Transaction not currently active',			& ! -27
				 'Transaction cannot begin due to locked files',& ! -28
				 'Attempt to free a lock inside a transaction', & ! -29
				 'Too many pages changed within transaction',	& ! -30
				 'Attempted update outside of transaction',		& ! -31
				 'Functions requires exclusive db access',		& ! -32
				 'Attempted to write lock a static file',		& ! -33
				 'No user id exists',							& ! -34
				 'Database file/path name too long',			& ! -35
				 'Invalid file number was passed to d_renfile', & ! -36
				 'Field is not an optional key',				& ! -37
				 'Field not defined in current record type',	& ! -38
				 'Record/field has/in a compound key',			& ! -39
				 'Invalid record or set number',				& ! -40
				 'Record or set not timestamped',				& ! -41
				 'Corrupted copy protected file',				& ! -42 
				 'Floating point error trap'/				  	  !-950

! System Errors
	  integer syserrcnt /26/
      integer syserr(26)                                        & 
		/-900,-901,-902,-903,-904,-905,-906,-907,-908,-909,     &
	     -910,-911,-912,-913,-914,-915,-916,-917,-918,-919,     &
		 -920,-921,-922,-933,-934,-935/
	  character*60 sysmsg(26)									&  
	             /'No more space on file',						& !-900
				 'System error',								& !-901
				 'Page fault -- changed during usage',			& !-902
				 'No working file set in dio',					& !-903
				 'Unable to allocate sufficient memory',		& !-904
				 'Unable to locate a file',						& !-905
				 'Unable to access db lock file',				& !-906
				 'Db lock file open/access error',				& !-907
				 'Inconsistent database locks',					& !-908
				 'File record limit reached',					& !-909
				 'Key file inconsistency detected',				& !-910
				 'Max concurrent user limit reached',			& !-911
				 'Bad seek on database file',					& !-912
				 'Invalid file specified',						& !-913
				 'Bad read on database/overflow file',			& !-914
				 'Network synchronization error',				& !-915
				 'Debugging check interrupt',					& !-916
				 'Network communications error',				& !-917
				 'Auto-recovery is in process',					& !-918
				 'Bad write on database/overflow file',			& !-919
				 'Unable to open lockmgr session',				& !-920
				 'DBUSERID is already used by another user',	& !-921
				 'The lock manager is busy',					& !-922
				 'Port/field not wide enough to show all text', & !-933
				 'Invalid input',								& !-934
				 'Device off-line or otherwise timed-out'/        !-935

! funcerr 
	  integer funcerrcnt /16/
      integer funcerr(16)                                       & 
		/   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,		&
		   10,  11,  12,  13,  14,  15/
	  character*60 funcmsg(16)                                  &
	            /'Normal return',                               &  ! 0  
				 'End of set',                                  &  ! 1
				 'Record not found',                            &  ! 2
				 'Duplicate key',                               &  ! 3
				 'Field type used out of sequence in d_keynext',&  ! 4
				 'Database file currently unavailable',         &  ! 5
				 'Record/set deleted since last accessed',      &  ! 6
				 'Record/set updated since last accessed',      &  ! 7
				 'Current record lock bit is set',				&  ! 8
				 'Current record lock bit is clear',			&  ! 9
				 'No more undo records in file',                &  !10
				 'Input function returns ESC',                  &  !11
				 'Editor needs re-sizing',                      &  !12
				 'Missing value',                               &  !13
				 'Interrupted operations',                      &  !14
				 'Moved to a different location'/                  !15

!     Job specific errors
      integer joberrcnt /5/
      integer joberr(5)                                         & 
		/  90,  91,  92,  93,  94 /
	  character*60 jobmsg(5)									&  
	           /'Mismatch number of rows', 						& ! 90
				'Mismatch number of columns',					& ! 91
				'Mismatch in Row IDs',							& ! 92
				'Mismatch in Column IDs',						& ! 93
				'Mismatch in Matrix type'/						  ! 94

  
!     0 return for file read, otherwise look through msg arrays

      if (errcode .eq. 0) then
	    errmsg = 'NO hardware block'
	    go to 900
	  end if

!     tc error
      do i =1,tcerrcnt
		if (errcode .eq. tcerr(i)) then
		  errmsg = tcmsg(i) 
		  go to 900
	    end if
	  end do

!     system error
      do i = 1,syserrcnt
	    if (errcode .eq. syserr(i)) then
		  errmsg = sysmsg(i)
		  go to 900
		end if
	  end do

!     function error
      do i = 1, funcerrcnt
	    if (errcode .eq. funcerr(i)) then
		  errmsg = funcmsg(i)
		  go to 900
		end if
	  end do

!     job error
      do i = 1, joberrcnt
	    if (errcode .eq. joberr(i)) then
		  errmsg = jobmsg(i)
		  go to 900
		end if
	  end do

!     can't find error code

      errmsg = 'Error msg not found'

!     write msg and kill job
  900 continue 
      fatal = .true.
      print 9001, errcode, errmsg, step, fname 
      write(6,9001) errcode, errmsg, step, fname

 	  rtn = 24
      write(7,9901) rtn               
	  
      call MTXF_Done(m1)
      call MTXF_Done(m2)
      call MTXF_Done(m3)
      close	(5, disp='keep') 
      close	(6, disp='keep') 
      close	(7, disp='keep') 
      close	(11, disp='keep') 

 9001 format(' FATAL matrix error: err=',i10,' msg=',a60,/' Step=',a20 /A)
 9901 format(i8)

	  stop
	  end subroutine