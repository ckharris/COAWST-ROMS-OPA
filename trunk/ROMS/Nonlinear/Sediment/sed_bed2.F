#include "cppdefs.h"

      MODULE sed_bed_mod2

#if defined NONLINEAR && defined SEDIMENT  && defined NONCOHESIVE_BED2
!
!svn $Id: sed_bed.F 2163 2011-06-08 03:22:34Z aretxabaleta $
!============================================== Alfredo Aretxabaleta ===
!  Copyright (c) 2002-2017 The ROMS/TOMS Group      Hernan G. Arango   !
!    Licensed under a MIT/X style license                              !
!    See License_ROMS.txt                                              !
!=======================================================================
!                                                                      !
!  This routine computes sediment bed layer stratigraphy.              !
!                                                                      !
!  Warner, J.C., C.R. Sherwood, R.P. Signell, C.K. Harris, and H.G.    !
!    Arango, 2008:  Development of a three-dimensional,  regional,     !
!    coupled wave, current, and sediment-transport model, Computers    !
!    & Geosciences, 34, 1284-1306.                                     !
!                                                                      !
!=======================================================================
!
      implicit none

      PRIVATE
      PUBLIC  :: sed_bed2

      CONTAINS
!
!***********************************************************************
      SUBROUTINE sed_bed2 (ng, tile)
!***********************************************************************
!
      USE mod_param
      USE mod_forces
      USE mod_grid
      USE mod_ocean
      USE mod_sedbed
      USE mod_stepping
# ifdef BBL_MODEL
      USE mod_bbl
# endif
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng, tile
!
!  Local variable declarations.
!
# include "tile.h"
!
# ifdef PROFILE
      CALL wclock_on (ng, iNLM, 16)
# endif
      CALL sed_bed_tile (ng, tile,                                      &
     &                   LBi, UBi, LBj, UBj,                            &
     &                   IminS, ImaxS, JminS, JmaxS,                    &
     &                   nstp(ng), nnew(ng),                            &
# ifdef WET_DRY
     &                   GRID(ng) % rmask_wet,                          &
# endif
# ifdef BBL_MODEL
     &                   BBL(ng) % bustrc,                              &
     &                   BBL(ng) % bvstrc,                              &
     &                   BBL(ng) % bustrw,                              &
     &                   BBL(ng) % bvstrw,                              &
     &                   BBL(ng) % bustrcwmax,                          &
     &                   BBL(ng) % bvstrcwmax,                          &
# else
     &                   FORCES(ng) % bustr,                            &
     &                   FORCES(ng) % bvstr,                            &
# endif
     &                   OCEAN(ng) % t,                                 &
# ifdef SUSPLOAD
     &                   SEDBED(ng) % ero_flux,                         &
     &                   SEDBED(ng) % settling_flux,                    &
# endif
# if defined SED_MORPH
     &                   SEDBED(ng) % bed_thick,                        &
# endif
     &                   SEDBED(ng) % bed,                              &
     &                   SEDBED(ng) % bed_frac,                         &
     &                   SEDBED(ng) % bed_mass,                         &
     &                   SEDBED(ng) % bottom)
# ifdef PROFILE
      CALL wclock_off (ng, iNLM, 16)
# endif
      RETURN
      END SUBROUTINE sed_bed2
!
!***********************************************************************
      SUBROUTINE sed_bed_tile (ng, tile,                                &
     &                         LBi, UBi, LBj, UBj,                      &
     &                         IminS, ImaxS, JminS, JmaxS,              &
     &                         nstp, nnew,                              &
# ifdef WET_DRY
     &                         rmask_wet,                               &
# endif
# ifdef BBL_MODEL
     &                         bustrc, bvstrc,                          &
     &                         bustrw, bvstrw,                          &
     &                         bustrcwmax, bvstrcwmax,                  &
# else
     &                         bustr, bvstr,                            &
# endif
     &                         t,                                       &
# ifdef SUSPLOAD
     &                         ero_flux, settling_flux,                 &
# endif
# if defined SED_MORPH
     &                         bed_thick,                               &
# endif
     &                         bed, bed_frac, bed_mass,                 &
     &                         bottom)
!***********************************************************************
!
      USE mod_param
      USE mod_scalars
      USE mod_sediment
!
      USE bc_3d_mod, ONLY : bc_r3d_tile
      USE exchange_2d_mod, ONLY : exchange_r2d_tile
# ifdef DISTRIBUTE
      USE mp_exchange_mod, ONLY : mp_exchange3d, mp_exchange4d
# endif
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng, tile
      integer, intent(in) :: LBi, UBi, LBj, UBj
      integer, intent(in) :: IminS, ImaxS, JminS, JmaxS
      integer, intent(in) :: nstp, nnew
!
# ifdef ASSUMED_SHAPE
#  ifdef WET_DRY
      real(r8), intent(in) :: rmask_wet(LBi:,LBj:)
#  endif
#  ifdef BBL_MODEL
      real(r8), intent(in) :: bustrc(LBi:,LBj:)
      real(r8), intent(in) :: bvstrc(LBi:,LBj:)
      real(r8), intent(in) :: bustrw(LBi:,LBj:)
      real(r8), intent(in) :: bvstrw(LBi:,LBj:)
      real(r8), intent(in) :: bustrcwmax(LBi:,LBj:)
      real(r8), intent(in) :: bvstrcwmax(LBi:,LBj:)
#  else
      real(r8), intent(in) :: bustr(LBi:,LBj:)
      real(r8), intent(in) :: bvstr(LBi:,LBj:)
#  endif
#  if defined SED_MORPH
      real(r8), intent(inout):: bed_thick(LBi:,LBj:,:)
#  endif
      real(r8), intent(inout) :: t(LBi:,LBj:,:,:,:)
#  ifdef SUSPLOAD
      real(r8), intent(inout) :: ero_flux(LBi:,LBj:,:)
      real(r8), intent(inout) :: settling_flux(LBi:,LBj:,:)
#  endif
      real(r8), intent(inout) :: bed(LBi:,LBj:,:,:)
      real(r8), intent(inout) :: bed_frac(LBi:,LBj:,:,:)
      real(r8), intent(inout) :: bed_mass(LBi:,LBj:,:,:,:)
      real(r8), intent(inout) :: bottom(LBi:,LBj:,:)
# else
#  ifdef WET_DRY
      real(r8), intent(in) :: rmask_wet(LBi:UBi,LBj:UBj)
#  endif
#  ifdef BBL_MODEL
      real(r8), intent(in) :: bustrc(LBi:UBi,LBj:UBj)
      real(r8), intent(in) :: bvstrc(LBi:UBi,LBj:UBj)
      real(r8), intent(in) :: bustrw(LBi:UBi,LBj:UBj)
      real(r8), intent(in) :: bvstrw(LBi:UBi,LBj:UBj)
      real(r8), intent(in) :: bustrcwmax(LBi:UBi,LBj:UBj)
      real(r8), intent(in) :: bvstrcwmax(LBi:UBi,LBj:UBj)
#  else
      real(r8), intent(in) :: bustr(LBi:UBi,LBj:UBj)
      real(r8), intent(in) :: bvstr(LBi:UBi,LBj:UBj)
#  endif
#  if defined SED_MORPH
      real(r8), intent(inout):: bed_thick(LBi:UBi,LBj:UBj,2)
#  endif
      real(r8), intent(inout) :: t(LBi:UBi,LBj:UBj,N(ng),3,NT(ng))
#  ifdef SUSPLOAD
      real(r8), intent(inout) :: ero_flux(LBi:UBi,LBj:UBj,NST)
      real(r8), intent(inout) :: settling_flux(LBi:UBi,LBj:UBj,NST)
#  endif
      real(r8), intent(inout) :: bed(LBi:UBi,LBj:UBj,Nbed,MBEDP)
      real(r8), intent(inout) :: bed_frac(LBi:UBi,LBj:UBj,Nbed,NST)
      real(r8), intent(inout) :: bed_mass(LBi:UBi,LBj:UBj,Nbed,1:2,NST)
      real(r8), intent(inout) :: bottom(LBi:UBi,LBj:UBj,MBOTP)
# endif
!
!  Local variable declarations.
!
      integer :: Ksed, i, ised, j, k, ks
      integer :: bnew, nnn

      real(r8), parameter :: eps = 1.0E-14_r8

      real(r8) :: cff, cff1, cff2, cff3
      real(r8) :: thck_avail, thck_to_add

      real(r8), dimension(NST) :: nlysm
      
      real(r8), dimension(IminS:ImaxS,NST) :: dep_mass
      real(r8), dimension(IminS:ImaxS,JminS:JmaxS) :: tau_w

# include "set_bounds.h"

# ifdef BEDLOAD
      bnew=nnew
# else
      bnew=nstp
# endif

! KLUDGE alert
! minlayer_thick(ng) = 0.0005
minlayer_thick(ng) = newlayer_thick(ng)
!
!-----------------------------------------------------------------------
! Compute sediment bed layer stratigraphy.
!-----------------------------------------------------------------------
!
# if defined BEDLOAD_MPM || defined SUSPLOAD
#  ifdef BBL_MODEL
      DO j=Jstr-1,Jend+1
        DO i=Istr-1,Iend+1
          tau_w(i,j)=SQRT(bustrcwmax(i,j)*bustrcwmax(i,j)+              &
     &                    bvstrcwmax(i,j)*bvstrcwmax(i,j))
#   ifdef WET_DRY
          tau_w(i,j)=tau_w(i,j)*rmask_wet(i,j)
#   endif
        END DO
      END DO
#  else
      DO j=Jstrm1,Jendp1
        DO i=Istrm1,Iendp1
          tau_w(i,j)=0.5_r8*SQRT((bustr(i,j)+bustr(i+1,j))*             &
     &                           (bustr(i,j)+bustr(i+1,j))+             &
     &                           (bvstr(i,j)+bvstr(i,j+1))*             &
     &                           (bvstr(i,j)+bvstr(i,j+1)))
#   ifdef WET_DRY
          tau_w(i,j)=tau_w(i,j)*rmask_wet(i,j)
#   endif
        END DO
      END DO
#  endif
# endif
!
!-----------------------------------------------------------------------
!  Update bed properties according to ero_flux and dep_flux.
!-----------------------------------------------------------------------
!
# ifdef SUSPLOAD
      J_LOOP : DO j=Jstr,Jend
                                !
                                !  The deposition and resuspension of sediment on the bottom "bed"
                                !  is due to precipitation flux FC(:,0), already computed, and the
                                !  resuspension (erosion, hence called ero_flux). The resuspension is
                                !  applied to the bottom-most grid box value qc(:,1) so the total mass
                                !  is conserved. Restrict "ero_flux" so that "bed" cannot go negative
                                !  after both fluxes are applied.
                                !
      DO i=Istr,Iend
         SED_LOOP: DO ised=1,NST  
            dep_mass(i,ised)=0.0_r8
#  ifdef SED_MORPH
            ! Apply morphology factor.
             ero_flux(i,j,ised)=ero_flux(i,j,ised)*morph_fac(ised,ng)
             settling_flux(i,j,ised)=settling_flux(i,j,ised)*            &
     &          morph_fac(ised,ng)
#  endif

            !  Update bed mass arrays.
            bed_mass(i,j,1,nnew,ised)=MAX(bed_mass(i,j,1,bnew,ised)-     &
     &        (ero_flux(i,j,ised)-                                       &
     &        settling_flux(i,j,ised)),                                  &
     &        0.0_r8)
            DO k=2,Nbed
               bed_mass(i,j,k,nnew,ised)=bed_mass(i,j,k,nstp,ised)
            END DO
         END DO SED_LOOP
      
         cff3=0.0_r8
         DO ised=1,NST
            cff3=cff3+bed_mass(i,j,1,nnew,ised)
         END DO

         IF (cff3.eq.0.0_r8) THEN 
            cff3=eps 
         END IF 
         bed(i,j,1,ithck)=0.0_r8
         DO ised=1,NST
            bed_frac(i,j,1,ised)=bed_mass(i,j,1,nnew,ised)/cff3
            bed(i,j,1,ithck)=MAX(bed(i,j,1,ithck)+                      &
     &        bed_mass(i,j,1,nnew,ised)/                                &
     &        (Srho(ised,ng)*                                         &
     &        (1.0_r8-bed(i,j,1,iporo))),0.0_r8)
         END DO
      END DO
      
      END DO J_LOOP 
# endif /* SUSPLOAD section */
!
!-----------------------------------------------------------------------
!  At this point, all deposition or erosion is complete, and
!  has been added/subtracted to top layer. Thickness has NOT been corrected.
!-----------------------------------------------------------------------
!
        J_LOOP2 : DO j=Jstr,Jend
        DO i=Istr,Iend

!       Calculate active layer thickness, bottom(i,j,iactv).
!       (trunk version allows this to be zero...this has minimum of 6*D50)
          bottom(i,j,iactv)=MAX(0.0_r8,                                 &
     &                          0.007_r8*                               &
     &                          (tau_w(i,j)-bottom(i,j,itauc))*rho0)+   &
     &                          6.0_r8*bottom(i,j,isd50)
# ifdef SED_MORPH
           ! Apply morphology factor.
           bottom(i,j,iactv)=MAX(bottom(i,j,iactv)*morph_fac(1,ng),      &
     &          bottom(i,j,iactv))
# endif
!
!          Calculate net deposition and erosion
           cff=0.0_r8
           cff2=0.0_r8
! SED_OPA - the first two classes are mud classes, hard-coded here.
!           DO ised=1,NST
           DO ised=1,NST-9
              cff=cff+settling_flux(i,j,ised)
              cff2=cff2+ero_flux(i,j,ised)
              dep_mass(i,ised)=0.0_r8
              IF ((ero_flux(i,j,ised)-settling_flux(i,j,ised)).lt.      &
     &             0.0_r8) THEN
                 dep_mass(i,ised)=settling_flux(i,j,ised)-              &
     &                ero_flux(i,j,ised)
              END IF
           END DO

           IF ( cff-cff2.GT.0.0_r8) THEN ! NET depostion
              !  Deposition. Determine if we need to create a new bed layer 
              ! (no test for age here)
              bed(i,j,1,iaged)=time(ng)
              IF(bed(i,j,1,ithck).gt.                                   &
     &             MAX(bottom(i,j,iactv),newlayer_thick(ng))) THEN
                 ! Top layer is too thick
                 IF (Nbed.gt.2) THEN
                    IF(bed(i,j,2,ithck).lt.minlayer_thick(ng)) THEN
                    ! Layer 2 is smaller than minimum size
                    ! Instead of pushing down all layers, just combine top 2 layers
                       cff=0.0_r8
                       cff1=0.0_r8
                       cff2=0.0_r8
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                       DO ised=1,NST
                       DO ised=1,NST-9
                          cff =cff +dep_mass(i,ised)
                          cff1=cff1+bed_mass(i,j,1,nnew,ised)
                          cff2=cff2+bed_mass(i,j,2,nnew,ised)
                       END DO
                       !  Update bed mass
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                       DO ised=1,NST
                       DO ised=1,NST-9
                          bed_mass(i,j,2,nnew,ised)=                    &
     &                         MAX(bed_mass(i,j,2,nnew,ised)+           &
     &                         bed_mass(i,j,1,nnew,ised)-               &
     &                         dep_mass(i,ised),0.0_r8)
                          bed_mass(i,j,1,nnew,ised)=dep_mass(i,ised)
                       END DO
                       ! ALA - average time and porosity
                       ! ALA CHECK WITH CRS cff1 or cff1-cff for first layer
                       bed(i,j,2,iaged)=(bed(i,j,1,iaged)*cff1+         &
     &                         bed(i,j,2,iaged)*cff2)/(cff1+cff2)
                       bed(i,j,1,iaged)=time(ng)
                       bed(i,j,2,iporo)=(bed(i,j,1,iporo)*cff1+         &
     &                         bed(i,j,2,iporo)*cff2)/(cff1+cff2)
                       ! ALA CHECK WITH CRS POROSITY OF 1ST LAYER
                       bed(i,j,1,iporo)=bed(i,j,1,iporo)
                    ELSE
                    ! Layer 2 is > minlayer thick, need another layer
                    !  Combine bottom layers.
                       cff1=0.0_r8
                       cff2=0.0_r8
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                       DO ised=1,NST
                       DO ised=1,NST-9
                          cff1=cff1+bed_mass(i,j,Nbed-1,nnew,ised)
                          cff2=cff2+bed_mass(i,j,Nbed,nnew,ised)
                       END DO
                       bed(i,j,Nbed,iporo)=                             &
     &                      (bed(i,j,Nbed-1,iporo)*cff1+                &
     &                      bed(i,j,Nbed,iporo)*cff2)/(cff1+cff2)
                       bed(i,j,Nbed,iaged)=                             &
     &                      (bed(i,j,Nbed-1,iaged)*cff1+                &
     &                      bed(i,j,Nbed,iaged)*cff2)/(cff1+cff2)
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                       DO ised=1,NST
                       DO ised=1,NST-9
                          bed_mass(i,j,Nbed,nnew,ised)=                 &
     &                         bed_mass(i,j,Nbed-1,nnew,ised)+          &
     &                         bed_mass(i,j,Nbed  ,nnew,ised)
                       END DO
                       !
                       !  Push layers down.
                       DO k=Nbed-1,2,-1
                          bed(i,j,k,iporo)=bed(i,j,k-1,iporo)
                          bed(i,j,k,iaged)=bed(i,j,k-1,iaged)
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                          DO ised =1,NST
                          DO ised =1,NST-9
                             bed_mass(i,j,k,nnew,ised)=                 &
     &                            bed_mass(i,j,k-1,nnew,ised)
                          END DO
                       END DO
                       !  Set new top parameters for top 2 layers
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                       DO ised=1,NST
                       DO ised=1,NST-9
                          bed_mass(i,j,2,nnew,ised)=                    &
     &                         MAX(bed_mass(i,j,2,nnew,ised)-           &
     &                         dep_mass(i,ised),0.0_r8)
                          bed_mass(i,j,1,nnew,ised)=dep_mass(i,ised)
                       END DO
                    END IF
                 ELSEIF (Nbed.eq.2) THEN 
                 ! NBED=2
                    cff1=0.0_r8
                    cff2=0.0_r8
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                    DO ised=1,NST
                    DO ised=1,NST-9
                       cff1=cff1+bed_mass(i,j,1,nnew,ised)
                       cff2=cff2+bed_mass(i,j,2,nnew,ised)
                    END DO
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                    DO ised=1,NST
                    DO ised=1,NST-9
                       bed_mass(i,j,2,nnew,ised)=                       &
     &                      MAX(bed_mass(i,j,2,nnew,ised)+              &
     &                      bed_mass(i,j,1,nnew,ised)-                  &
     &                      dep_mass(i,ised),0.0_r8)
                       bed_mass(i,j,1,nnew,ised)=dep_mass(i,ised)
                    END DO
                    ! ALA - average time and porosity
                    bed(i,j,2,iaged)=(bed(i,j,1,iaged)*cff1+            &
     &                      bed(i,j,2,iaged)*cff2)/(cff1+cff2)
                    bed(i,j,1,iaged)=time(ng)
                    bed(i,j,2,iporo)=(bed(i,j,1,iporo)*cff1+            &
     &                      bed(i,j,2,iporo)*cff2)/(cff1+cff2)
                    ! ALA CHECK WITH CRS POROSITY OF 1ST LAYER
                    bed(i,j,1,iporo)=bed(i,j,1,iporo)                    
                 ELSE
                 ! NBED=1
                 END IF
              ELSE
                ! Net deposition has occured, but no new bed layer was created 
             END IF
           ELSE
                ! Net erosion occurred
                bed(i,j,1,iaged)=time(ng)
                IF (Nbed.eq.2) THEN 
                 ! NBED=2
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                    DO ised=1,NST
                    DO ised=1,NST-9
                       bed_mass(i,j,2,nnew,ised)=                       &
     &                      MAX(bed_mass(i,j,2,nnew,ised)+              &
     &                      bed_mass(i,j,1,nnew,ised)-                  &
     &                      dep_mass(i,ised),0.0_r8)
                       bed_mass(i,j,1,nnew,ised)=dep_mass(i,ised)
                    END DO
                ELSEIF (Nbed.eq.1) THEN
                ! ALF NO NEED TO DO ANYTHING
                ELSE
                END IF
           END IF

          ! Recalculate thickness and fractions for all layers.
           DO k=1,Nbed
              cff3=0.0_r8
! SED_OPA - the first two classes are mud classes, hard-coded here.
!              DO ised=1,NST
              DO ised=1,NST-9
                 cff3=cff3+bed_mass(i,j,k,nnew,ised)
              END DO
              IF (cff3.eq.0.0_r8) THEN 
                 cff3=eps 
              END IF 
              bed(i,j,k,ithck)=0.0_r8
! SED_OPA - the first two classes are mud classes, hard-coded here.
!              DO ised=1,NST
              DO ised=1,NST-9
                 bed_frac(i,j,k,ised)=bed_mass(i,j,k,nnew,ised)/cff3
                 bed(i,j,k,ithck)=MAX(bed(i,j,k,ithck)+                 &
     &                         bed_mass(i,j,k,nnew,ised)/               &
     &                         (Srho(ised,ng)*                          &
     &                (1.0_r8-bed(i,j,k,iporo))),0.0_r8)
              END DO
           END DO
        END DO
      END DO J_LOOP2

      J_LOOP3 : DO j=Jstr,Jend
        DO i=Istr,Iend
          IF (bottom(i,j,iactv).gt.bed(i,j,1,ithck)) THEN
            IF (Nbed.eq.1) THEN
              bottom(i,j,iactv)=bed(i,j,1,ithck)
            ELSE
              thck_to_add=bottom(i,j,iactv)-bed(i,j,1,ithck)
              thck_avail=0.0_r8
              Ksed=1                                        ! initialize
              DO k=2,Nbed
                IF (thck_avail.lt.thck_to_add) THEN
                  thck_avail=thck_avail+bed(i,j,k,ithck)
                  Ksed=k
                END IF
              END DO
!
!  Catch here if there was not enough bed material.
!
              IF (thck_avail.lt.thck_to_add) THEN
                bottom(i,j,iactv)=bed(i,j,1,ithck)+thck_avail
                thck_to_add=thck_avail
              END IF
!
!  Update bed mass of top layer and fractional layer.
!
              cff2=MAX(thck_avail-thck_to_add,0.0_r8)/                  &
     &             MAX(bed(i,j,Ksed,ithck),eps)	        
! SED_OPA - the first two classes are mud classes, hard-coded here.
!              DO ised=1,NST
              DO ised=1,NST-9
                cff1=0.0_r8
                DO k=1,Ksed
                  cff1=cff1+bed_mass(i,j,k,nnew,ised)
                END DO
                cff3=cff2*bed_mass(i,j,Ksed,nnew,ised)
                bed_mass(i,j,1   ,nnew,ised)=cff1-cff3
                bed_mass(i,j,Ksed,nnew,ised)=cff3
              END DO
!
!  Update thickness of fractional layer ksource_sed.
!
              bed(i,j,Ksed,ithck)=MAX(thck_avail-thck_to_add,0.0_r8)
!
!  Update bed fraction of top layer.
!
              cff3=0.0_r8
! SED_OPA - the first two classes are mud classes, hard-coded here.
!              DO ised=1,NST
              DO ised=1,NST-9
                cff3=cff3+bed_mass(i,j,1,nnew,ised)
              END DO
              IF (cff3.eq.0.0_r8) THEN
                 cff3=eps
              END IF
! SED_OPA - the first two classes are mud classes, hard-coded here.
!              DO ised=1,NST
              DO ised=1,NST-9
                bed_frac(i,j,1,ised)=bed_mass(i,j,1,nnew,ised)/cff3
              END DO
!
!  Upate bed thickness of top layer.
!
              bed(i,j,1,ithck)=bottom(i,j,iactv)
!
!  Pull all layers closer to the surface.
!
              DO k=Ksed,Nbed
                ks=Ksed-2
                bed(i,j,k-ks,ithck)=bed(i,j,k,ithck)
                bed(i,j,k-ks,iporo)=bed(i,j,k,iporo)
                bed(i,j,k-ks,iaged)=bed(i,j,k,iaged)
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                DO ised=1,NST
                DO ised=1,NST-9
                  bed_frac(i,j,k-ks,ised)=bed_frac(i,j,k,ised)
                  bed_mass(i,j,k-ks,nnew,ised)=bed_mass(i,j,k,nnew,ised)
                END DO
              END DO
!
!  Add new layers onto the bottom. Split what was in the bottom layer to
!  fill these new empty cells. ("ks" is the number of new layers).
!
              ks=Ksed-2
              ! ALA CHECK WITH CRS about bed_frac 
              nnn=0
! SED_OPA - the first two classes are mud classes, hard-coded here.
!              DO ised=1,NST
              DO ised=1,NST-9
                 nlysm(ised)=newlayer_thick(ng)*REAL(ks+1,r8)*          &
     &                  (Srho(ised,ng)*                                 &
     &                  (1.0_r8-bed(i,j,Nbed-ks,iporo)))*               &
     &                  bed_frac(i,j,Nbed-ks,ised)
              		IF (ks.gt.0) THEN
                        IF (bed_mass(i,j,Nbed-ks,nnew,ised).gt.         &
     &                       nlysm(ised)) THEN
                           nnn=nnn+1
                           nlysm(ised)=                                 &
     &                           newlayer_thick(ng)*REAL(ks,r8)*        &
     &                          (Srho(ised,ng)*                         &
     &                          (1.0_r8-bed(i,j,Nbed-ks,iporo)))*       &
     &                          bed_frac(i,j,Nbed-ks,ised)
                        END IF
                    END IF
              END DO
! SED_OPA - the first two classes are mud classes, hard-coded here.
!              IF (nnn.eq.NST) THEN
              IF (nnn.eq.NST-9) THEN
                  bed(i,j,Nbed,ithck)=bed(i,j,Nbed-ks,ithck)-           &
     &                                newlayer_thick(ng)*REAL(ks,r8)
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                  DO ised=1,NST
                  DO ised=1,NST-9
                     bed_mass(i,j,Nbed,nnew,ised)=                      &
     &                  bed_mass(i,j,Nbed-ks,nnew,ised)-nlysm(ised)
                  END DO
                  DO k=Nbed-1,Nbed-ks,-1
                     bed(i,j,k,ithck)=newlayer_thick(ng)
                     bed(i,j,k,iaged)=bed(i,j,Nbed-ks,iaged)
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                     DO ised=1,NST
                     DO ised=1,NST-9
                        bed_frac(i,j,k,ised)=bed_frac(i,j,Nbed-ks,ised)
                        bed_mass(i,j,k,nnew,ised)=                      &
     &                           nlysm(ised)/REAL(ks,r8)
                     END DO
                  END DO
              ELSE
                 cff=1.0_r8/REAL(ks+1,r8)
                  DO k=Nbed,Nbed-ks,-1
                     bed(i,j,k,ithck)=bed(i,j,Nbed-ks,ithck)*cff
                     bed(i,j,k,iaged)=bed(i,j,Nbed-ks,iaged)
! SED_OPA - the first two classes are mud classes, hard-coded here.
!                     DO ised=1,NST
                     DO ised=1,NST-9
                        bed_frac(i,j,k,ised)=bed_frac(i,j,Nbed-ks,ised)
                        bed_mass(i,j,k,nnew,ised)=                      &
     &                             bed_mass(i,j,Nbed-ks,nnew,ised)*cff
                     END DO
                  END DO
              END IF
            END IF  ! Nbed > 1
          END IF  ! increase top bed layer
        END DO
      END DO J_LOOP3
!
!-----------------------------------------------------------------------
! Store old bed thickness.
!-----------------------------------------------------------------------
!
# if defined SED_MORPH
      DO j=JstrR,JendR
        DO i=IstrR,IendR
            bed_thick(i,j,nnew)=0.0_r8
            DO k=1,Nbed
              bed_thick(i,j,nnew)=bed_thick(i,j,nnew)+                  &
     &                            bed(i,j,k,ithck)
            END DO
          END DO
        END DO
        IF (EWperiodic(ng).or.NSperiodic(ng)) THEN
          CALL exchange_r2d_tile (ng, tile,                             &
     &                            LBi, UBi, LBj, UBj,                   &
     &                            bed_thick(:,:,nnew))
        END IF
# endif
!
!-----------------------------------------------------------------------
!  Apply periodic or gradient boundary conditions to property arrays.
!-----------------------------------------------------------------------
!
      DO ised=1,NST
        CALL bc_r3d_tile (ng, tile,                                     &
     &                    LBi, UBi, LBj, UBj, 1, Nbed,                  &
     &                    bed_frac(:,:,:,ised))
        CALL bc_r3d_tile (ng, tile,                                     &
     &                    LBi, UBi, LBj, UBj, 1, Nbed,                  &
     &                    bed_mass(:,:,:,nnew,ised))
      END DO
# ifdef DISTRIBUTE
      CALL mp_exchange4d (ng, tile, iNLM, 2,                            &
     &                    LBi, UBi, LBj, UBj, 1, Nbed, 1, NST,          &
     &                    NghostPoints,                                 &
     &                    EWperiodic(ng), NSperiodic(ng),               &
     &                    bed_frac,                                     &
     &                    bed_mass(:,:,:,nnew,:))
# endif

      DO i=1,MBEDP
        CALL bc_r3d_tile (ng, tile,                                     &
     &                    LBi, UBi, LBj, UBj, 1, Nbed,                  &
     &                    bed(:,:,:,i))
      END DO
# ifdef DISTRIBUTE
      CALL mp_exchange4d (ng, tile, iNLM, 1,                            &
     &                    LBi, UBi, LBj, UBj, 1, Nbed, 1, MBEDP,        &
     &                    NghostPoints,                                 &
     &                    EWperiodic(ng), NSperiodic(ng),               &
     &                    bed)
# endif

      RETURN
      END SUBROUTINE sed_bed_tile
#endif
      END MODULE sed_bed_mod2
