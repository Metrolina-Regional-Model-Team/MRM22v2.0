      implicit none

      include 'MTXINC.for'
   
      integer tc_status
      integer n, m1,m2,m3, i, j, nrows, ncols
	integer*4 prkindx,narg
      integer false
      real*8  f,cost,drivelen,parknode,drivetim,pnr2dest,pnrcost
      character*260 fname1,fname2,fname3
	character*200 ctlf,inf1,inf2,inf3
      integer*4, allocatable :: rowID(:)
      integer*4, allocatable :: colID(:)

      WRITE(*,'(////'' Program UPD_DA_Dist_Time_Cost v2 TransCAD5.0''//
     +        ''     Written By:''//
     +        ''     Manish Jain''/
     +        ''     AECOM'')')
	WRITE (*,'(//)')

      call getarg(1,ctlf,narg)
	open (unit=5,file=ctlf)
c	open (unit=5,file='shadowprice.ctl')
	read(5,'(a)') inf1  
	read(5,'(a)') inf2  
	read(5,'(a)') inf3  
      call MTXF_INITMATDLL(tc_status)
c	inf1='D://Metrolina//2030Build_Run9//skims//Test.mtx'
c	inf2='D://Metrolina//2030Build_Run9//skims//drivelength_peak.mtx'
      fname1 = inf1(1:len_trim(inf1))//char(0)
      fname2 = inf2(1:len_trim(inf2))//char(0)
      fname3 = inf3(1:len_trim(inf3))//char(0)
      false = 0
	m1 = MTXF_LoadFromFile(fname1, false)
      m2 = MTXF_LoadFromFile(fname2, false)
      m3 = MTXF_LoadFromFile(fname3, false)
      if (m1 .eq. 0) then 
         print *, 'No HardwareBlock!!!' 
         stop  
      end if
      nrows =  MTXF_GetNRows(m1)
      ncols =  MTXF_GetNCols(m1)
      allocate(rowID(1:nrows))
      allocate(colID(1:ncols))
      
      call MTXF_GetIDs(m1, 0, rowID)
      call MTXF_GetIDs(m1, 1, colID)

      call MTXF_SETCORE(m2, 1)
      call MTXF_SETCORE(m3, 1)
      do i=1,  nrows
         WRITE (*,'(''+  Processing Zone: '',i6)') rowID(i)
         do j=1, ncols
            call MTXF_SETCORE(m1, 0)
            call MTXF_GetElement(m1, rowID(i), colID(j), cost)
            call MTXF_SETCORE(m1, 2)
		  call MTXF_GetElement(m1, rowID(i), colID(j), parknode)
	      
		  if (parknode.gt.0) then
	        
			prkindx = parknode
              call MTXF_SETCORE(m2, 1)
		    call MTXF_GetElement(m2, rowID(i), prkindx, drivelen)

		    call MTXF_SETCORE(m2, 2)
		    call MTXF_GetElement(m2, rowID(i), prkindx, drivetim)

		    call MTXF_SETCORE(m2, 4)
		    call MTXF_GetElement(m2, rowID(i), prkindx, pnrcost)

		    call MTXF_GetElement(m3, prkindx, colID(j), pnr2dest)

	        if(cost.gt.0 .and. drivelen.gt.0) then
      
		      cost=100*cost+10*drivelen+0.5*pnrcost
                call MTXF_SETCORE(m1, 0)
                call MTXF_SETELEMENT(m1, rowID(i), colID(j), cost)
		      call MTXF_SETCORE(m1, 1)
                call MTXF_SETELEMENT(m1, rowID(i), colID(j), drivelen)
                call MTXF_SETCORE(m1, 3)
                call MTXF_SETELEMENT(m1, rowID(i), colID(j), drivetim)
                call MTXF_SETCORE(m1, 4)
                call MTXF_SETELEMENT(m1, rowID(i), colID(j), pnr2dest)
                call MTXF_SETCORE(m1, 7)
                call MTXF_SETELEMENT(m1, rowID(i), colID(j), pnrcost)

              endif

	      endif

         end do
      end do   
      call MTXF_Done(m1)
      call MTXF_Done(m2)
      call MTXF_Done(m3)
c      call MTXF_CLOSEFILE(m1)
c      call MTXF_CLOSEFILE(m2)
c      call MTXF_CLOSEFILE(m3)
      end
      
