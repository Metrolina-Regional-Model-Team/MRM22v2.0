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
