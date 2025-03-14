      SUBROUTINE wclock_on (ng, model, region, line, routine)
!
!svn $Id: timers.F 855 2017-07-29 03:10:57Z arango $
!================================================== Hernan G. Arango ===
!  Copyright (c) 2002-2018 The ROMS/TOMS Group                         !
!    Licensed under a MIT/X style license                              !
!    See License_ROMS.txt                                              !
!=======================================================================
!                                                                      !
!  This routine turns on wall clock to meassure the elapsed time in    !
!  seconds spend by each parallel thread in requested model region.    !
!                                                                      !
!  On Input:                                                           !
!                                                                      !
!     ng         Nested grid number (integer)                          !
!     model      Calling model identifier (integer)                    !
!     region     Profiling reagion number (integer)                    !
!     line       Calling model routine line (integer)                  !
!     routine    Calling model routine (string)                        !
!                                                                      !
!=======================================================================
!
      USE mod_param
      USE mod_parallel
      USE mod_iounits
      USE mod_strings
!
      implicit none
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng, model, region, line
      character (len=*), intent(in) :: routine
!
!  Local variable declarations.
!
      integer :: iregion, MyModel, NSUB
      integer :: my_getpid
      integer :: my_threadnum
      real(r8), dimension(2) :: wtime
      real(r8) :: my_wtime
!
!-----------------------------------------------------------------------
! Initialize timing for all threads.
!-----------------------------------------------------------------------
!
!  Set number of subdivisions, same as for global reductions.
!
      NSUB=numthreads
!
!  Insure that MyModel is not zero.
!
      MyModel=MAX(1,model)
!
!  Start the wall CPU clock for specified region, model, and grid.
!
      Cstr(region,MyModel,ng)=my_wtime(wtime)
!
!  If region zero, indicating first call from main driver, initialize
!  time profiling arrays and set process ID.
!
      IF ((region.eq.0).and.(proc(1,MyModel,ng).eq.0)) THEN
        DO iregion=1,Nregion
          Cend(iregion,MyModel,ng)=0.0_r8
          Csum(iregion,MyModel,ng)=0.0_r8
        END DO
        proc(1,MyModel,ng)=1
        proc(0,MyModel,ng)=my_getpid()
!$OMP CRITICAL (START_WCLOCK)
        IF (ng.eq.1) THEN
          WRITE (stdout,10) ' Thread #', MyThread,                      &
     &                      ' (pid=',proc(0,MyModel,ng),') is active.'
        END IF
 10     FORMAT (a,i3,a,i8,a)
        thread_count=thread_count+1
        IF (thread_count.eq.NSUB) thread_count=0
!$OMP END CRITICAL (START_WCLOCK)
      END IF
      RETURN
      END SUBROUTINE wclock_on
!
      SUBROUTINE wclock_off (ng, model, region, line, routine)
!
!=======================================================================
!                                                                      !
!  This routine turns off wall clock to meassure the elapsed time in   !
!  seconds spend by each parallel thread in requested model region.    !
!                                                                      !
!  On Input:                                                           !
!                                                                      !
!     ng         Nested grid number (integer)                          !
!     model      Calling model identifier (integer)                    !
!     region     Profiling reagion number (integer)                    !
!     line       Calling model routine line (integer)                  !
!     routine    Calling model routine (string)                        !
!                                                                      !
!=======================================================================
!
      USE mod_param
      USE mod_parallel
      USE mod_iounits
      USE mod_strings
!
      implicit none
!
!  Imported variable declarations.
!
      integer, intent(in) ::  ng, model, region, line
      character (len=*), intent(in) :: routine
!
!  Local variable declarations.
!
      integer :: imodel, iregion, MyModel, NSUB
      integer :: my_threadnum
      real(r8) :: percent, sumcpu, sumper, total
      real(r8), dimension(2) :: wtime
      real(r8) :: my_wtime
      character (len=14), dimension(4) :: label
!
!-----------------------------------------------------------------------
!  Compute elapsed wall time for all threads.
!-----------------------------------------------------------------------
!
!  Set number of subdivisions, same as for global reductions.
!
      NSUB=numthreads
!
!  Insure that MyModel is not zero.
!
      MyModel=MAX(1,model)
!
!  Compute elapsed CPU time (seconds) for each profile region, except
!  for region zero which is called by the main driver before the
!  simulatiom is stopped.
!
      IF (region.ne.0) THEN
        Cend(region,MyModel,ng)=Cend(region,MyModel,ng)+                &
     &                          (my_wtime(wtime)-                       &
     &                           Cstr(region,MyModel,ng))
      END IF
!
!-----------------------------------------------------------------------
!  If simulation is compleated, compute and report elapsed CPU time for
!  all regions.
!-----------------------------------------------------------------------
!
      IF ((region.eq.0).and.(proc(1,MyModel,ng).eq.1)) THEN
!
!  Computed elapsed wall time for the driver, region=0.  Since it is
!  called only once, "MyModel" will have a value and the other models
!  will be zero.
!
        Cend(region,MyModel,ng)=Cend(region,MyModel,ng)+                &
     &                          (my_wtime(wtime)-                       &
     &                           Cstr(region,MyModel,ng))
        DO imodel=1,4
          proc(1,imodel,ng)=0
        END DO
!$OMP CRITICAL (FINALIZE_WCLOCK)
!
!  Report elapsed time (seconds) for each CPU.  We get the same time
!  time for all nested grids.
!
        IF (ng.eq.1) THEN
          WRITE (stdout,10) ' Thread #', MyThread, ' CPU:',             &
     &                      Cend(region,MyModel,ng)
 10       FORMAT (a,i3,a,f12.3)
        END IF
!
!  Sum the elapsed time for each profile region by model.
!
        thread_count=thread_count+1
        DO imodel=1,4
          DO iregion=0,Nregion
            Csum(iregion,imodel,ng)=Csum(iregion,imodel,ng)+            &
     &                              Cend(iregion,imodel,ng)
          END DO
        END DO
!
!  Compute total elapsed CPU wall time between all parallel threads.
!
        IF (thread_count.eq.NSUB) THEN
          thread_count=0
          IF (Master) THEN
            IF (ng.eq.1) THEN             ! Same for all nested grids
              total_cpu=total_cpu+Csum(region,model,ng)
            END IF
            DO imodel=1,4
              total_model(imodel)=0.0_r8
              DO iregion=1,Nregion
                total_model(imodel)=total_model(imodel)+                &
     &                              Csum(iregion,imodel,ng)
              END DO
            END DO
            IF (ng.eq.1) THEN
              WRITE (stdout,20) ' Total:', total_cpu
 20           FORMAT (a,8x,f14.3)
            END IF
          END IF
!
!  Report profiling times.
!
          label(iNLM)='Nonlinear     '
          label(iTLM)='Tangent linear'
          label(iRPM)='Representer   '
          label(iADM)='Adjoint       '
          DO imodel=1,4
            IF (Master.and.(total_model(imodel).gt.0.0_r8)) THEN
              WRITE (stdout,30) TRIM(label(imodel)),                    &
     &                          'model elapsed CPU time profile, Grid:',&
     &                          ng
 30           FORMAT (/,1x,a,1x,a,1x,i2.2/)
            END IF
            sumcpu=0.0_r8
            sumper=0.0_r8
            DO iregion=1,Mregion-1
              IF (Csum(iregion,imodel,ng).gt.0.0_r8) THEN
                percent=100.0_r8*Csum(iregion, imodel,ng)/total_cpu
                IF (Master) WRITE (stdout,40) Pregion(iregion),         &
     &                                        Csum(iregion,imodel,ng),  &
     &                                        percent
                sumcpu=sumcpu+Csum(iregion,imodel,ng)
                sumper=sumper+percent
              END IF
            END DO
            Ctotal=Ctotal+sumcpu
 40         FORMAT (2x,a,t53,f14.3,2x,'(',f7.4,' %)')
            IF (Master.and.(total_model(imodel).gt.0.0_r8)) THEN
              WRITE (stdout,50) sumcpu, sumper
 50           FORMAT (t47,'Total:',f14.3,2x,f8.4)
            END IF
          END DO
          IF (Master.and.(ng.eq.Ngrids)) THEN
            percent=100.0_r8*Ctotal/total_cpu
            WRITE (stdout,60) Ctotal, percent,                          &
     &                        total_cpu-Ctotal, 100.0_r8-percent
 60         FORMAT (/,2x,                                               &
     &              'Unique code regions profiled .....................'&
     &               f14.3,2x,f8.4,' %'/,2x,                            &
     &              'Residual, non-profiled code ......................'&
     &               f14.3,2x,f8.4,' %'/)
            WRITE (stdout,70) total_cpu
 70         FORMAT (/,' All percentages are with respect to',           &
     &                ' total time =',5x,f12.3,/)
          END IF
        END IF
!$OMP END CRITICAL (FINALIZE_WCLOCK)
      END IF
      RETURN
      END SUBROUTINE wclock_off
