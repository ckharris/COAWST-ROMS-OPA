      MODULE ini_fields_mod
!
!svn $Id: ini_fields.F 830 2017-01-24 21:21:11Z arango $
!================================================== Hernan G. Arango ===
!  Copyright (c) 2002-2018 The ROMS/TOMS Group       Andrew M. Moore   !
!    Licensed under a MIT/X style license                              !
!    See License_ROMS.txt                                              !
!=======================================================================
!                                                                      !
!  This routine initializes other time levels for 2D fields. It also   !
!  couples 3D and 2D momentum equations:  it initializes 2D momentum   !
!  (ubar,vbar) to the vertical integral of initial 3D momentum (u,v).  !
!                                                                      !
!=======================================================================
!
      implicit none
!
      PRIVATE
      PUBLIC :: ini_fields
      PUBLIC :: ini_zeta
!
      CONTAINS
!
!***********************************************************************
      SUBROUTINE ini_fields (ng, tile, model)
!***********************************************************************
!
      USE mod_param
      USE mod_grid
      USE mod_coupling
      USE mod_ocean
      USE mod_sedbed
      USE mod_stepping
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng, tile, model
!
!  Local variable declarations.
!
      integer :: IminS, ImaxS, JminS, JmaxS
      integer :: LBi, UBi, LBj, UBj, LBij, UBij
!
!  Set horizontal starting and ending indices for automatic private
!  storage arrays.
!
      IminS=BOUNDS(ng)%Istr(tile)-3
      ImaxS=BOUNDS(ng)%Iend(tile)+3
      JminS=BOUNDS(ng)%Jstr(tile)-3
      JmaxS=BOUNDS(ng)%Jend(tile)+3
!
!  Determine array lower and upper bounds in the I- and J-directions.
!
      LBi=BOUNDS(ng)%LBi(tile)
      UBi=BOUNDS(ng)%UBi(tile)
      LBj=BOUNDS(ng)%LBj(tile)
      UBj=BOUNDS(ng)%UBj(tile)
!
!  Set array lower and upper bounds for MIN(I,J) directions and
!  MAX(I,J) directions.
!
      LBij=BOUNDS(ng)%LBij
      UBij=BOUNDS(ng)%UBij
!
      CALL wclock_on (ng, iNLM, 2, 53, "ROMS/Nonlinear/ini_fields.F")
      CALL ini_fields_tile (ng, tile, model,                            &
     &                      LBi, UBi, LBj, UBj,                         &
     &                      IminS, ImaxS, JminS, JmaxS,                 &
     &                      kstp(ng), krhs(ng), knew(ng),               &
     &                      nstp(ng), nnew(ng),                         &
     &                      SEDBED(ng) % bottom,                        &
     &                      SEDBED(ng) % bed,                           &
     &                      SEDBED(ng) % bed_frac,                      &
     &                      SEDBED(ng) % bed_mass,                      &
     &                      GRID(ng) % Hz,                              &
     &                      OCEAN(ng) % t,                              &
     &                      OCEAN(ng) % u,                              &
     &                      OCEAN(ng) % v,                              &
     &                      OCEAN(ng) % ubar,                           &
     &                      OCEAN(ng) % vbar,                           &
     &                      OCEAN(ng) % zeta)
      CALL wclock_off (ng, iNLM, 2, 112, "ROMS/Nonlinear/ini_fields.F")
      RETURN
      END SUBROUTINE ini_fields
!
!***********************************************************************
      SUBROUTINE ini_fields_tile (ng, tile, model,                      &
     &                            LBi, UBi, LBj, UBj,                   &
     &                            IminS, ImaxS, JminS, JmaxS,           &
     &                            kstp, krhs, knew,                     &
     &                            nstp, nnew,                           &
     &                            bottom,                               &
     &                            bed, bed_frac, bed_mass,              &
     &                            Hz,                                   &
     &                            t, u, v,                              &
     &                            ubar, vbar, zeta)
!***********************************************************************
!
      USE mod_param
      USE mod_ncparam
      USE mod_scalars
      USE mod_sediment
!
      USE exchange_2d_mod
      USE exchange_3d_mod
      USE t3dbc_mod, ONLY : t3dbc_tile
      USE u3dbc_mod, ONLY : u3dbc_tile
      USE v3dbc_mod, ONLY : v3dbc_tile
      USE u2dbc_mod, ONLY : u2dbc_tile
      USE v2dbc_mod, ONLY : v2dbc_tile
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng, tile, model
      integer, intent(in) :: LBi, UBi, LBj, UBj
      integer, intent(in) :: IminS, ImaxS, JminS, JmaxS
      integer, intent(in) :: kstp, krhs, knew
      integer, intent(in) :: nstp, nnew
!
      real(r8), intent(in) :: Hz(LBi:,LBj:,:)
      real(r8), intent(in) :: zeta(LBi:,LBj:,:)
      real(r8), intent(inout) :: bottom(LBi:,LBj:,:)
      real(r8), intent(inout) :: bed(LBi:,LBj:,:,:)
      real(r8), intent(inout) :: bed_frac(LBi:,LBj:,:,:)
      real(r8), intent(inout) :: bed_mass(LBi:,LBj:,:,:,:)
      real(r8), intent(inout) :: t(LBi:,LBj:,:,:,:)
      real(r8), intent(inout) :: u(LBi:,LBj:,:,:)
      real(r8), intent(inout) :: v(LBi:,LBj:,:,:)
      real(r8), intent(inout) :: ubar(LBi:,LBj:,:)
      real(r8), intent(inout) :: vbar(LBi:,LBj:,:)
!
!  Local variable declarations.
!
      integer :: i, ic, itrc, j, k
      integer :: ised
      real(r8) :: cff1, cff2, cff3, cff4, cff5, cff6, cff7
      real(r8), dimension(IminS:ImaxS,0:N(ng)) :: CF
      real(r8), dimension(IminS:ImaxS,0:N(ng)) :: DC
!
!-----------------------------------------------------------------------
!  Set lower and upper tile bounds and staggered variables bounds for
!  this horizontal domain partition.  Notice that if tile=-1, it will
!  set the values for the global grid.
!-----------------------------------------------------------------------
!
      integer :: Istr, IstrB, IstrP, IstrR, IstrT, IstrM, IstrU
      integer :: Iend, IendB, IendP, IendR, IendT
      integer :: Jstr, JstrB, JstrP, JstrR, JstrT, JstrM, JstrV
      integer :: Jend, JendB, JendP, JendR, JendT
      integer :: Istrm3, Istrm2, Istrm1, IstrUm2, IstrUm1
      integer :: Iendp1, Iendp2, Iendp2i, Iendp3
      integer :: Jstrm3, Jstrm2, Jstrm1, JstrVm2, JstrVm1
      integer :: Jendp1, Jendp2, Jendp2i, Jendp3
!
      Istr   =BOUNDS(ng) % Istr   (tile)
      IstrB  =BOUNDS(ng) % IstrB  (tile)
      IstrM  =BOUNDS(ng) % IstrM  (tile)
      IstrP  =BOUNDS(ng) % IstrP  (tile)
      IstrR  =BOUNDS(ng) % IstrR  (tile)
      IstrT  =BOUNDS(ng) % IstrT  (tile)
      IstrU  =BOUNDS(ng) % IstrU  (tile)
      Iend   =BOUNDS(ng) % Iend   (tile)
      IendB  =BOUNDS(ng) % IendB  (tile)
      IendP  =BOUNDS(ng) % IendP  (tile)
      IendR  =BOUNDS(ng) % IendR  (tile)
      IendT  =BOUNDS(ng) % IendT  (tile)
      Jstr   =BOUNDS(ng) % Jstr   (tile)
      JstrB  =BOUNDS(ng) % JstrB  (tile)
      JstrM  =BOUNDS(ng) % JstrM  (tile)
      JstrP  =BOUNDS(ng) % JstrP  (tile)
      JstrR  =BOUNDS(ng) % JstrR  (tile)
      JstrT  =BOUNDS(ng) % JstrT  (tile)
      JstrV  =BOUNDS(ng) % JstrV  (tile)
      Jend   =BOUNDS(ng) % Jend   (tile)
      JendB  =BOUNDS(ng) % JendB  (tile)
      JendP  =BOUNDS(ng) % JendP  (tile)
      JendR  =BOUNDS(ng) % JendR  (tile)
      JendT  =BOUNDS(ng) % JendT  (tile)
!
      Istrm3 =BOUNDS(ng) % Istrm3 (tile)            ! Istr-3
      Istrm2 =BOUNDS(ng) % Istrm2 (tile)            ! Istr-2
      Istrm1 =BOUNDS(ng) % Istrm1 (tile)            ! Istr-1
      IstrUm2=BOUNDS(ng) % IstrUm2(tile)            ! IstrU-2
      IstrUm1=BOUNDS(ng) % IstrUm1(tile)            ! IstrU-1
      Iendp1 =BOUNDS(ng) % Iendp1 (tile)            ! Iend+1
      Iendp2 =BOUNDS(ng) % Iendp2 (tile)            ! Iend+2
      Iendp2i=BOUNDS(ng) % Iendp2i(tile)            ! Iend+2 interior
      Iendp3 =BOUNDS(ng) % Iendp3 (tile)            ! Iend+3
      Jstrm3 =BOUNDS(ng) % Jstrm3 (tile)            ! Jstr-3
      Jstrm2 =BOUNDS(ng) % Jstrm2 (tile)            ! Jstr-2
      Jstrm1 =BOUNDS(ng) % Jstrm1 (tile)            ! Jstr-1
      JstrVm2=BOUNDS(ng) % JstrVm2(tile)            ! JstrV-2
      JstrVm1=BOUNDS(ng) % JstrVm1(tile)            ! JstrV-1
      Jendp1 =BOUNDS(ng) % Jendp1 (tile)            ! Jend+1
      Jendp2 =BOUNDS(ng) % Jendp2 (tile)            ! Jend+2
      Jendp2i=BOUNDS(ng) % Jendp2i(tile)            ! Jend+2 interior
      Jendp3 =BOUNDS(ng) % Jendp3 (tile)            ! Jend+3
!
!-----------------------------------------------------------------------
!  If not perfect restart, initialize other time levels for 3D momentum.
!-----------------------------------------------------------------------
!
      IF (.not.PerfectRST(ng)) THEN
        DO j=JstrB,JendB
          DO k=1,N(ng)
            DO i=IstrM,IendB
              cff1=u(i,j,k,nstp)
              u(i,j,k,nstp)=cff1
              u(i,j,k,nnew)=cff1
            END DO
          END DO
!
          IF (j.ge.JstrM) THEN
            DO k=1,N(ng)
              DO i=IstrB,IendB
                cff2=v(i,j,k,nstp)
                v(i,j,k,nstp)=cff2
                v(i,j,k,nnew)=cff2
              END DO
            END DO
          END IF
        END DO
!
!  Apply boundary conditions.
!
        CALL u3dbc_tile (ng, tile,                                      &
     &                   LBi, UBi, LBj, UBj, N(ng),                     &
     &                   IminS, ImaxS, JminS, JmaxS,                    &
     &                   nstp, nstp,                                    &
     &                   u)
        CALL v3dbc_tile (ng, tile,                                      &
     &                   LBi, UBi, LBj, UBj, N(ng),                     &
     &                   IminS, ImaxS, JminS, JmaxS,                    &
     &                   nstp, nstp,                                    &
     &                   v)
        CALL u3dbc_tile (ng, tile,                                      &
     &                   LBi, UBi, LBj, UBj, N(ng),                     &
     &                   IminS, ImaxS, JminS, JmaxS,                    &
     &                   nstp, nnew,                                    &
     &                   u)
        CALL v3dbc_tile (ng, tile,                                      &
     &                   LBi, UBi, LBj, UBj, N(ng),                     &
     &                   IminS, ImaxS, JminS, JmaxS,                    &
     &                   nstp, nnew,                                    &
     &                   v)
      END IF
!
      IF (EWperiodic(ng).or.NSperiodic(ng)) THEN
        CALL exchange_u3d_tile (ng, tile,                               &
     &                          LBi, UBi, LBj, UBj, 1, N(ng),           &
     &                          u(:,:,:,nstp))
        CALL exchange_v3d_tile (ng, tile,                               &
     &                          LBi, UBi, LBj, UBj, 1, N(ng),           &
     &                          v(:,:,:,nstp))
        CALL exchange_u3d_tile (ng, tile,                               &
     &                          LBi, UBi, LBj, UBj, 1, N(ng),           &
     &                          u(:,:,:,nnew))
        CALL exchange_v3d_tile (ng, tile,                               &
     &                          LBi, UBi, LBj, UBj, 1, N(ng),           &
     &                          v(:,:,:,nnew))
      END IF
!
!-----------------------------------------------------------------------
!  If not perfect restart, compute vertically-integrated momentum
!  (ubar, vbar) from initial 3D momentum (u, v).
!-----------------------------------------------------------------------
!
!  Here DC(i,1:N) are the grid cell thicknesses, DC(i,0) is the total
!  depth of the water column, and CF(i,0) is the vertical integral.
!
      IF (.not.PerfectRST(ng)) THEN
        DO j=JstrB,JendB
          DO i=IstrM,IendB
            DC(i,0)=0.0_r8
            CF(i,0)=0.0_r8
          END DO
          DO k=1,N(ng)
            DO i=IstrM,IendB
              DC(i,k)=0.5_r8*(Hz(i,j,k)+Hz(i-1,j,k))
              DC(i,0)=DC(i,0)+DC(i,k)
              CF(i,0)=CF(i,0)+DC(i,k)*u(i,j,k,nstp)
            END DO
          END DO
          DO i=IstrM,IendB
            cff1=1.0_r8/DC(i,0)
            cff2=CF(i,0)*cff1
            ubar(i,j,kstp)=cff2
            ubar(i,j,knew)=cff2
          END DO
!
          IF (j.ge.JstrM) THEN
            DO i=IstrB,IendB
              DC(i,0)=0.0_r8
              CF(i,0)=0.0_r8
            END DO
            DO k=1,N(ng)
              DO i=IstrB,IendB
                DC(i,k)=0.5_r8*(Hz(i,j,k)+Hz(i,j-1,k))
                DC(i,0)=DC(i,0)+DC(i,k)
                CF(i,0)=CF(i,0)+DC(i,k)*v(i,j,k,nstp)
              END DO
            END DO
            DO i=IstrB,IendB
              cff1=1.0_r8/DC(i,0)
              cff2=CF(i,0)*cff1
              vbar(i,j,kstp)=cff2
              vbar(i,j,knew)=cff2
            END DO
          END IF
        END DO
!
!  Apply boundary conditions.
!
        IF (.not.(ANY(LBC(:,isUbar,ng)%radiation).or.                   &
     &            ANY(LBC(:,isVbar,ng)%radiation).or.                   &
     &            ANY(LBC(:,isUbar,ng)%Flather).or.                     &
     &            ANY(LBC(:,isVbar,ng)%Flather))) THEN
          CALL u2dbc_tile (ng, tile,                                    &
     &                     LBi, UBi, LBj, UBj,                          &
     &                     IminS, ImaxS, JminS, JmaxS,                  &
     &                     krhs, kstp, kstp,                            &
     &                     ubar, vbar, zeta)
          CALL v2dbc_tile (ng, tile,                                    &
     &                     LBi, UBi, LBj, UBj,                          &
     &                     IminS, ImaxS, JminS, JmaxS,                  &
     &                     krhs, kstp, kstp,                            &
     &                     ubar, vbar, zeta)
          CALL u2dbc_tile (ng, tile,                                    &
     &                     LBi, UBi, LBj, UBj,                          &
     &                     IminS, ImaxS, JminS, JmaxS,                  &
     &                     krhs, kstp, knew,                            &
     &                     ubar, vbar, zeta)
          CALL v2dbc_tile (ng, tile,                                    &
     &                     LBi, UBi, LBj, UBj,                          &
     &                     IminS, ImaxS, JminS, JmaxS,                  &
     &                     krhs, kstp, knew,                            &
     &                     ubar, vbar, zeta)
        END IF
      END IF
!
      IF (EWperiodic(ng).or.NSperiodic(ng)) THEN
        CALL exchange_u2d_tile (ng, tile,                               &
     &                          LBi, UBi, LBj, UBj,                     &
     &                          ubar(:,:,kstp))
        CALL exchange_v2d_tile (ng, tile,                               &
     &                          LBi, UBi, LBj, UBj,                     &
     &                          vbar(:,:,kstp))
        CALL exchange_u2d_tile (ng, tile,                               &
     &                          LBi, UBi, LBj, UBj,                     &
     &                          ubar(:,:,knew))
        CALL exchange_v2d_tile (ng, tile,                               &
     &                          LBi, UBi, LBj, UBj,                     &
     &                          vbar(:,:,knew))
      END IF
!
!-----------------------------------------------------------------------
!  If not perfect restart, initialize other time levels for tracers.
!-----------------------------------------------------------------------
!
      ic=0
      IF (.not.PerfectRST(ng)) THEN
        DO itrc=1,NT(ng)
          IF (LtracerCLM(itrc,ng).and.LnudgeTCLM(itrc,ng)) THEN
            ic=ic+1
          END IF
          DO k=1,N(ng)
            DO j=JstrB,JendB
              DO i=IstrB,IendB
                cff1=t(i,j,k,nstp,itrc)
                t(i,j,k,nstp,itrc)=cff1
                t(i,j,k,nnew,itrc)=cff1
              END DO
            END DO
          END DO
!
!  Apply boundary conditions.
!
          CALL t3dbc_tile (ng, tile, itrc, ic,                          &
     &                     LBi, UBi, LBj, UBj, N(ng), NT(ng),           &
     &                     IminS, ImaxS, JminS, JmaxS,                  &
     &                     nstp, nstp,                                  &
     &                     t)
          CALL t3dbc_tile (ng, tile, itrc, ic,                          &
     &                     LBi, UBi, LBj, UBj, N(ng), NT(ng),           &
     &                     IminS, ImaxS, JminS, JmaxS,                  &
     &                     nstp, nnew,                                  &
     &                     t)
!         ELSE
!          CALL pt3dbc_tile (ng, tile, itrc,                             &
!     &                      LBi, UBi, LBj, UBj, N(ng), NT(ng),          &
!     &                      IminS, ImaxS, JminS, JmaxS,                 &
!     &                      nstp, nstp,                                 &
!     &                      t)
!          CALL pt3dbc_tile (ng, tile, itrc,                             &
!     &                      LBi, UBi, LBj, UBj, N(ng), NT(ng),          &
!     &                      IminS, ImaxS, JminS, JmaxS,                 &
!     &                      nstp, nnew,                                 &
!     &                      t)
!         END IF
        END DO
      END IF
!
      IF (EWperiodic(ng).or.NSperiodic(ng)) THEN
        DO itrc=1,NT(ng)
          CALL exchange_r3d_tile (ng, tile,                             &
     &                            LBi, UBi, LBj, UBj, 1, N(ng),         &
     &                            t(:,:,:,nstp,itrc))
          CALL exchange_r3d_tile (ng, tile,                             &
     &                            LBi, UBi, LBj, UBj, 1, N(ng),         &
     &                            t(:,:,:,nnew,itrc))
        END DO
      END IF
!
!-----------------------------------------------------------------------
!  Initialize sediment bed properties.
!-----------------------------------------------------------------------
!
      IF (.not.PerfectRST(ng)) THEN
        DO k=1,Nbed
          DO j=JstrT,JendT
            DO i=IstrT,IendT
              DO ised=1,NST
                cff1=bed_mass(i,j,k,1,ised)
                bed_mass(i,j,k,2,ised)=cff1
              END DO
            END DO
          END DO
        END DO
      END IF
!
      IF (EWperiodic(ng).or.NSperiodic(ng)) THEN
        DO ised=1,NST
          CALL exchange_r3d_tile (ng, tile,                             &
     &                            LBi, UBi, LBj, UBj, 1, Nbed,          &
     &                            bed_frac(:,:,:,ised))
          CALL exchange_r3d_tile (ng, tile,                             &
     &                            LBi, UBi, LBj, UBj, 1, Nbed,          &
     &                            bed_mass(:,:,:,1,ised))
          CALL exchange_r3d_tile (ng, tile,                             &
     &                            LBi, UBi, LBj, UBj, 1, Nbed,          &
     &                            bed_mass(:,:,:,2,ised))
        END DO
        DO ised=1,MBEDP
          CALL exchange_r3d_tile (ng, tile,                             &
     &                            LBi, UBi, LBj, UBj, 1, Nbed,          &
     &                            bed(:,:,:,ised))
        END DO
        CALL exchange_r3d_tile (ng, tile,                               &
     &                          LBi, UBi, LBj, UBj, 1, MBOTP,           &
     &                          bottom)
      END IF
      RETURN
      END SUBROUTINE ini_fields_tile
!
!***********************************************************************
      SUBROUTINE ini_zeta (ng, tile, model)
!***********************************************************************
!
      USE mod_param
      USE mod_grid
      USE mod_coupling
      USE mod_ocean
      USE mod_stepping
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng, tile, model
!
!  Local variable declarations.
!
      integer :: IminS, ImaxS, JminS, JmaxS
      integer :: LBi, UBi, LBj, UBj, LBij, UBij
!
!  Set horizontal starting and ending indices for automatic private
!  storage arrays.
!
      IminS=BOUNDS(ng)%Istr(tile)-3
      ImaxS=BOUNDS(ng)%Iend(tile)+3
      JminS=BOUNDS(ng)%Jstr(tile)-3
      JmaxS=BOUNDS(ng)%Jend(tile)+3
!
!  Determine array lower and upper bounds in the I- and J-directions.
!
      LBi=BOUNDS(ng)%LBi(tile)
      UBi=BOUNDS(ng)%UBi(tile)
      LBj=BOUNDS(ng)%LBj(tile)
      UBj=BOUNDS(ng)%UBj(tile)
!
!  Set array lower and upper bounds for MIN(I,J) directions and
!  MAX(I,J) directions.
!
      LBij=BOUNDS(ng)%LBij
      UBij=BOUNDS(ng)%UBij
!
      CALL wclock_on (ng, iNLM, 2, 990, "ROMS/Nonlinear/ini_fields.F")
      CALL ini_zeta_tile (ng, tile, model,                              &
     &                    LBi, UBi, LBj, UBj,                           &
     &                    IminS, ImaxS, JminS, JmaxS,                   &
     &                    kstp(ng), krhs(ng), knew(ng),                 &
     &                    COUPLING(ng) % Zt_avg1,                       &
     &                    OCEAN(ng) % zeta)
      CALL wclock_off (ng, iNLM, 2, 1013, "ROMS/Nonlinear/ini_fields.F")
      RETURN
      END SUBROUTINE ini_zeta
!
!***********************************************************************
      SUBROUTINE ini_zeta_tile (ng, tile, model,                        &
     &                          LBi, UBi, LBj, UBj,                     &
     &                          IminS, ImaxS, JminS, JmaxS,             &
     &                          kstp, krhs, knew,                       &
     &                          Zt_avg1,                                &
     &                          zeta)
!***********************************************************************
!
      USE mod_param
      USE mod_ncparam
      USE mod_scalars
!
      USE exchange_2d_mod, ONLY : exchange_r2d_tile
      USE zetabc_mod, ONLY : zetabc_tile
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng, tile, model
      integer, intent(in) :: LBi, UBi, LBj, UBj
      integer, intent(in) :: IminS, ImaxS, JminS, JmaxS
      integer, intent(in) :: kstp, krhs, knew
!
      real(r8), intent(inout) :: Zt_avg1(LBi:,LBj:)
      real(r8), intent(inout) :: zeta(LBi:,LBj:,:)
!
!  Local variable declarations.
!
      integer :: Imin, Imax, Jmin, Jmax
      integer :: i, j, kbed
      real(r8) :: cff1
!
!-----------------------------------------------------------------------
!  Set lower and upper tile bounds and staggered variables bounds for
!  this horizontal domain partition.  Notice that if tile=-1, it will
!  set the values for the global grid.
!-----------------------------------------------------------------------
!
      integer :: Istr, IstrB, IstrP, IstrR, IstrT, IstrM, IstrU
      integer :: Iend, IendB, IendP, IendR, IendT
      integer :: Jstr, JstrB, JstrP, JstrR, JstrT, JstrM, JstrV
      integer :: Jend, JendB, JendP, JendR, JendT
      integer :: Istrm3, Istrm2, Istrm1, IstrUm2, IstrUm1
      integer :: Iendp1, Iendp2, Iendp2i, Iendp3
      integer :: Jstrm3, Jstrm2, Jstrm1, JstrVm2, JstrVm1
      integer :: Jendp1, Jendp2, Jendp2i, Jendp3
!
      Istr   =BOUNDS(ng) % Istr   (tile)
      IstrB  =BOUNDS(ng) % IstrB  (tile)
      IstrM  =BOUNDS(ng) % IstrM  (tile)
      IstrP  =BOUNDS(ng) % IstrP  (tile)
      IstrR  =BOUNDS(ng) % IstrR  (tile)
      IstrT  =BOUNDS(ng) % IstrT  (tile)
      IstrU  =BOUNDS(ng) % IstrU  (tile)
      Iend   =BOUNDS(ng) % Iend   (tile)
      IendB  =BOUNDS(ng) % IendB  (tile)
      IendP  =BOUNDS(ng) % IendP  (tile)
      IendR  =BOUNDS(ng) % IendR  (tile)
      IendT  =BOUNDS(ng) % IendT  (tile)
      Jstr   =BOUNDS(ng) % Jstr   (tile)
      JstrB  =BOUNDS(ng) % JstrB  (tile)
      JstrM  =BOUNDS(ng) % JstrM  (tile)
      JstrP  =BOUNDS(ng) % JstrP  (tile)
      JstrR  =BOUNDS(ng) % JstrR  (tile)
      JstrT  =BOUNDS(ng) % JstrT  (tile)
      JstrV  =BOUNDS(ng) % JstrV  (tile)
      Jend   =BOUNDS(ng) % Jend   (tile)
      JendB  =BOUNDS(ng) % JendB  (tile)
      JendP  =BOUNDS(ng) % JendP  (tile)
      JendR  =BOUNDS(ng) % JendR  (tile)
      JendT  =BOUNDS(ng) % JendT  (tile)
!
      Istrm3 =BOUNDS(ng) % Istrm3 (tile)            ! Istr-3
      Istrm2 =BOUNDS(ng) % Istrm2 (tile)            ! Istr-2
      Istrm1 =BOUNDS(ng) % Istrm1 (tile)            ! Istr-1
      IstrUm2=BOUNDS(ng) % IstrUm2(tile)            ! IstrU-2
      IstrUm1=BOUNDS(ng) % IstrUm1(tile)            ! IstrU-1
      Iendp1 =BOUNDS(ng) % Iendp1 (tile)            ! Iend+1
      Iendp2 =BOUNDS(ng) % Iendp2 (tile)            ! Iend+2
      Iendp2i=BOUNDS(ng) % Iendp2i(tile)            ! Iend+2 interior
      Iendp3 =BOUNDS(ng) % Iendp3 (tile)            ! Iend+3
      Jstrm3 =BOUNDS(ng) % Jstrm3 (tile)            ! Jstr-3
      Jstrm2 =BOUNDS(ng) % Jstrm2 (tile)            ! Jstr-2
      Jstrm1 =BOUNDS(ng) % Jstrm1 (tile)            ! Jstr-1
      JstrVm2=BOUNDS(ng) % JstrVm2(tile)            ! JstrV-2
      JstrVm1=BOUNDS(ng) % JstrVm1(tile)            ! JstrV-1
      Jendp1 =BOUNDS(ng) % Jendp1 (tile)            ! Jend+1
      Jendp2 =BOUNDS(ng) % Jendp2 (tile)            ! Jend+2
      Jendp2i=BOUNDS(ng) % Jendp2i(tile)            ! Jend+2 interior
      Jendp3 =BOUNDS(ng) % Jendp3 (tile)            ! Jend+3
!
!-----------------------------------------------------------------------
!  Initialize other time levels for free-surface.
!-----------------------------------------------------------------------
!
      IF (.not.PerfectRST(ng)) THEN
        IF (.not.(ANY(LBC(:,isFsur,ng)%radiation).or.                   &
     &            ANY(LBC(:,isFsur,ng)%Chapman_explicit).or.            &
     &            ANY(LBC(:,isFsur,ng)%Chapman_implicit))) THEN
          Imin=IstrB
          Imax=IendB
          Jmin=JstrB
          Jmax=JendB
        ELSE
          Imin=IstrT
          Imax=IendT
          Jmin=JstrT
          Jmax=JendT
        END IF
        DO j=Jmin,Jmax
          DO i=Imin,Imax
            cff1=zeta(i,j,kstp)
            zeta(i,j,kstp)=cff1
            zeta(i,j,knew)=cff1
          END DO
        END DO
!
!  Apply boundary conditions.
!
        IF (.not.(ANY(LBC(:,isFsur,ng)%radiation).or.                   &
     &            ANY(LBC(:,isFsur,ng)%Chapman_explicit).or.            &
     &            ANY(LBC(:,isFsur,ng)%Chapman_implicit))) THEN
          CALL zetabc_tile (ng, tile,                                   &
     &                      LBi, UBi, LBj, UBj,                         &
     &                      IminS, ImaxS, JminS, JmaxS,                 &
     &                      krhs, kstp, kstp,                           &
     &                      zeta)
          CALL zetabc_tile (ng, tile,                                   &
     &                      LBi, UBi, LBj, UBj,                         &
     &                      IminS, ImaxS, JminS, JmaxS,                 &
     &                      krhs, kstp, knew,                           &
     &                      zeta)
        END IF
      END IF
!
      IF (EWperiodic(ng).or.NSperiodic(ng)) THEN
        CALL exchange_r2d_tile (ng, tile,                               &
     &                          LBi, UBi, LBj, UBj,                     &
     &                          zeta(:,:,kstp))
        CALL exchange_r2d_tile (ng, tile,                               &
     &                          LBi, UBi, LBj, UBj,                     &
     &                          zeta(:,:,knew))
        IF (PerfectRST(ng)) THEN
          CALL exchange_r2d_tile (ng, tile,                             &
     &                            LBi, UBi, LBj, UBj,                   &
     &                            zeta(:,:,krhs))
        END IF
      END IF
!
!-----------------------------------------------------------------------
!  Initialize fast-time averaged free-surface (Zt_avg1) with the inital
!  free-surface
!-----------------------------------------------------------------------
!
      DO j=JstrT,JendT
        DO i=IstrT,IendT
          Zt_avg1(i,j)=zeta(i,j,kstp)
        END DO
      END DO
!
      IF (EWperiodic(ng).or.NSperiodic(ng)) THEN
        CALL exchange_r2d_tile (ng, tile,                               &
     &                          LBi, UBi, LBj, UBj,                     &
     &                          Zt_avg1)
      END IF
      RETURN
      END SUBROUTINE ini_zeta_tile
      END MODULE ini_fields_mod
