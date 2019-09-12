      SUBROUTINE def_quick (ng, ldef)
!
!svn $Id: def_quick.F 873 2017-10-05 20:27:10Z arango $
!================================================== Hernan G. Arango ===
!  Copyright (c) 2002-2018 The ROMS/TOMS Group                         !
!    Licensed under a MIT/X style license                              !
!    See License_ROMS.txt                                              !
!=======================================================================
!                                                                      !
!  This routine creates ROMS QUICKSAVE NetCDF file, it defines its     !
!  dimensions, attributes, and variables.                              !
!                                                                      !
!=======================================================================
!
      USE mod_param
      USE mod_parallel
      USE mod_iounits
      USE mod_ncparam
      USE mod_netcdf
      USE mod_scalars
      USE mod_sediment
!
      USE def_var_mod, ONLY : def_var
      USE strings_mod, ONLY : FoundError
!
      implicit none
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng
      logical, intent(in) :: ldef
!
!  Local variable declarations.
!
      logical :: got_var(NV)
      integer, parameter :: Natt = 25
      integer :: i, j, ifield, itrc, nvd3, nvd4, varid
      integer :: recdim, status
      integer :: DimIDs(32), t2dgrd(3), u2dgrd(3), v2dgrd(3)
      integer :: Vsize(4)
      integer :: def_dim
      integer :: b3dgrd(4)
      integer :: t3dgrd(4), u3dgrd(4), v3dgrd(4), w3dgrd(4)
      real(r8) :: Aval(6)
      character (len=120) :: Vinfo(Natt)
      character (len=256) :: ncname
!
      SourceFile="ROMS/Utility/def_quick.F"
!
!-----------------------------------------------------------------------
!  Set and report file name.
!-----------------------------------------------------------------------
!
      IF (FoundError(exit_flag, NoError, 79,                            &
     &               "ROMS/Utility/def_quick.F")) RETURN
      ncname=QCK(ng)%name
!
      IF (Master) THEN
        IF (ldef) THEN
          WRITE (stdout,10) ng, TRIM(ncname)
        ELSE
          WRITE (stdout,20) ng, TRIM(ncname)
        END IF
      END IF
!
!=======================================================================
!  Create a new quicksave file.
!=======================================================================
!
      DEFINE : IF (ldef) THEN
        CALL netcdf_create (ng, iNLM, TRIM(ncname), QCK(ng)%ncid)
        IF (FoundError(exit_flag, NoError, 97,                          &
     &                 "ROMS/Utility/def_quick.F")) THEN
          IF (Master) WRITE (stdout,30) TRIM(ncname)
          RETURN
        END IF
!
!-----------------------------------------------------------------------
!  Define file dimensions.
!-----------------------------------------------------------------------
!
        DimIDs=0
!
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'xi_rho',        &
     &                 IOBOUNDS(ng)%xi_rho, DimIDs( 1))
        IF (FoundError(exit_flag, NoError, 111,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'xi_u',          &
     &                 IOBOUNDS(ng)%xi_u, DimIDs( 2))
        IF (FoundError(exit_flag, NoError, 116,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'xi_v',          &
     &                 IOBOUNDS(ng)%xi_v, DimIDs( 3))
        IF (FoundError(exit_flag, NoError, 121,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'xi_psi',        &
     &                 IOBOUNDS(ng)%xi_psi, DimIDs( 4))
        IF (FoundError(exit_flag, NoError, 126,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'eta_rho',       &
     &                 IOBOUNDS(ng)%eta_rho, DimIDs( 5))
        IF (FoundError(exit_flag, NoError, 131,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'eta_u',         &
     &                 IOBOUNDS(ng)%eta_u, DimIDs( 6))
        IF (FoundError(exit_flag, NoError, 136,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'eta_v',         &
     &                 IOBOUNDS(ng)%eta_v, DimIDs( 7))
        IF (FoundError(exit_flag, NoError, 141,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'eta_psi',       &
     &                 IOBOUNDS(ng)%eta_psi, DimIDs( 8))
        IF (FoundError(exit_flag, NoError, 146,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'N',             &
     &                 N(ng), DimIDs( 9))
        IF (FoundError(exit_flag, NoError, 198,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 's_rho',         &
     &                 N(ng), DimIDs( 9))
        IF (FoundError(exit_flag, NoError, 203,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 's_w',           &
     &                 N(ng)+1, DimIDs(10))
        IF (FoundError(exit_flag, NoError, 208,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'tracer',        &
     &                 NT(ng), DimIDs(11))
        IF (FoundError(exit_flag, NoError, 213,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'NST',           &
     &                 NST, DimIDs(32))
        IF (FoundError(exit_flag, NoError, 219,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'Nbed',          &
     &                 Nbed, DimIDs(16))
        IF (FoundError(exit_flag, NoError, 224,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname, 'boundary',      &
     &                 4, DimIDs(14))
        IF (FoundError(exit_flag, NoError, 260,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        status=def_dim(ng, iNLM, QCK(ng)%ncid, ncname,                  &
     &                 TRIM(ADJUSTL(Vname(5,idtime))),                  &
     &                 nf90_unlimited, DimIDs(12))
        IF (FoundError(exit_flag, NoError, 280,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
        recdim=DimIDs(12)
!
!  Set number of dimensions for output variables.
!
        nvd3=3
        nvd4=4
!
!  Define dimension vectors for staggered tracer type variables.
!
        t2dgrd(1)=DimIDs( 1)
        t2dgrd(2)=DimIDs( 5)
        t2dgrd(3)=DimIDs(12)
        t3dgrd(1)=DimIDs( 1)
        t3dgrd(2)=DimIDs( 5)
        t3dgrd(3)=DimIDs( 9)
        t3dgrd(4)=DimIDs(12)
!
!  Define dimension vectors for staggered u-momentum type variables.
!
        u2dgrd(1)=DimIDs( 2)
        u2dgrd(2)=DimIDs( 6)
        u2dgrd(3)=DimIDs(12)
        u3dgrd(1)=DimIDs( 2)
        u3dgrd(2)=DimIDs( 6)
        u3dgrd(3)=DimIDs( 9)
        u3dgrd(4)=DimIDs(12)
!
!  Define dimension vectors for staggered v-momentum type variables.
!
        v2dgrd(1)=DimIDs( 3)
        v2dgrd(2)=DimIDs( 7)
        v2dgrd(3)=DimIDs(12)
        v3dgrd(1)=DimIDs( 3)
        v3dgrd(2)=DimIDs( 7)
        v3dgrd(3)=DimIDs( 9)
        v3dgrd(4)=DimIDs(12)
!
!  Define dimension vector for staggered w-momentum type variables.
!
        w3dgrd(1)=DimIDs( 1)
        w3dgrd(2)=DimIDs( 5)
        w3dgrd(3)=DimIDs(10)
        w3dgrd(4)=DimIDs(12)
!
!  Define dimension vector for sediment bed layer type variables.
!
        b3dgrd(1)=DimIDs( 1)
        b3dgrd(2)=DimIDs( 5)
        b3dgrd(3)=DimIDs(16)
        b3dgrd(4)=DimIDs(12)
!
!  Initialize unlimited time record dimension.
!
        QCK(ng)%Rindex=0
!
!  Initialize local information variable arrays.
!
        DO i=1,Natt
          DO j=1,LEN(Vinfo(1))
            Vinfo(i)(j:j)=' '
          END DO
        END DO
        DO i=1,6
          Aval(i)=0.0_r8
        END DO
!
!-----------------------------------------------------------------------
!  Define time-recordless information variables.
!-----------------------------------------------------------------------
!
        CALL def_info (ng, iNLM, QCK(ng)%ncid, ncname, DimIDs)
        IF (FoundError(exit_flag, NoError, 414,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
!
!-----------------------------------------------------------------------
!  Define time-varying variables.
!-----------------------------------------------------------------------
!
!  Define model time.
!
        Vinfo( 1)=Vname(1,idtime)
        Vinfo( 2)=Vname(2,idtime)
        WRITE (Vinfo( 3),'(a,a)') 'seconds since ', TRIM(Rclock%string)
        Vinfo( 4)=TRIM(Rclock%calendar)
        Vinfo(14)=Vname(4,idtime)
        status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idtime),     &
     &                 NF_TYPE, 1, (/recdim/), Aval, Vinfo, ncname,     &
     &                 SetParAccess = .TRUE.)
        IF (FoundError(exit_flag, NoError, 431,                         &
     &                 "ROMS/Utility/def_quick.F")) RETURN
!
!  Define time-varying depth of RHO-points.
!
        IF (Qout(idpthR,ng)) THEN
          Vinfo( 1)=Vname(1,idpthR)
          WRITE (Vinfo( 2),40) Vname(2,idpthR)
          Vinfo( 3)=Vname(3,idpthR)
          Vinfo(14)=Vname(4,idpthR)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idpthR,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idpthR),   &
     &                   NF_FOUT, nvd4, t3dgrd, Aval, Vinfo, ncname,    &
     &                   SetFillVal = .FALSE.)
          IF (FoundError(exit_flag, NoError, 541,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define time-varying depth of U-points.
!
        IF (Qout(idpthU,ng)) THEN
          Vinfo( 1)=Vname(1,idpthU)
          WRITE (Vinfo( 2),40) Vname(2,idpthU)
          Vinfo( 3)=Vname(3,idpthU)
          Vinfo(14)=Vname(4,idpthU)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idpthU,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idpthU),   &
     &                   NF_FOUT, nvd4, u3dgrd, Aval, Vinfo, ncname,    &
     &                   SetFillVal = .FALSE.)
          IF (FoundError(exit_flag, NoError, 561,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define time-varying depth of V-points.
!
        IF (Qout(idpthV,ng)) THEN
          Vinfo( 1)=Vname(1,idpthV)
          WRITE (Vinfo( 2),40) Vname(2,idpthV)
          Vinfo( 3)=Vname(3,idpthV)
          Vinfo(14)=Vname(4,idpthV)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idpthV,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idpthV),   &
     &                   NF_FOUT, nvd4, v3dgrd, Aval, Vinfo, ncname,    &
     &                   SetFillVal = .FALSE.)
          IF (FoundError(exit_flag, NoError, 581,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define time-varying depth of W-points.
!
        IF (Qout(idpthW,ng)) THEN
          Vinfo( 1)=Vname(1,idpthW)
          WRITE (Vinfo( 2),40) Vname(2,idpthW)
          Vinfo( 3)=Vname(3,idpthW)
          Vinfo(14)=Vname(4,idpthW)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idpthW,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idpthW),   &
     &                   NF_FOUT, nvd4, w3dgrd, Aval, Vinfo, ncname,    &
     &                   SetFillVal = .FALSE.)
          IF (FoundError(exit_flag, NoError, 601,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define free-surface.
!
        IF (Qout(idFsur,ng)) THEN
          Vinfo( 1)=Vname(1,idFsur)
          Vinfo( 2)=Vname(2,idFsur)
          Vinfo( 3)=Vname(3,idFsur)
          Vinfo(14)=Vname(4,idFsur)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idFsur,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idFsur),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 626,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define 2D U-momentum component.
!
        IF (Qout(idUbar,ng)) THEN
          Vinfo( 1)=Vname(1,idUbar)
          Vinfo( 2)=Vname(2,idUbar)
          Vinfo( 3)=Vname(3,idUbar)
          Vinfo(14)=Vname(4,idUbar)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idUbar,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idUbar),   &
     &                   NF_FOUT, nvd3, u2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 645,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define 2D V-momentum component.
!
        IF (Qout(idVbar,ng)) THEN
          Vinfo( 1)=Vname(1,idVbar)
          Vinfo( 2)=Vname(2,idVbar)
          Vinfo( 3)=Vname(3,idVbar)
          Vinfo(14)=Vname(4,idVbar)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idVbar,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idVbar),   &
     &                   NF_FOUT, nvd3, v2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 664,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define 2D Eastward momentum component at RHO-points.
!
        IF (Qout(idu2dE,ng)) THEN
          Vinfo( 1)=Vname(1,idu2dE)
          Vinfo( 2)=Vname(2,idu2dE)
          Vinfo( 3)=Vname(3,idu2dE)
          Vinfo(14)=Vname(4,idu2dE)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(21)='barotropic_eastward_sea_water_velocity'
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idu2dE,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idu2dE),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 684,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define 2D Northward momentum component at RHO-points.
!
        IF (Qout(idv2dN,ng)) THEN
          Vinfo( 1)=Vname(1,idv2dN)
          Vinfo( 2)=Vname(2,idv2dN)
          Vinfo( 3)=Vname(3,idv2dN)
          Vinfo(14)=Vname(4,idv2dN)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(21)='barotropic_northward_sea_water_velocity'
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idv2dN,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idv2dN),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 704,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define 3D U-momentum component.
!
        IF (Qout(idUvel,ng)) THEN
          Vinfo( 1)=Vname(1,idUvel)
          Vinfo( 2)=Vname(2,idUvel)
          Vinfo( 3)=Vname(3,idUvel)
          Vinfo(14)=Vname(4,idUvel)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idUvel,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idUvel),   &
     &                   NF_FOUT, nvd4, u3dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 724,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define 3D V-momentum component.
!
        IF (Qout(idVvel,ng)) THEN
          Vinfo( 1)=Vname(1,idVvel)
          Vinfo( 2)=Vname(2,idVvel)
          Vinfo( 3)=Vname(3,idVvel)
          Vinfo(14)=Vname(4,idVvel)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idVvel,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idVvel),   &
     &                   NF_FOUT, nvd4, v3dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 743,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define model surface U-momentum component.
!
        IF (Qout(idUsur,ng)) THEN
          Vinfo( 1)=Vname(1,idUsur)
          Vinfo( 2)=Vname(2,idUsur)
          Vinfo( 3)=Vname(3,idUsur)
          Vinfo(14)=Vname(4,idUsur)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idUsur,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idUsur),   &
     &                   NF_FOUT, nvd3, u2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 762,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define model surface V-momentum component.
!
        IF (Qout(idVsur,ng)) THEN
          Vinfo( 1)=Vname(1,idVsur)
          Vinfo( 2)=Vname(2,idVsur)
          Vinfo( 3)=Vname(3,idVsur)
          Vinfo(14)=Vname(4,idVsur)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idVsur,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idVsur),   &
     &                   NF_FOUT, nvd3, v2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 781,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define 3D Eastward momentum component at RHO-points.
!
        IF (Qout(idu3dE,ng)) THEN
          Vinfo( 1)=Vname(1,idu3dE)
          Vinfo( 2)=Vname(2,idu3dE)
          Vinfo( 3)=Vname(3,idu3dE)
          Vinfo(14)=Vname(4,idu3dE)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(21)='eastward_sea_water_velocity'
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idu3dE,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idu3dE),   &
     &                   NF_FOUT, nvd4, t3dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 801,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define 3D Northward momentum component at RHO-points.
!
        IF (Qout(idv3dN,ng)) THEN
          Vinfo( 1)=Vname(1,idv3dN)
          Vinfo( 2)=Vname(2,idv3dN)
          Vinfo( 3)=Vname(3,idv3dN)
          Vinfo(14)=Vname(4,idv3dN)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(21)='northward_sea_water_velocity'
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idv3dN,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idv3dN),   &
     &                   NF_FOUT, nvd4, t3dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 821,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define model surface Eastward momentum component at RHO-points.
!
        IF (Qout(idUsuE,ng)) THEN
          Vinfo( 1)=Vname(1,idUsuE)
          Vinfo( 2)=Vname(2,idUsuE)
          Vinfo( 3)=Vname(3,idUsuE)
          Vinfo(14)=Vname(4,idUsuE)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(21)='surface_eastward_sea_water_velocity'
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idUsuE,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idUsuE),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 841,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define model surface Northward momentum component at RHO-points.
!
        IF (Qout(idVsuN,ng)) THEN
          Vinfo( 1)=Vname(1,idVsuN)
          Vinfo( 2)=Vname(2,idVsuN)
          Vinfo( 3)=Vname(3,idVsuN)
          Vinfo(14)=Vname(4,idVsuN)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(21)='surface_northward_sea_water_velocity'
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idVsuN,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idVsuN),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 861,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define 3D momentum component in the S-direction.
!
        IF (Qout(idWvel,ng)) THEN
          Vinfo( 1)=Vname(1,idWvel)
          Vinfo( 2)=Vname(2,idWvel)
          Vinfo( 3)=Vname(3,idWvel)
          Vinfo(14)=Vname(4,idWvel)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(21)='upward_sea_water_velocity'
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idWvel,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idWvel),   &
     &                   NF_FOUT, nvd4, w3dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 881,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define S-coordinate vertical "omega" momentum component.
!
        IF (Qout(idOvel,ng)) THEN
          Vinfo( 1)=Vname(1,idOvel)
          Vinfo( 2)=Vname(2,idOvel)
          Vinfo( 3)='meter second-1'
          Vinfo(14)=Vname(4,idOvel)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idOvel,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idOvel),   &
     &                   NF_FOUT, nvd4, w3dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 900,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define tracer type variables.
!
        DO itrc=1,NT(ng)
          IF (Qout(idTvar(itrc),ng)) THEN
            Vinfo( 1)=Vname(1,idTvar(itrc))
            Vinfo( 2)=Vname(2,idTvar(itrc))
            Vinfo( 3)=Vname(3,idTvar(itrc))
            Vinfo(14)=Vname(4,idTvar(itrc))
            Vinfo(16)=Vname(1,idtime)
            DO i=1,NST
              IF (itrc.eq.idsed(i)) THEN
                WRITE (Vinfo(19),50) 1000.0_r8*Sd50(i,ng)
              END IF
            END DO
            Vinfo(22)='coordinates'
            Aval(5)=REAL(r3dvar,r8)
            status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Tid(itrc),   &
     &                     NF_FOUT, nvd4, t3dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 927,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
          END IF
        END DO
!
!  Define surface tracer type variables.
!
        DO itrc=1,NT(ng)
          IF (Qout(idsurT(itrc),ng)) THEN
            Vinfo( 1)=Vname(1,idsurT(itrc))
            Vinfo( 2)=Vname(2,idsurT(itrc))
            Vinfo( 3)=Vname(3,idsurT(itrc))
            Vinfo(14)=Vname(4,idsurT(itrc))
            Vinfo(16)=Vname(1,idtime)
            DO i=1,NST
              IF (itrc.eq.idsed(i)) THEN
                WRITE (Vinfo(19),50) 1000.0_r8*Sd50(i,ng)
              END IF
            END DO
            Vinfo(22)='coordinates'
            Aval(5)=REAL(r2dvar,r8)
            status=def_var(ng, iNLM, QCK(ng)%ncid,                      &
     &                     QCK(ng)%Vid(idsurT(itrc)),                   &
     &                     NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 956,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
          END IF
        END DO
!
!  Define density anomaly.
!
        IF (Qout(idDano,ng)) THEN
          Vinfo( 1)=Vname(1,idDano)
          Vinfo( 2)=Vname(2,idDano)
          Vinfo( 3)=Vname(3,idDano)
          Vinfo(14)=Vname(4,idDano)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idDano,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idDano),   &
     &                   NF_FOUT, nvd4, t3dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 976,                       &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define vertical viscosity coefficient.
!
        IF (Qout(idVvis,ng)) THEN
          Vinfo( 1)=Vname(1,idVvis)
          Vinfo( 2)=Vname(2,idVvis)
          Vinfo( 3)=Vname(3,idVvis)
          Vinfo(14)=Vname(4,idVvis)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idVvis,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idVvis),   &
     &                   NF_FOUT, nvd4, w3dgrd, Aval, Vinfo, ncname,    &
     &                   SetFillVal = .FALSE.)
          IF (FoundError(exit_flag, NoError, 1038,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define vertical diffusion coefficient for potential temperature.
!
        IF (Qout(idTdif,ng)) THEN
          Vinfo( 1)=Vname(1,idTdif)
          Vinfo( 2)=Vname(2,idTdif)
          Vinfo( 3)=Vname(3,idTdif)
          Vinfo(14)=Vname(4,idTdif)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idTdif,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idTdif),   &
     &                   NF_FOUT, nvd4, w3dgrd, Aval, Vinfo, ncname,    &
     &                   SetFillVal = .FALSE.)
          IF (FoundError(exit_flag, NoError, 1058,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define vertical diffusion coefficient for salinity.
!
        IF (Qout(idSdif,ng)) THEN
          Vinfo( 1)=Vname(1,idSdif)
          Vinfo( 2)=Vname(2,idSdif)
          Vinfo( 3)=Vname(3,idSdif)
          Vinfo(14)=Vname(4,idSdif)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idSdif,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idSdif),   &
     &                   NF_FOUT, nvd4, w3dgrd, Aval, Vinfo, ncname,    &
     &                   SetFillVal = .FALSE.)
          IF (FoundError(exit_flag, NoError, 1079,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define turbulent kinetic energy.
!
        IF (Qout(idMtke,ng)) THEN
          Vinfo( 1)=Vname(1,idMtke)
          Vinfo( 2)=Vname(2,idMtke)
          Vinfo( 3)=Vname(3,idMtke)
          Vinfo(14)=Vname(4,idMtke)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idMtke,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idMtke),   &
     &                   NF_FOUT, nvd4, w3dgrd, Aval, Vinfo, ncname,    &
     &                   SetFillVal = .FALSE.)
          IF (FoundError(exit_flag, NoError, 1101,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define turbulent kinetic energy time length scale.
!
        IF (Qout(idMtls,ng)) THEN
          Vinfo( 1)=Vname(1,idMtls)
          Vinfo( 2)=Vname(2,idMtls)
          Vinfo( 3)=Vname(3,idMtls)
          Vinfo(14)=Vname(4,idMtls)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idMtls,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idMtls),   &
     &                   NF_FOUT, nvd4, w3dgrd, Aval, Vinfo, ncname,    &
     &                   SetFillVal = .FALSE.)
          IF (FoundError(exit_flag, NoError, 1121,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define surface active tracer fluxes.
!
        DO itrc=1,NAT
          IF (Qout(idTsur(itrc),ng)) THEN
            Vinfo( 1)=Vname(1,idTsur(itrc))
            Vinfo( 2)=Vname(2,idTsur(itrc))
            Vinfo( 3)=Vname(3,idTsur(itrc))
            IF (itrc.eq.itemp) THEN
              Vinfo(11)='upward flux, cooling'
              Vinfo(12)='downward flux, heating'
            ELSE IF (itrc.eq.isalt) THEN
              Vinfo(11)='upward flux, freshening (net precipitation)'
              Vinfo(12)='downward flux, salting (net evaporation)'
            END IF
            Vinfo(14)=Vname(4,idTsur(itrc))
            Vinfo(16)=Vname(1,idtime)
            Vinfo(22)='coordinates'
            Aval(5)=REAL(Iinfo(1,idTsur(itrc),ng),r8)
            status=def_var(ng, iNLM, QCK(ng)%ncid,                      &
     &                     QCK(ng)%Vid(idTsur(itrc)), NF_FOUT,          &
     &                     nvd3, t2dgrd, Aval, Vinfo, ncname)
            IF (FoundError(exit_flag, NoError, 1209,                    &
     &                     "ROMS/Utility/def_quick.F")) RETURN
          END IF
        END DO
!
!  Define surface U-momentum stress.
!
        IF (Qout(idUsms,ng)) THEN
          Vinfo( 1)=Vname(1,idUsms)
          Vinfo( 2)=Vname(2,idUsms)
          Vinfo( 3)=Vname(3,idUsms)
          Vinfo(14)=Vname(4,idUsms)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idUsms,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idUsms),   &
     &                   NF_FOUT, nvd3, u2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1403,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define surface V-momentum stress.
!
        IF (Qout(idVsms,ng)) THEN
          Vinfo( 1)=Vname(1,idVsms)
          Vinfo( 2)=Vname(2,idVsms)
          Vinfo( 3)=Vname(3,idVsms)
          Vinfo(14)=Vname(4,idVsms)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idVsms,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idVsms),   &
     &                   NF_FOUT, nvd3, v2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1422,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define bottom U-momentum stress.
!
        IF (Qout(idUbms,ng)) THEN
          Vinfo( 1)=Vname(1,idUbms)
          Vinfo( 2)=Vname(2,idUbms)
          Vinfo( 3)=Vname(3,idUbms)
          Vinfo(14)=Vname(4,idUbms)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idUbms,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idUbms),   &
     &                   NF_FOUT, nvd3, u2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1441,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define bottom V-momentum stress.
!
        IF (Qout(idVbms,ng)) THEN
          Vinfo( 1)=Vname(1,idVbms)
          Vinfo( 2)=Vname(2,idVbms)
          Vinfo( 3)=Vname(3,idVbms)
          Vinfo(14)=Vname(4,idVbms)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idVbms,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idVbms),   &
     &                   NF_FOUT, nvd3, v2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1460,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define bottom U-current stress.
!
        IF (Qout(idUbrs,ng)) THEN
          Vinfo( 1)=Vname(1,idUbrs)
          Vinfo( 2)=Vname(2,idUbrs)
          Vinfo( 3)=Vname(3,idUbrs)
          Vinfo(14)=Vname(4,idUbrs)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idUbrs,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idUbrs),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1481,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define bottom V-current stress.
!
        IF (Qout(idVbrs,ng)) THEN
          Vinfo( 1)=Vname(1,idVbrs)
          Vinfo( 2)=Vname(2,idVbrs)
          Vinfo( 3)=Vname(3,idVbrs)
          Vinfo(14)=Vname(4,idVbrs)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idVbrs,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idVbrs),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1500,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define wind-induced, bottom U-wave stress.
!
        IF (Qout(idUbws,ng)) THEN
          Vinfo( 1)=Vname(1,idUbws)
          Vinfo( 2)=Vname(2,idUbws)
          Vinfo( 3)=Vname(3,idUbws)
          Vinfo(14)=Vname(4,idUbws)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idUbws,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idUbws),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1519,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define bottom wind-induced, bottom V-wave stress.
!
        IF (Qout(idVbws,ng)) THEN
          Vinfo( 1)=Vname(1,idVbws)
          Vinfo( 2)=Vname(2,idVbws)
          Vinfo( 3)=Vname(3,idVbws)
          Vinfo(14)=Vname(4,idVbws)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idVbws,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idVbws),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1538,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define maximum wind and current, bottom U-wave stress.
!
        IF (Qout(idUbcs,ng)) THEN
          Vinfo( 1)=Vname(1,idUbcs)
          Vinfo( 2)=Vname(2,idUbcs)
          Vinfo( 3)=Vname(3,idUbcs)
          Vinfo(14)=Vname(4,idUbcs)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idUbcs,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idUbcs),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1557,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define maximum wind and current, bottom V-wave stress.
!
        IF (Qout(idVbcs,ng)) THEN
          Vinfo( 1)=Vname(1,idVbcs)
          Vinfo( 2)=Vname(2,idVbcs)
          Vinfo( 3)=Vname(3,idVbcs)
          Vinfo(14)=Vname(4,idVbcs)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idVbcs,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idVbcs),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1576,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define wind-induced, bed wave orbital U-velocity.
!
        IF (Qout(idUbot,ng)) THEN
          Vinfo( 1)=Vname(1,idUbot)
          Vinfo( 2)=Vname(2,idUbot)
          Vinfo( 3)=Vname(3,idUbot)
          Vinfo(14)=Vname(4,idUbot)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idUbot,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idUbot),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1595,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define wind-induced, bed wave orbital V-velocity.
!
        IF (Qout(idVbot,ng)) THEN
          Vinfo( 1)=Vname(1,idVbot)
          Vinfo( 2)=Vname(2,idVbot)
          Vinfo( 3)=Vname(3,idVbot)
          Vinfo(14)=Vname(4,idVbot)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idVbot,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idVbot),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1614,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define bottom U-momentum above bed.
!
        IF (Qout(idUbur,ng)) THEN
          Vinfo( 1)=Vname(1,idUbur)
          Vinfo( 2)=Vname(2,idUbur)
          Vinfo( 3)=Vname(3,idUbur)
          Vinfo(14)=Vname(4,idUbur)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idUbur,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idUbur),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1633,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define bottom V-momentum above bed.
!
        IF (Qout(idVbvr,ng)) THEN
          Vinfo( 1)=Vname(1,idVbvr)
          Vinfo( 2)=Vname(2,idVbvr)
          Vinfo( 3)=Vname(3,idVbvr)
          Vinfo(14)=Vname(4,idVbvr)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idVbvr,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idVbvr),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 1652,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define sediment fraction of each size class in each bed layer.
!
        DO i=1,NST
          IF (Qout(idfrac(i),ng)) THEN
            Vinfo( 1)=Vname(1,idfrac(i))
            Vinfo( 2)=Vname(2,idfrac(i))
            Vinfo( 3)=Vname(3,idfrac(i))
            Vinfo(14)=Vname(4,idfrac(i))
            Vinfo(16)=Vname(1,idtime)
            WRITE (Vinfo(19),50) 1000.0_r8*Sd50(i,ng)
            Vinfo(22)='coordinates'
            Aval(5)=REAL(Iinfo(1,idfrac(i),ng))
            status=def_var(ng, iNLM, QCK(ng)%ncid,                      &
     &                     QCK(ng)%Vid(idfrac(i)), NF_FOUT,             &
     &                     nvd4, b3dgrd, Aval, Vinfo, ncname)
            IF (FoundError(exit_flag, NoError, 1720,                    &
     &                     "ROMS/Utility/def_quick.F")) RETURN
          END IF
        END DO
!
!  Define sediment mass of each size class in each bed layer.
!
        DO i=1,NST
          IF (Qout(idBmas(i),ng)) THEN
            Vinfo( 1)=Vname(1,idBmas(i))
            Vinfo( 2)=Vname(2,idBmas(i))
            Vinfo( 3)=Vname(3,idBmas(i))
            Vinfo(14)=Vname(4,idBmas(i))
            Vinfo(16)=Vname(1,idtime)
            WRITE (Vinfo(19),50) 1000.0_r8*Sd50(i,ng)
            Vinfo(22)='coordinates'
            Aval(5)=REAL(Iinfo(1,idBmas(i),ng),r8)
            status=def_var(ng, iNLM, QCK(ng)%ncid,                      &
     &                     QCK(ng)%Vid(idBmas(i)), NF_FOUT,             &
     &                     nvd4, b3dgrd, Aval, Vinfo, ncname)
            IF (FoundError(exit_flag, NoError, 1743,                    &
     &                     "ROMS/Utility/def_quick.F")) RETURN
          END IF
        END DO
!
!  Define sediment properties in each bed layer.
!
        DO i=1,MBEDP
          IF (Qout(idSbed(i),ng)) THEN
            Vinfo( 1)=Vname(1,idSbed(i))
            Vinfo( 2)=Vname(2,idSbed(i))
            Vinfo( 3)=Vname(3,idSbed(i))
            Vinfo(14)=Vname(4,idSbed(i))
            Vinfo(16)=Vname(1,idtime)
            Vinfo(22)='coordinates'
            Aval(5)=REAL(Iinfo(1,idSbed(i),ng),r8)
            status=def_var(ng, iNLM, QCK(ng)%ncid,                      &
     &                     QCK(ng)%Vid(idSbed(i)), NF_FOUT,             &
     &                     nvd4, b3dgrd, Aval, Vinfo, ncname)
            IF (FoundError(exit_flag, NoError, 1765,                    &
     &                     "ROMS/Utility/def_quick.F")) RETURN
          END IF
        END DO
!
!  Define exposed sediment layer properties.
!
        DO i=1,MBOTP
          IF (Qout(idBott(i),ng)) THEN
            Vinfo( 1)=Vname(1,idBott(i))
            Vinfo( 2)=Vname(2,idBott(i))
            Vinfo( 3)=Vname(3,idBott(i))
            Vinfo(14)=Vname(4,idBott(i))
            Vinfo(16)=Vname(1,idtime)
            Vinfo(22)='coordinates'
            Aval(5)=REAL(r2dvar,r8)
            status=def_var(ng, iNLM, QCK(ng)%ncid,                      &
     &                     QCK(ng)%Vid(idBott(i)), NF_FOUT,             &
     &                     nvd3, t2dgrd, Aval, Vinfo, ncname)
            IF (FoundError(exit_flag, NoError, 1789,                    &
     &                     "ROMS/Utility/def_quick.F")) RETURN
          END IF
        END DO
!
!  Define wind-induced significat wave height.
!
        IF (Qout(idWamp,ng)) THEN
          Vinfo( 1)=Vname(1,idWamp)
          Vinfo( 2)=Vname(2,idWamp)
          Vinfo( 3)=Vname(3,idWamp)
          Vinfo(14)=Vname(4,idWamp)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idWamp,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idWamp),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 2124,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define wind-induced mean wavelength.
!
        IF (Qout(idWlen,ng)) THEN
          Vinfo( 1)=Vname(1,idWlen)
          Vinfo( 2)=Vname(2,idWlen)
          Vinfo( 3)=Vname(3,idWlen)
          Vinfo(14)=Vname(4,idWlen)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idWlen,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idWlen),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 2145,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define wind-induced wave direction.
!
        IF (Qout(idWdir,ng)) THEN
          Vinfo( 1)=Vname(1,idWdir)
          Vinfo( 2)=Vname(2,idWdir)
          Vinfo( 3)=Vname(3,idWdir)
          Vinfo(14)=Vname(4,idWdir)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idWdir,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idWdir),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 2166,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!  Define wind-induced bottom wave period.
!
        IF (Qout(idWpbt,ng)) THEN
          Vinfo( 1)=Vname(1,idWpbt)
          Vinfo( 2)=Vname(2,idWpbt)
          Vinfo( 3)=Vname(3,idWpbt)
          Vinfo(14)=Vname(4,idWpbt)
          Vinfo(16)=Vname(1,idtime)
          Vinfo(22)='coordinates'
          Aval(5)=REAL(Iinfo(1,idWpbt,ng),r8)
          status=def_var(ng, iNLM, QCK(ng)%ncid, QCK(ng)%Vid(idWpbt),   &
     &                   NF_FOUT, nvd3, t2dgrd, Aval, Vinfo, ncname)
          IF (FoundError(exit_flag, NoError, 2209,                      &
     &                   "ROMS/Utility/def_quick.F")) RETURN
        END IF
!
!-----------------------------------------------------------------------
!  Leave definition mode.
!-----------------------------------------------------------------------
!
        CALL netcdf_enddef (ng, iNLM, ncname, QCK(ng)%ncid)
        IF (FoundError(exit_flag, NoError, 2262,                        &
     &                 "ROMS/Utility/def_quick.F")) RETURN
!
!-----------------------------------------------------------------------
!  Write out time-recordless, information variables.
!-----------------------------------------------------------------------
!
        CALL wrt_info (ng, iNLM, QCK(ng)%ncid, ncname)
        IF (FoundError(exit_flag, NoError, 2270,                        &
     &                 "ROMS/Utility/def_quick.F")) RETURN
      END IF DEFINE
!
!=======================================================================
!  Open an existing quicksave file, check its contents, and prepare
!  for appending data.
!=======================================================================
!
      QUERY : IF (.not.ldef) THEN
        ncname=QCK(ng)%name
!
!  Open quicksave file for read/write.
!
        CALL netcdf_open (ng, iNLM, ncname, 1, QCK(ng)%ncid)
        IF (FoundError(exit_flag, NoError, 2285,                        &
     &                 "ROMS/Utility/def_quick.F")) THEN
          WRITE (stdout,60) TRIM(ncname)
          RETURN
        END IF
!
!  Inquire about the dimensions and check for consistency.
!
        CALL netcdf_check_dim (ng, iNLM, ncname,                        &
     &                         ncid = QCK(ng)%ncid)
        IF (FoundError(exit_flag, NoError, 2295,                        &
     &                 "ROMS/Utility/def_quick.F")) RETURN
!
!  Inquire about the variables.
!
        CALL netcdf_inq_var (ng, iNLM, ncname,                          &
     &                       ncid = QCK(ng)%ncid)
        IF (FoundError(exit_flag, NoError, 2302,                        &
     &                 "ROMS/Utility/def_quick.F")) RETURN
!
!  Initialize logical switches.
!
        DO i=1,NV
          got_var(i)=.FALSE.
        END DO
!
!  Scan variable list from input NetCDF and activate switches for
!  quicksave variables. Get variable IDs.
!
        DO i=1,n_var
          IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idtime))) THEN
            got_var(idtime)=.TRUE.
            QCK(ng)%Vid(idtime)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idpthR))) THEN
            got_var(idpthR)=.TRUE.
            QCK(ng)%Vid(idpthR)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idpthU))) THEN
            got_var(idpthU)=.TRUE.
            QCK(ng)%Vid(idpthU)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idpthV))) THEN
            got_var(idpthV)=.TRUE.
            QCK(ng)%Vid(idpthV)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idpthW))) THEN
            got_var(idpthW)=.TRUE.
            QCK(ng)%Vid(idpthW)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idFsur))) THEN
            got_var(idFsur)=.TRUE.
            QCK(ng)%Vid(idFsur)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idUbar))) THEN
            got_var(idUbar)=.TRUE.
            QCK(ng)%Vid(idUbar)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idVbar))) THEN
            got_var(idVbar)=.TRUE.
            QCK(ng)%Vid(idVbar)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idu2dE))) THEN
            got_var(idu2dE)=.TRUE.
            QCK(ng)%Vid(idu2dE)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idv2dN))) THEN
            got_var(idv2dN)=.TRUE.
            QCK(ng)%Vid(idv2dN)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idUvel))) THEN
            got_var(idUvel)=.TRUE.
            QCK(ng)%Vid(idUvel)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idVvel))) THEN
            got_var(idVvel)=.TRUE.
            QCK(ng)%Vid(idVvel)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idUsur))) THEN
            got_var(idUsur)=.TRUE.
            QCK(ng)%Vid(idUsur)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idVsur))) THEN
            got_var(idVsur)=.TRUE.
            QCK(ng)%Vid(idVsur)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idu3dE))) THEN
            got_var(idu3dE)=.TRUE.
            QCK(ng)%Vid(idu3dE)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idv3dN))) THEN
            got_var(idv3dN)=.TRUE.
            QCK(ng)%Vid(idv3dN)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idUsuE))) THEN
            got_var(idUsuE)=.TRUE.
            QCK(ng)%Vid(idUsuE)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idVsuN))) THEN
            got_var(idVsuN)=.TRUE.
            QCK(ng)%Vid(idVsuN)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idWvel))) THEN
            got_var(idWvel)=.TRUE.
            QCK(ng)%Vid(idWvel)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idOvel))) THEN
            got_var(idOvel)=.TRUE.
            QCK(ng)%Vid(idOvel)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idDano))) THEN
            got_var(idDano)=.TRUE.
            QCK(ng)%Vid(idDano)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idVvis))) THEN
            got_var(idVvis)=.TRUE.
            QCK(ng)%Vid(idVvis)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idTdif))) THEN
            got_var(idTdif)=.TRUE.
            QCK(ng)%Vid(idTdif)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idSdif))) THEN
            got_var(idSdif)=.TRUE.
            QCK(ng)%Vid(idSdif)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idMtke))) THEN
            got_var(idMtke)=.TRUE.
            QCK(ng)%Vid(idMtke)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idMtls))) THEN
            got_var(idMtls)=.TRUE.
            QCK(ng)%Vid(idMtls)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idUsms))) THEN
            got_var(idUsms)=.TRUE.
            QCK(ng)%Vid(idUsms)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idVsms))) THEN
            got_var(idVsms)=.TRUE.
            QCK(ng)%Vid(idVsms)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idUbms))) THEN
            got_var(idUbms)=.TRUE.
            QCK(ng)%Vid(idUbms)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idVbms))) THEN
            got_var(idVbms)=.TRUE.
            QCK(ng)%Vid(idVbms)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idUbrs))) THEN
            got_var(idUbrs)=.TRUE.
            QCK(ng)%Vid(idUbrs)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idVbrs))) THEN
            got_var(idVbrs)=.TRUE.
            QCK(ng)%Vid(idVbrs)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idUbws))) THEN
            got_var(idUbws)=.TRUE.
            QCK(ng)%Vid(idUbws)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idVbws))) THEN
            got_var(idVbws)=.TRUE.
            QCK(ng)%Vid(idVbws)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idUbcs))) THEN
            got_var(idUbcs)=.TRUE.
            QCK(ng)%Vid(idUbcs)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idVbcs))) THEN
            got_var(idVbcs)=.TRUE.
            QCK(ng)%Vid(idVbcs)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idUbot))) THEN
            got_var(idUbot)=.TRUE.
            QCK(ng)%Vid(idUbot)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idVbot))) THEN
            got_var(idVbot)=.TRUE.
            QCK(ng)%Vid(idVbot)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idUbur))) THEN
            got_var(idUbur)=.TRUE.
            QCK(ng)%Vid(idUbur)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idVbvr))) THEN
            got_var(idVbvr)=.TRUE.
            QCK(ng)%Vid(idVbvr)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idWamp))) THEN
            got_var(idWamp)=.TRUE.
            QCK(ng)%Vid(idWamp)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idWlen))) THEN
            got_var(idWlen)=.TRUE.
            QCK(ng)%Vid(idWlen)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idWdir))) THEN
            got_var(idWdir)=.TRUE.
            QCK(ng)%Vid(idWdir)=var_id(i)
          ELSE IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idWpbt))) THEN
            got_var(idWpbt)=.TRUE.
            QCK(ng)%Vid(idWpbt)=var_id(i)
          END IF
          DO itrc=1,NT(ng)
            IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idTvar(itrc)))) THEN
              got_var(idTvar(itrc))=.TRUE.
              QCK(ng)%Tid(itrc)=var_id(i)
            ELSE IF (TRIM(var_name(i)).eq.                              &
     &               TRIM(Vname(1,idsurT(itrc)))) THEN
              got_var(idsurT(itrc))=.TRUE.
              QCK(ng)%Vid(idsurT(itrc))=var_id(i)
            END IF
          END DO
          DO itrc=1,NAT
            IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idTsur(itrc)))) THEN
              got_var(idTsur(itrc))=.TRUE.
              QCK(ng)%Vid(idTsur(itrc))=var_id(i)
            END IF
          END DO
          DO itrc=1,NST
            IF (TRIM(var_name(i)).eq.                                   &
     &               TRIM(Vname(1,idfrac(itrc)))) THEN
              got_var(idfrac(itrc))=.TRUE.
              QCK(ng)%Vid(idfrac(itrc))=var_id(i)
            ELSE IF (TRIM(var_name(i)).eq.                              &
     &               TRIM(Vname(1,idBmas(itrc)))) THEN
              got_var(idBmas(itrc))=.TRUE.
              QCK(ng)%Vid(idBmas(itrc))=var_id(i)
            END IF
          END DO
          DO itrc=1,MBEDP
            IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idSbed(itrc)))) THEN
              got_var(idSbed(itrc))=.TRUE.
              QCK(ng)%Vid(idSbed(itrc))=var_id(i)
            END IF
          END DO
          DO itrc=1,MBOTP
            IF (TRIM(var_name(i)).eq.TRIM(Vname(1,idBott(itrc)))) THEN
              got_var(idBott(itrc))=.TRUE.
              QCK(ng)%Vid(idBott(itrc))=var_id(i)
            END IF
          END DO
        END DO
!
!  Check if quicksave variables are available in input NetCDF
!  file.
!
        IF (.not.got_var(idtime)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idtime)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idpthR).and.Qout(idpthR,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idpthR)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idpthU).and.Qout(idpthU,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idpthU)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idpthV).and.Qout(idpthV,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idpthV)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idpthW).and.Qout(idpthW,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idpthW)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idFsur).and.Qout(idFsur,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idFsur)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idUbar).and.Qout(idUbar,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idUbar)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idVbar).and.Qout(idVbar,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idVbar)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idu2dE).and.Qout(idu2dE,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idu2dE)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idv2dN).and.Qout(idv2dN,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idv2dN)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idUvel).and.Qout(idUvel,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idUvel)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idVvel).and.Qout(idVvel,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idVvel)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idUsur).and.Qout(idUsur,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idUsur)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idVsur).and.Qout(idVsur,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idVsur)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idu3dE).and.Qout(idu3dE,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idu3dE)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idv3dN).and.Qout(idv3dN,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idv3dN)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idUsuE).and.Qout(idUsuE,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idUsuE)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idVsuN).and.Qout(idVsuN,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idVsuN)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idWvel).and.Qout(idWvel,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idWvel)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idOvel).and.Qout(idOvel,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idOvel)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idDano).and.Qout(idDano,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idDano)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idVvis).and.Qout(idVvis,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idVvis)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idTdif).and.Qout(idTdif,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idTdif)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idSdif).and.Qout(idSdif,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idSdif)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idMtke).and.Qout(idMtke,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idMtke)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idMtls).and.Qout(idMtls,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idMtls)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idUsms).and.Qout(idUsms,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idUsms)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idVsms).and.Qout(idVsms,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idVsms)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idUbms).and.Qout(idUbms,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idUbms)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idVbms).and.Qout(idVbms,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idVbms)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idUbrs).and.Qout(idUbrs,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idUbrs)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idVbrs).and.Qout(idVbrs,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idVbrs)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idUbws).and.Qout(idUbws,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idUbws)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idVbws).and.Qout(idVbws,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idVbws)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idUbcs).and.Qout(idUbcs,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idUbcs)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idVbcs).and.Qout(idVbcs,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idVbcs)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idUbot).and.Qout(idUbot,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idUbot)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idVbot).and.Qout(idVbot,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idVbot)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idUbur).and.Qout(idUbur,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idUbur)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idVbvr).and.Qout(idVbvr,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idVbvr)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idWamp).and.Qout(idWamp,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idWamp)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idWlen).and.Qout(idWlen,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idWlen)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idWdir).and.Qout(idWdir,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idWdir)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        IF (.not.got_var(idWpbt).and.Qout(idWpbt,ng)) THEN
          IF (Master) WRITE (stdout,70) TRIM(Vname(1,idWpbt)),          &
     &                                  TRIM(ncname)
          exit_flag=3
          RETURN
        END IF
        DO itrc=1,NT(ng)
          IF (.not.got_var(idTvar(itrc)).and.Qout(idTvar(itrc),ng)) THEN
            IF (Master) WRITE (stdout,70) TRIM(Vname(1,idTvar(itrc))),  &
     &                                    TRIM(ncname)
            exit_flag=3
            RETURN
          END IF
          IF (.not.got_var(idsurT(itrc)).and.Qout(idsurT(itrc),ng)) THEN
            IF (Master) WRITE (stdout,70) TRIM(Vname(1,idsurT(itrc))),  &
     &                                    TRIM(ncname)
            exit_flag=3
            RETURN
          END IF
        END DO
        DO itrc=1,NAT
          IF (.not.got_var(idTsur(itrc)).and.Qout(idTsur(itrc),ng)) THEN
            IF (Master) WRITE (stdout,70) TRIM(Vname(1,idTsur(itrc))),  &
     &                                    TRIM(ncname)
            exit_flag=3
            RETURN
          END IF
        END DO
        DO i=1,NST
          IF (.not.got_var(idfrac(i)).and.Qout(idfrac(i),ng)) THEN
            IF (Master) WRITE (stdout,70) TRIM(Vname(1,idfrac(i))),     &
     &                                    TRIM(ncname)
            exit_flag=3
            RETURN
          END IF
          IF(.not.got_var(idBmas(i)).and.Qout(idBmas(i),ng)) THEN
            IF (Master) WRITE (stdout,70) TRIM(Vname(1,idBmas(i))),     &
     &                                    TRIM(ncname)
            exit_flag=3
            RETURN
          END IF
        END DO
        DO i=1,MBEDP
          IF (.not.got_var(idSbed(i)).and.Qout(idSbed(i),ng)) THEN
            IF (Master) WRITE (stdout,70) TRIM(Vname(1,idSbed(i))),     &
     &                                    TRIM(ncname)
            exit_flag=3
            RETURN
          END IF
        END DO
        DO i=1,MBOTP
          IF (.not.got_var(idBott(i)).and.Qout(idBott(i),ng)) THEN
            IF (Master) WRITE (stdout,70) TRIM(Vname(1,idBott(i))),     &
     &                                    TRIM(ncname)
            exit_flag=3
            RETURN
          END IF
        END DO
!
!  Set unlimited time record dimension to the appropriate value.
!
        IF (ndefQCK(ng).gt.0) THEN
          QCK(ng)%Rindex=((ntstart(ng)-1)-                              &
     &                    ndefQCK(ng)*((ntstart(ng)-1)/ndefQCK(ng)))/   &
     &                   nQCK(ng)
        ELSE
          QCK(ng)%Rindex=(ntstart(ng)-1)/nQCK(ng)
        END IF
        QCK(ng)%Rindex=MIN(QCK(ng)%Rindex,rec_size)
      END IF QUERY
!
  10  FORMAT (6x,'DEF_QUICK   - creating  quicksave', t43,              &
     &        ' file, Grid ',i2.2,': ', a)
  20  FORMAT (6x,'DEF_QUICK   - inquiring quicksave', t43,              &
     &        ' file, Grid ',i2.2,': ', a)
  30  FORMAT (/,' DEF_QUICK - unable to create quicksave NetCDF file:', &
     &        1x,a)
  40  FORMAT ('time dependent',1x,a)
  50  FORMAT (1pe11.4,1x,'millimeter')
  60  FORMAT (/,' DEF_QUICK - unable to open quicksave NetCDF file: ',a)
  70  FORMAT (/,' DEF_QUICK - unable to find variable: ',a,2x,          &
     &        ' in quicksave NetCDF file: ',a)
      RETURN
      END SUBROUTINE def_quick
