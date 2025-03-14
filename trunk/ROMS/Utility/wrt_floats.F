#include "cppdefs.h"
#ifdef FLOATS
      SUBROUTINE wrt_floats (ng)
!
!svn $Id: wrt_floats.F 857 2017-07-29 04:05:27Z arango $
!================================================== Hernan G. Arango ===
!  Copyright (c) 2002-2018 The ROMS/TOMS Group                         !
!    Licensed under a MIT/X style license                              !
!    See License_ROMS.txt                                              !
!=======================================================================
!                                                                      !
!  This subroutine writes simulated drifter trajectories into floats   !
!  NetCDF file.                                                        !
!                                                                      !
!=======================================================================
!
      USE mod_param
      USE mod_parallel
      USE mod_floats
      USE mod_iounits
      USE mod_ncparam
      USE mod_netcdf
      USE mod_scalars
      USE mod_stepping
!
      USE strings_mod, ONLY : FoundError
!
      implicit none
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng
!
!  Local variable declarations.
!
      integer :: Fcount, itrc, l, status

      real(r8), dimension(Nfloats(ng)) :: Tout
! DDMITRY
! I found that saved i,j indices of the Lagrangian
! floats in the netcdf do not match LON/LAT arrays
! but shifted by -1 index in both directions
! I think the reason could be due to different "inner" and external
! dimensions of RHO points
! Also note that RHO-centered arrays are shifted by +1 dimension
! during the netcdf output (see Utility/nf_write3d.f
! To fix this possibly bug, I am adding an offset to the 
! floats' i, j indices
!
      real(r8), dimension(Nfloats(ng),Nocmp) :: Tout2d  ! DDMITRY
      real(r8) :: Ioffset=1.0, Joffset=1.0
! END DD
!
      SourceFile=__FILE__
!
!-----------------------------------------------------------------------
!  Write out station data at RHO-points.
!-----------------------------------------------------------------------
!
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
!
!  Set time record index.
!
      FLT(ng)%Rindex=FLT(ng)%Rindex+1
      Fcount=FLT(ng)%Fcount
      FLT(ng)%Nrec(Fcount)=FLT(ng)%Nrec(Fcount)+1
!
!  Write out model time (s).
!
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      TRIM(Vname(1,idtime)), time(ng:),           &
     &                      (/FLT(ng)%Rindex/), (/1/),                  &
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = FLT(ng)%Vid(idtime))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
!
!  Write out floats X-grid locations.
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
!          Tout(l)=DRIFTER(ng)%track(ixgrd,nf(ng),l)
          Tout(l)=DRIFTER(ng)%track(ixgrd,nf(ng),l)+Ioffset   ! DDMITRY
        ELSE
          Tout(l)=spval
        END IF
      END DO
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      'Xgrid', Tout,                              &
     &                      (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),    &
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = FLT(ng)%Vid(idXgrd))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
!
!  Write out floats Y-grid locations.
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
!          Tout(l)=DRIFTER(ng)%track(iygrd,nf(ng),l)
          Tout(l)=DRIFTER(ng)%track(iygrd,nf(ng),l)+Joffset   ! DDMITRY
        ELSE
          Tout(l)=spval
        END IF
      END DO
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      'Ygrid', Tout,                              &
     &                      (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),    &
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = FLT(ng)%Vid(idYgrd))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN

# ifdef SOLVE3D
!
!  Write out floats Z-grid locations.
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
          Tout(l)=DRIFTER(ng)%track(izgrd,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      'Zgrid', Tout,                              &
     &                      (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),    &
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = FLT(ng)%Vid(idZgrd))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
# endif

# ifdef OFFLINE_FLOATS_LATLON
!
!  Write out floats (lon,lat) and (x,y) locations.
!
    IF (.not.spherical) THEN
        WRITE(stdout,*) 'OFFLINE FLOATS MODULE NEEDS SPHERICAL GRID!'
        exit_flag=2
        RETURN
    END IF
    IF (spherical) THEN
      DO l=1,Nfloats(ng)
        IF (FLT(ng)%bounded(l)) THEN
          Tout(l)=FLT(ng)%track(iflon,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
        CALL netcdf_put_fvar (ng, iNLM, FLTname(ng),                    &
     &                        'lon', Tout,                              &
     &                        (/1,tFLTindx(ng)/), (/Nfloats(ng),1/),    &
     &                        ncid = ncFLTid(ng),                       &
     &                        varid = fltVid(idglon,ng))
      IF (exit_flag.ne.NoError) RETURN

      DO l=1,Nfloats(ng)
        IF (FLT(ng)%bounded(l)) THEN
          Tout(l)=FLT(ng)%track(ixspc,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
        CALL netcdf_put_fvar (ng, iNLM, FLTname(ng),                    &
     &                        'x', Tout,                                &
     &                        (/1,tFLTindx(ng)/), (/Nfloats(ng),1/),    &
     &                        ncid = ncFLTid(ng),                       &
     &                        varid = fltVid(idxspc,ng))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
      DO l=1,Nfloats(ng)
        IF (FLT(ng)%bounded(l)) THEN
          Tout(l)=FLT(ng)%track(iflat,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
        CALL netcdf_put_fvar (ng, iNLM, FLTname(ng),                    &
     &                        'lat', Tout,                              &
     &                        (/1,tFLTindx(ng)/), (/Nfloats(ng),1/),    &
     &                        ncid = ncFLTid(ng),                       &
     &                        varid = fltVid(idglat,ng))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
      DO l=1,Nfloats(ng)
        IF (FLT(ng)%bounded(l)) THEN
          Tout(l)=FLT(ng)%track(iyspc,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
        CALL netcdf_put_fvar (ng, iNLM, FLTname(ng),                    &
     &                        'y', Tout,                                &
     &                        (/1,tFLTindx(ng)/), (/Nfloats(ng),1/),    &
     &                        ncid = ncFLTid(ng),                       &
     &                        varid = fltVid(idyspc,ng))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
     DO l=1,Nfloats(ng)
        IF (FLT(ng)%bounded(l)) THEN
          Tout(l)=FLT(ng)%track(iwdph,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
        CALL netcdf_put_fvar (ng, iNLM, FLTname(ng),                    &
     &                        'wd', Tout,                               &
     &                        (/1,tFLTindx(ng)/), (/Nfloats(ng),1/),    &
     &                        ncid = ncFLTid(ng),                       &
     &                        varid = fltVid(idwdph,ng))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
     END IF
# else
!
!  Write out floats (lon,lat) or (x,y) locations.
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
          Tout(l)=DRIFTER(ng)%track(iflon,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
      IF (spherical) THEN
        CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                   &
     &                        'lon', Tout,                              &
     &                        (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),  &
     &                        ncid = FLT(ng)%ncid,                      &
     &                        varid = FLT(ng)%Vid(idglon))
      ELSE
        CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                   &
     &                        'x', Tout,                                &
     &                        (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),  &
     &                        ncid = FLT(ng)%ncid,                      &
     &                        varid = FLT(ng)%Vid(idglon))
      END IF
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
          Tout(l)=DRIFTER(ng)%track(iflat,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
      IF (spherical) THEN
        CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                   &
     &                        'lat', Tout,                              &
     &                        (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),  &
     &                        ncid = FLT(ng)%ncid,                      &
     &                        varid = FLT(ng)%Vid(idglat))
      ELSE
        CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                   &
     &                        'y', Tout,                                &
     &                        (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),  &
     &                        ncid = FLT(ng)%ncid,                      &
     &                        varid = FLT(ng)%Vid(idglat))
      END IF
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
# endif

# ifdef SOLVE3D
!
!  Write out floats depths.
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
          Tout(l)=DRIFTER(ng)%track(idpth,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      'depth', Tout,                              &
     &                      (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),    &
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = FLT(ng)%Vid(iddpth))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
!
!  Write out density anomaly.
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
          Tout(l)=DRIFTER(ng)%track(ifden,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      TRIM(Vname(1,idDano)), Tout,                &
     &                      (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),    &
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = FLT(ng)%Vid(idDano))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
!
!  Write out tracer type variables.
!
      DO itrc=1,NT(ng)
        DO l=1,Nfloats(ng)
          IF (DRIFTER(ng)%bounded(l)) THEN
#  ifdef OFFLINE_FLOATS
            Tout(l)=DRIFTER(ng)%track(itrc+(NFV(ng)-NT(ng)),nf(ng),l)
#  else
            Tout(l)=DRIFTER(ng)%track(ifTvar(itrc),nf(ng),l)
#  endif
          ELSE
            Tout(l)=spval
          END IF
        END DO
        CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                   &
     &                        TRIM(Vname(1,idTvar(itrc))), Tout,        &
     &                        (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),  &
     &                        ncid = FLT(ng)%ncid,                      &
     &                        varid = FLT(ng)%Tid(itrc))
        IF (FoundError(exit_flag, NoError, __LINE__,                    &
     &                 __FILE__)) RETURN
      END DO

#  ifdef OFFLINE_FLOATS
      IF (Master) print *, '  WRT_FLOATS, model time (days), t=', tdays
#  endif
# endif
# ifdef FLOAT_OIL
! DDMITRY
!
! Write out oil float density
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
          Tout(l)=DRIFTER(ng)%track(iroil,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      'rho_oil', Tout,                            &
     &                      (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),    &
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = FLT(ng)%Vid(idroil))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
!
! Write out oil float size (diameter)
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
          Tout(l)=DRIFTER(ng)%track(isizo,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      'Doil', Tout,                               &
     &                      (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),    &
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = FLT(ng)%Vid(idsizo))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
!
! Write out weight fractions of oil components
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
          Tout2d(l,1)=DRIFTER(ng)%track(isats,nf(ng),l)
          Tout2d(l,2)=DRIFTER(ng)%track(iarom,nf(ng),l)
          Tout2d(l,3)=1.0_r8-(DRIFTER(ng)%track(isats,nf(ng),l)+        &
     &                        DRIFTER(ng)%track(iarom,nf(ng),l))
        ELSE
          Tout2d(l,:)=spval
        END IF
      END DO
      IF (Master) THEN
        print*,'WRITING NetCDF wght_fract ',trim(FLT(ng)%name)
        print*,'Rindex=',FLT(ng)%Rindex
      ENDIF
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      'wght_fract', Tout2d,                         &
     &                 (/1,1,FLT(ng)%Rindex/), (/Nfloats(ng),Nocmp,1/),&
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = FLT(ng)%Vid(idwfro))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
!
! DD END
!!!!!
# endif
# ifdef FLOAT_OYSTER
!
!  Write out biological float swimming time.
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
          Tout(l)=DRIFTER(ng)%track(iswim,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      'swim_time', Tout,                          &
     &                      (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),    &
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = Flt(ng)%Vid(idswim))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
!
!  Write out biological float vertical velocity.
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
          Tout(l)=DRIFTER(ng)%track(iwbio,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      'w_bio', Tout,                              &
     &                      (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),    &
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = FLT(ng)%Vid(idwbio))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
!
!  Write out biological float size (length).
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
                Tout(l)=DRIFTER(ng)%track(isizf,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      'bio_size', Tout,                           &
     &                      (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),    &
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = FLT(ng)%Vid(idsize))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
!
!  Write out biological float sinking velocity.
!
      DO l=1,Nfloats(ng)
        IF (DRIFTER(ng)%bounded(l)) THEN
          Tout(l)=DRIFTER(ng)%track(iwsin,nf(ng),l)
        ELSE
          Tout(l)=spval
        END IF
      END DO
      CALL netcdf_put_fvar (ng, iNLM, FLT(ng)%name,                     &
     &                      'bio_sink', Tout,                           &
     &                      (/1,FLT(ng)%Rindex/), (/Nfloats(ng),1/),    &
     &                      ncid = FLT(ng)%ncid,                        &
     &                      varid = FLT(ng)%Vid(idwsin))
      IF (FoundError(exit_flag, NoError, __LINE__,                      &
     &               __FILE__)) RETURN
# endif
!
!-----------------------------------------------------------------------
!  Synchronize floats NetCDF file to disk.
!-----------------------------------------------------------------------
!
      CALL netcdf_sync (ng, iNLM, FLT(ng)%name, FLT(ng)%ncid)

#else
      SUBROUTINE wrt_floats
#endif
      RETURN
      END SUBROUTINE wrt_floats
