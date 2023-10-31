      implicit none

      include 'MTXINC.for'
   
      integer tc_status
      integer n, m1,m3, i, j, nrows, ncols
	integer*4 narg,iknrnode,iknrcat
      integer false
      character*260 fname1,fname3
	character*200 ctlf,inf1,inf2,outf1
      integer*4, allocatable :: rowID(:)
      integer*4, allocatable :: colID(:)
      real*8 knrnode,rknrcat
	integer*4 knr_node,knr_cat
	integer*2 knrcat(25000)
 
      WRITE(*,'(////'' Program KNR_Loc_Cat ver TransCAD5.0''//
     +        ''     Written By:''//
     +        ''     Manish Jain''/
     +        ''     AECOM Consult, Inc.'')')
	WRITE (*,'(//)')

      call getarg(1,ctlf,narg)
	open (unit=5,file=ctlf)
c      open(5,file="KNR_Loc_Cat.ctl")
      read(5,'(a)') inf1            !KNR Node
	read(5,'(a)') inf2            !KNR Category
      read(5,'(a)') outf1           !KNR Flag
	close(5)
	open(12,file=inf2)
   40	read(12,*,end=50) knr_node,knr_cat
      if (knr_cat.lt.0 .or. knr_cat.gt.3) knr_cat=9
      knrcat(knr_node)=knr_cat
      goto 40
   50	continue

      call MTXF_INITMATDLL(tc_status)
      fname1 = inf1(1:len_trim(inf1))//char(0)
      fname3 = outf1(1:len_trim(outf1))//char(0)
      false = 0
	m1 = MTXF_LoadFromFile(fname1, false)
      if (m1 .eq. 0) then 
         print *, 'No HardwareBlock!!!' 
         stop  
      end if
	m3 = MTXF_LoadFromFile(fname3, false)
      nrows =  MTXF_GetNRows(m1)
      ncols =  MTXF_GetNCols(m1)
      allocate(rowID(1:nrows))
      allocate(colID(1:ncols))
      
      call MTXF_GetIDs(m1, 0, rowID)
      call MTXF_GetIDs(m1, 1, colID)

      do i=1,  nrows
         WRITE (*,'(''+  Processing Zone: '',i6)') rowID(i)
         do j=1, ncols
            call MTXF_GetElement(m1, rowID(i), colID(j), knrnode)
            if(knrnode.gt.0.0) then
	        iknrnode=knrnode
	        iknrcat=knrcat(iknrnode)
		    if (iknrcat.eq.2) then
	          rknrcat=iknrcat
                call MTXF_SETELEMENT(m3, rowID(i), colID(j), rknrcat)
		    endif
	      endif
         end do
      end do   
      call MTXF_Done(m1)
c      call MTXF_CLOSEFILE(m1)
      call MTXF_Done(m3)
c      call MTXF_CLOSEFILE(m3)
      end
      
