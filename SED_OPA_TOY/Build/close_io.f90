      SUBROUTINE close_inp (ng, model)
!
!svn $Id: close_io.F 882 2017-11-23 05:41:19Z arango $
!================================================== Hernan G. Arango ===
!  Copyright (c) 2002-2018 The ROMS/TOMS Group                         !
!    Licensed under a MIT/X style license                              !
!    See License_ROMS.txt                                              !
!=======================================================================
!                                                                      !
! This subroutine checks some input files are in close state.  It is   !
! used during initialization to force all multi-file input fields to   !
! in close state. This is important in iterative algorithms that run   !
! the full model repetitevely.                                         !
!                                                                      !
!=======================================================================
!
      USE mod_param
      USE mod_iounits
      USE mod_ncparam
      USE mod_netcdf
      USE mod_scalars
!
      USE strings_mod, ONLY : FoundError
!
      implicit none
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng, model
!
!  Local variable declarations.
!
      integer :: Fcount, i, j, lstr
!
      SourceFile="ROMS/Utility/close_io.F" // ", close_io.F"
!
!-----------------------------------------------------------------------
!  If multi-file input fields, close several input files.
!-----------------------------------------------------------------------
!
!  If appropriate, close boundary files.
!
      IF (ObcData(ng)) THEN
        DO i=1,nBCfiles(ng)
          IF ((BRY(i,ng)%Nfiles.gt.1).and.(BRY(i,ng)%ncid.ge.0)) THEN
            IF (model.eq.iADM) THEN
              DO j=1,BRY(i,ng)%Nfiles
                IF ((BRY(i,ng)%time_min(j).le.tdays(ng)).and.           &
     &              (tdays(ng).le.BRY(i,ng)%time_max(j))) THEN
                  Fcount=j
                  EXIT
                END IF
              END DO
            ELSE
              Fcount=1
            END IF
            BRY(i,ng)%Fcount=Fcount
            BRY(i,ng)%name=TRIM(BRY(i,ng)%files(Fcount))
            lstr=LEN_TRIM(BRY(i,ng)%name)
            BRY(i,ng)%base=BRY(i,ng)%name(1:lstr-3)
            CALL netcdf_close (ng, model, BRY(i,ng)%ncid,               &
     &                         BRY(i,ng)%files(i),  .FALSE.)
            IF (FoundError(exit_flag, NoError, 100,                     &
     &                   "ROMS/Utility/close_io.F")) RETURN
          END IF
        END DO
      END IF
!
!  If appropriate, close climatology files.
!
      IF (CLM_FILE(ng)) THEN
        DO i=1,nCLMfiles(ng)
          IF ((CLM(i,ng)%Nfiles.gt.1).and.(CLM(i,ng)%ncid.ge.0)) THEN
            IF (model.eq.iADM) THEN
              DO j=1,CLM(i,ng)%Nfiles
                IF ((CLM(i,ng)%time_min(i).le.tdays(ng)).and.             &
     &            (tdays(ng).le.CLM(i,ng)%time_max(i))) THEN
                  Fcount=j
                  EXIT
                END IF
              END DO
            ELSE
              Fcount=1
            END IF
            CLM(i,ng)%Fcount=Fcount
            CLM(i,ng)%name=TRIM(CLM(i,ng)%files(Fcount))
            lstr=LEN_TRIM(CLM(i,ng)%name)
            CLM(i,ng)%base=CLM(i,ng)%name(1:lstr-3)
            CALL netcdf_close (ng, model, CLM(i,ng)%ncid,                 &
     &                     CLM(i,ng)%files(i),  .FALSE.)
            IF (FoundError(exit_flag, NoError, 128,                     &
     &                   "ROMS/Utility/close_io.F")) RETURN
          END IF
        END DO
      END IF
      RETURN
      END SUBROUTINE close_inp
!
      SUBROUTINE close_out
!
!=======================================================================
!                                                                      !
! This subroutine flushes and closes all output files.                 !
!                                                                      !
!=======================================================================
!
      USE mod_param
      USE mod_parallel
      USE mod_iounits
      USE mod_ncparam
      USE mod_netcdf
      USE mod_scalars
      USE strings_mod, ONLY : FoundError
!
      USE dateclock_mod, ONLY : get_date
!
      implicit none
!
!  Local variable declarations.
!
      logical :: First
      integer :: Fcount, MyError, i, ng
!
      SourceFile="ROMS/Utility/close_io.F" // ", close_out"
!
!-----------------------------------------------------------------------
!  Close output NetCDF files. Set file indices to closed state.
!-----------------------------------------------------------------------
!
      DO ng=1,Ngrids
        IF (RST(ng)%ncid.ne.-1) THEN
          CALL netcdf_close (ng, iNLM, RST(ng)%ncid)
        END IF
        IF (HIS(ng)%ncid.ne.-1) THEN
          CALL netcdf_close (ng, iNLM, HIS(ng)%ncid)
        END IF
        IF (QCK(ng)%ncid.ne.-1) THEN
          CALL netcdf_close (ng, iNLM, QCK(ng)%ncid)
        END IF
!
!  Report number of time records written.
!
        IF (Master) THEN
          WRITE (stdout,10) ng
          IF (associated(HIS(ng)%Nrec)) THEN
            Fcount=HIS(ng)%Fcount
            IF (HIS(ng)%Nrec(Fcount).gt.0) THEN
              WRITE (stdout,20) 'HISTORY', HIS(ng)%Nrec(Fcount)
            END IF
          END IF
          IF (associated(RST(ng)%Nrec)) THEN
            Fcount=RST(ng)%Fcount
            IF (RST(ng)%Nrec(Fcount).gt.0) THEN
              IF (LcycleRST(ng)) THEN
                IF (RST(ng)%Nrec(Fcount).gt.1) THEN
                  RST(ng)%Nrec(Fcount)=2
                ELSE
                  RST(ng)%Nrec(Fcount)=1
                END IF
              END IF
              WRITE (stdout,20) 'RESTART', RST(ng)%Nrec(Fcount)
            END IF
          END IF
        END IF
      END DO
!
!-----------------------------------------------------------------------
!  Report analytical header files used.
!-----------------------------------------------------------------------
!
      IF (Master) THEN
        First=.TRUE.
        DO i=1,51
          IF ((LEN_TRIM(ANANAME(i)).gt.0).and.(exit_flag.ne.5)) THEN
            IF (First) THEN
              First=.FALSE.
              WRITE (stdout,30) ' Analytical header files used:'
            END IF
            WRITE (stdout,'(5x,a)') TRIM(ADJUSTL(ANANAME(i)))
          END IF
        END DO
      END IF
!
!-----------------------------------------------------------------------
!  If applicable, report internal exit errors.
!-----------------------------------------------------------------------
!
      IF (Master.and.(FoundError(exit_flag, NoError, 456,               &
     &               "ROMS/Utility/close_io.F"))) THEN
        WRITE (stdout,40) Rerror(exit_flag), exit_flag
      END IF
      IF (exit_flag.eq.NoError) THEN
        CALL get_date (date_str)
        IF (Master) WRITE (stdout,50) TRIM(date_str)
      ELSE IF ((exit_flag.eq.1).or.(blowup.ne.0)) THEN
        IF (Master) WRITE (stdout,60)
      ELSE IF (exit_flag.eq.2) THEN
        IF (Master) WRITE (stdout,70) nf90_strerror(ioerror)
      ELSE IF (exit_flag.eq.3) THEN
        IF (Master) WRITE (stdout,80) nf90_strerror(ioerror)
      ELSE IF (exit_flag.eq.4) THEN
        IF (Master) WRITE (stdout,90)
      ELSE IF (exit_flag.eq.5) THEN
        IF (Master) WRITE (stdout,100)
      ELSE IF (exit_flag.eq.6) THEN
        IF (Master) WRITE (stdout,110)
      ELSE IF (exit_flag.eq.7) THEN
        IF (Master) WRITE (stdout,120)
      ELSE IF (exit_flag.eq.8) THEN
        IF (Master) WRITE (stdout,130)
      ELSE IF (exit_flag.eq.9) THEN
        IF (Master) WRITE (stdout,140)
      END IF
!
 10   FORMAT (/,' ROMS/TOMS - Output NetCDF summary for Grid ',         &
     &        i2.2,':')
 20   FORMAT (13x,'number of time records written in ',                 &
     &        a,' file = ',i8.8)
 30   FORMAT (/,a,/)
 40   FORMAT (/,a,i3,/)
 50   FORMAT (/,' ROMS/TOMS: DONE... ',a)
 60   FORMAT (/,' MAIN: Abnormal termination: BLOWUP.')
 70   FORMAT (/,' ERROR: Abnormal termination: NetCDF INPUT.',/,        &
     &          ' REASON: ',a)
 80   FORMAT (/,' ERROR: Abnormal termination: NetCDF OUTPUT.',/,       &
     &          ' REASON: ',a)
 90   FORMAT (/,' ERROR: I/O related problem.')
100   FORMAT (/,' ERROR: Illegal model configuration.')
110   FORMAT (/,' ERROR: Illegal domain partition.')
120   FORMAT (/,' ERROR: Illegal input parameter.')
130   FORMAT (/,' ERROR: Fatal algorithm result.')
140   FORMAT (/,' ERROR: Fatal frazil ice check.')
      RETURN
      END SUBROUTINE close_out
