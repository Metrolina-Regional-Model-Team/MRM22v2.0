C     This program splits Drive Access trip matrix into following two parts:
C     1-Production to PNR Lot Trips, 2-PNR Lot to Attraction Trips
C     Compiled using CaliperMTXF.dll and CaliperMTXF.lib from TransCAD 4.8 Build 475
C     Written by Manish Jain, AECOM Consult, 12.21.06
C     Update, compiled using TransCAD5.0 Build 1590 lib and dlls

      implicit none

      include 'MTXINC.for'
   
      integer tc_status
      integer n, m1,m2,m3,m4, i, j, nrows, ncols, npnrs
	integer*4 narg,ipnrnode,icore1,icore2
      integer false
      character*260 fname1,fname2,fname3,fname4
	character*200 ctlf,inf1,inf2,inf3,inf4
	character*50 inp1,inp2
      integer*4, allocatable :: rowID(:)
      integer*4, allocatable :: colID(:)
      integer*4, allocatable :: pnrID(:)
	real*8,    allocatable :: setrow(:)
      real*8 pnrnode,trips,dr_segments,tr_segments,temp

      WRITE(*,'(////'' Program Drv2PNR2Attr ver TransCAD5.0''//
     +        ''     Written By:''//
     +        ''     Manish Jain''/
     +        ''     AECOM Transportation.'')')
	WRITE (*,'(//)')

      call getarg(1,ctlf,narg)
	open (unit=5,file=ctlf)
c      open(5,file="Drv2PNR2Attr.ctl")
      read(5,'(a)') inf1            !drv2PNR_file
	read(5,'(a)') inf2            !PNR2attr_file
      read(5,'(a)') inf3            !PNR_node_file
	read(5,'(a)') inf4            !PA_trip_file
      read(5,*) icore1              !trip_seg_core
      read(5,*) icore2              !pa_trips_core

	close(5)

      call MTXF_INITMATDLL(tc_status)
      fname1 = inf1(1:len_trim(inf1))//char(0)
      fname2 = inf2(1:len_trim(inf2))//char(0)
      fname3 = inf3(1:len_trim(inf3))//char(0)
      fname4 = inf4(1:len_trim(inf4))//char(0)
      false = 0
	m1 = MTXF_LoadFromFile(fname1, false)
      if (m1 .eq. 0) then 
         print *, 'No HardwareBlock!!!' 
         stop  
      end if
	m2 = MTXF_LoadFromFile(fname2, false)
	m3 = MTXF_LoadFromFile(fname3, false)
	m4 = MTXF_LoadFromFile(fname4, false)
      nrows =  MTXF_GetNRows(m4)
      ncols =  MTXF_GetNCols(m4)
	npnrs =  MTXF_GetNCols(m1)
      allocate(rowID(1:nrows))
      allocate(colID(1:ncols))
      allocate(pnrID(1:npnrs))
      allocate(setrow(1:npnrs))

      call MTXF_GetIDs(m4, 0, rowID)
      call MTXF_GetIDs(m4, 1, colID)
      call MTXF_GetIDs(m1, 1, pnrID)

         WRITE (*,'('' '')')

      temp=0.0
	dr_segments=0.0
	tr_segments=0.0
	pnrnode=0.0
	ipnrnode=0
	icore1=icore1-1
	icore2=icore2-1
      call MTXF_SETCORE(m1, icore1)
      call MTXF_SETCORE(m2, icore1)
      call MTXF_SETCORE(m4, icore2)
      
      trips=0.0
	do i=1, npnrs
      setrow(i)=0.0
	end do

C     Initialize tables to zero
	do i=1,  nrows
         WRITE (*,'(''+  INITIALIZING ZONE: '',i5)') rowID(i)
         call MTXF_SETVECTOR(m1, rowID(i), 0, setrow)
         call MTXF_SETVECTOR(m2, rowID(i), 1, setrow)
         
      end do   

C     Loop on every production zone
C
      WRITE (*,'('' '')')
	do i=1,  nrows
         WRITE (*,'(''+  PROCESSING ZONE: '',i5)') rowID(i)
         do j=1, ncols
            call MTXF_GetElement(m3, rowID(i), colID(j), pnrnode)
            if(pnrnode.gt.0.0) then

	        ipnrnode=pnrnode
              trips=0.0 
              call MTXF_GetElement(m4, rowID(i), colID(j), trips)
			if (trips.gt.0) then             
		     call MTXF_GetElement(m1, rowID(i), ipnrnode, temp)
	         dr_segments=temp+trips
	         temp=0.0
               call MTXF_SETELEMENT(m1, rowID(i), ipnrnode, dr_segments)
	         dr_segments=0.0

	         call MTXF_GetElement(m2, ipnrnode, colID(j), temp)
	         tr_segments=temp+trips
	         temp=0.0
               call MTXF_SETELEMENT(m2, ipnrnode, colID(j), tr_segments)
	         tr_segments=0.0
			end if

	      end if
         end do
      end do   
C     Closefile return an error, using "done" function
10    call MTXF_Done(m1)
c      call MTXF_CLOSEFILE(m1)
      call MTXF_Done(m2)
c      call MTXF_CLOSEFILE(m2)
      call MTXF_Done(m3)
c      call MTXF_CLOSEFILE(m3)
      call MTXF_Done(m4)
c      call MTXF_CLOSEFILE(m4)
      end
      
