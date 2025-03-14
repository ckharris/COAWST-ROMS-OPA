      MODULE sed_opa_mod
!=======================================================================
!
      implicit none
      PRIVATE
      PUBLIC  :: sed_opamod
      CONTAINS
!
!***********************************************************************
      SUBROUTINE sed_opamod (ng, tile)
!***********************************************************************
!
      USE mod_param
      USE mod_forces
      USE mod_grid
      USE mod_mixing
      USE mod_ocean
      USE mod_stepping
      USE mod_bbl
      USE mod_sedopa
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng, tile
!
!  Local variable declarations.
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
      CALL wclock_on (ng, iNLM, 16)
      CALL sed_opamod_tile (ng, tile,                                   &
     &                       LBi, UBi, LBj, UBj, N(ng), NT(ng),         &

     &                       IminS, ImaxS, JminS, JmaxS,                &

     &                       nstp(ng), nnew(ng),                        &

     &                       GRID(ng) % z_r,                            &

     &                       GRID(ng) % z_w,                            &

     &                       GRID(ng) % Hz,                             &

     &                       BBL(ng) % bustrcwmax,                      &

     &                       BBL(ng) % bvstrcwmax,                      &

     &                       FORCES(ng) % Pwave_bot,                    &

     &                       FORCES(ng) % bustr,                        &

     &                       FORCES(ng) % bvstr,                        &

     &                       MIXING(ng) % Akt,                          &

     &                       MIXING(ng) % Akv,                          &

     &                       MIXING(ng) % Lscale,                       &

     &                       MIXING(ng) % gls,                          &

     &                       MIXING(ng) % tke,                          &

     &                       OCEAN(ng) % t,                             &

     &                       SEDOPA(ng) % f_mass,                       &

     &                       SEDOPA(ng) % f_diam,                       &

     &                       SEDOPA(ng) % oil_mass,                     &

     &                       SEDOPA(ng) % oil_diam,                     &

     &                       SEDOPA(ng) % opa_mass,                     &

     &                       SEDOPA(ng) % opa_diam)
      CALL wclock_off (ng, iNLM, 16)
      RETURN
      END SUBROUTINE sed_opamod
!***********************************************************************
      SUBROUTINE sed_opamod_tile (ng, tile,                             &

     &                             LBi, UBi, LBj, UBj, UBk, UBt,        &

     &                             IminS, ImaxS, JminS, JmaxS,          &

     &                             nstp, nnew, z_r, z_w, Hz,            &

     &                             bustrcwmax,                          &

     &                             bvstrcwmax,                          &

     &                             Pwave_bot,                           &

     &                             bustr,                               &

     &                             bvstr,                               &

     &                             Akt,Akv,Lscale,gls,tke,              &

     &                             t,                                   &

     &                             f_mass,f_diam,                       &

     &                             oil_mass,oil_diam,                   &

     &                             opa_mass,opa_diam)
!***********************************************************************
!
      USE mod_param
      USE mod_scalars
      USE mod_sediment
      USE mod_sedopa
      USE mod_oil_Eulvar
!
      implicit none
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng, tile
      integer, intent(in) :: LBi, UBi, LBj, UBj, UBk, UBt
      integer, intent(in) :: IminS, ImaxS, JminS, JmaxS
      integer, intent(in) :: nstp, nnew
      integer, parameter :: NSED=2
      integer, parameter :: NOIL=1
      integer, parameter :: NOPA=4
!
      real(r8), intent(in) :: z_r(LBi:,LBj:,:)
      real(r8), intent(in) :: z_w(LBi:,LBj:,0:)
      real(r8), intent(in) :: Hz(LBi:,LBj:,:)
      real(r8), intent(in) :: bustrcwmax(LBi:,LBj:)
      real(r8), intent(in) :: bvstrcwmax(LBi:,LBj:)
      real(r8), intent(in) :: Pwave_bot(LBi:,LBj:)
      real(r8), intent(in) :: bustr(LBi:,LBj:)
      real(r8), intent(in) :: bvstr(LBi:,LBj:)
      real(r8), intent(in) :: Akt(LBi:,LBj:,0:,:)
      real(r8), intent(in) :: Akv(LBi:,LBj:,0:)
      real(r8), intent(in) :: Lscale(LBi:,LBj:,0:)
      real(r8), intent(in) :: tke(LBi:,LBj:,0:,:)
      real(r8), intent(in) :: gls(LBi:,LBj:,0:,:)
      real(r8), intent(inout) :: t(LBi:,LBj:,:,:,:)
!  Imported variable declarations.
      real(r8), intent(inout)  :: f_mass(0:NSED+1)
      real(r8), intent(inout)  :: f_diam(NSED)
      real(r8) :: f_vol(NSED)
      real(r8) :: f_rho(NSED)
      real(r8), intent(inout)  :: oil_mass(NOIL)
      real(r8), intent(inout)  :: oil_diam(NOIL)
      real(r8) :: oil_vol(NOIL)
      real(r8) :: oil_rho(NOIL)
      real(r8), intent(inout)  :: opa_mass(0:NOPA+1)
      real(r8), intent(inout)  :: opa_diam(NOPA)
      real(r8) :: opa_vol(NOPA)
      real(r8) :: opa_rho(NOPA)
!
!  Local variable declarations.
! 
      integer :: i, indx, j, k, ks
      integer :: ised, ioil, iopa
      real(r8), parameter :: f_dp0  = 0.000001_r8
      real(r8), parameter :: f_nf   = 2.39_r8
      real(r8), parameter :: rhoref = 1025.0_r8
!
!  Variable declarations for floc model
!
      integer  :: iv1
      real(r8), dimension(IminS:ImaxS,N(ng)) :: Hz_inv
      real(r8) :: Gval,diss,mneg1,mneg2,mneg3,dttemp,f_dt
      real(r8) :: dt1,f_csum,epsilon8
      real(r8) :: cvtotmud,tke_av, gls_av, exp1, exp2, exp3,ustr2,effecz
      real(r8) :: cvtotoil,cvtotopa,totoilopa
      real(r8), dimension(IminS:ImaxS,N(ng),NSED) :: susmud
      real(r8), dimension(IminS:ImaxS,N(ng),NOPA) :: susopa
! susoil to track pure oil
      real(r8), dimension(IminS:ImaxS,N(ng),NOIL) :: susoil
! susoil2 to track oil in OPA
      real(r8), dimension(IminS:ImaxS,N(ng),NOPA) :: susoil2   
      real(r8),dimension(1:NSED)    :: cv_tmp1,NNin1,NNout1
      real(r8),dimension(1:NOIL)    :: cv_tmp2,NNin2,NNout2
      real(r8),dimension(1:NOPA)    :: cv_tmp3,NNin3,NNout3
      real(r8),dimension(1:NOPA)    :: cv_tmp4,NNin4,NNout4
!      real(r8),dimension(1:NOPA)    :: NNin4,NNout4
!  f_mneg_param : negative mass tolerated to avoid small sub time step
!  (g/l)
      real(r8), parameter :: f_mneg_param=0.000_r8
      real(r8), parameter :: f_clim=0.00001_r8
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
      epsilon8=epsilon(1.0)
!--------------------------------------------------------------------------
! * Executable part
!
      SEDOPA(ng)%opa_diam(1) = 0.256_r8
      SEDOPA(ng)%opa_diam(2) = 0.63_r8
      SEDOPA(ng)%opa_diam(3) = 1.024_r8
      SEDOPA(ng)%opa_diam(4) = 1.8_r8
!--------------------------------------------------
! floc characteristics
      DO ised=1,NSED
         f_diam(ised)=Sd50(ised,ng)
         f_vol(ised)=pi/6.0_r8*(f_diam(ised))**3.0_r8
         f_rho(ised)=rhoref+(2650.0_r8-rhoref)*                         &
     &     (f_dp0/f_diam(ised))**(3.0_r8-f_nf)
         f_mass(ised)=f_vol(ised)*(f_rho(ised)-rhoref)
      ENDDO
      f_mass(0) = 0.0_r8
      f_mass(NSED+1)=f_mass(NSED)*2.0_r8+1.0_r8
      IF (f_diam(1).eq.f_dp0)  THEN
          f_mass(1)=f_vol(1)*Srho(1,ng)
      ENDIF
!--------------------------------------------------
! OPA characteristics
     DO iopa=1,NOPA
        opa_diam(iopa) = opa_diam(iopa)*0.001_r8
        opa_vol(iopa) = pi/6.0_r8*(opa_diam(iopa))**3.0_r8  ! m-3
        opa_rho(iopa) = rhoref+(2650.0_r8-rhoref)*                      &
                        (f_dp0/opa_diam(iopa))**(3.0_r8-f_nf)
        opa_mass(iopa)=opa_vol(iopa)*(opa_rho(iopa)-rhoref)
!           write(*,*) 'OPA ', iopa, 'rho ',opa_rho(iopa)
!           write(*,*) 'OPA ', iopa, 'vol ',opa_vol(iopa)
!           write(*,*) 'OPA ', iopa, 'mass ',opa_mass(iopa)
!  settling velocity (Stokes law)
!           opa_ws(iopa) =
!           grav*(opa_rho(iopa)-rhoref)*opa_diam(iopa)**2.0/(18*0.001)
!           write(*,*) 'OPA ', iopa, 'ws ',opa_ws(iopa)
     ENDDO
     opa_mass(0) = 0.0_r8
     opa_mass(NOPA+1) = opa_mass(NOPA)*2.0_r8+1.0_r8
!----------------------------------------------------------------
      J_LOOP : DO j=Jstr,Jend
!
!  Extract mud variables from tracer arrays, place them into
!  scratch arrays, and restrict their values to be positive definite.
      DO k=1,N(ng)
        DO i=Istr,Iend
          Hz_inv(i,k)=1.0_r8/Hz(i,j,k)
          OIL3D(ng)%Doil(i,j,k) = 0.1_r8     ! mm
          if (k .le. 5) then 
            OIL3D(ng)%Coil(i,j,k,1) = 0.1_r8  ! kg m-3
          else
            OIL3D(ng)%Coil(i,j,k,1) = 0.05_r8  ! kg m-3 
          endif
          SEDOPA(ng)%oil_diam(1) = OIL3D(ng)%Doil(i,j,k)
          SEDOPA(ng)%oil_rho(1)  = 893.0_r8  ! kg m-3
! oil characteristics
          DO ioil=1,NOIL
!             write(*,*) 'oil_diam(1)=',oil_diam(ioil)
             SEDOPA(ng)%oil_diam(ioil) = SEDOPA(ng)%oil_diam(ioil)*0.001_r8
             SEDOPA(ng)%oil_vol(ioil) = pi/6.0_r8*(SEDOPA(ng)%oil_diam(ioil))**3.0_r8
             SEDOPA(ng)%oil_mass(ioil) = SEDOPA(ng)%oil_rho(ioil)*SEDOPA(ng)%oil_vol(ioil)
          ENDDO
!     WRITE(*,*) ' '
!     WRITE(*,*) 'NAT, NPT, NSED, NNS:', NAT,NPT,NSED,NNS
          CALL opamod_comp_coef(SEDOPA(ng) %  f_mass,                   &
             &                  SEDOPA(ng) %  f_diam,                   &
             &                  SEDOPA(ng) %  oil_mass,                 &
             &                  SEDOPA(ng) %  oil_diam,                 &
             &                  SEDOPA(ng) %  opa_mass,                 &
             &                  SEDOPA(ng) %  opa_diam,                 &
             &                  SEDOPA(ng) %  opa_g1,                   &
             &                  SEDOPA(ng) %  oil_l1,                   &
             &                  SEDOPA(ng) %  sed_l1,                   &
             &                  SEDOPA(ng) %  opa_coll_prob1,           &
             &                  SEDOPA(ng) %  opa_oil1,                 &
             &                  SEDOPA(ng) %  opa_g2,                   &
             &                  SEDOPA(ng) %  opa_l2,                   &
             &                  SEDOPA(ng) %  oil_l2,                   &
             &                  SEDOPA(ng) %  opa_coll_prob2,           &
             &                  SEDOPA(ng) %  opa_oil2,                 &
             &                  SEDOPA(ng) %  opa_g3,                   &
             &                  SEDOPA(ng) %  opa_l3,                   &
             &                  SEDOPA(ng) %  sed_l3,                   &
             &                  SEDOPA(ng) %  opa_coll_prob3,           &
             &                  SEDOPA(ng) %  sed_g4,                   &
             &                  SEDOPA(ng) %  sed_l4,                   &
             &                  SEDOPA(ng) %  opa_coll_prob4)
        END DO
      END DO
! MUD01,MUD02,OPA01,OPA02,OPA03,OPA04,OPA-OIL01,OPA-OIL02,OPA-OIL03,OPA-OIL04
      DO ised=1,NCS
         indx = idsed(ised)
         DO k=1,N(ng)
            DO i=Istr,Iend
!               susmud(i,k,ised)=MAX(t(i,j,k,nstp,indx),0.0_r8)
                if(indx .ge. 3 .and. indx .le. 4) then
!                   WRITE(*,*) 'indx2=',indx
                   susmud(i,k,indx-2)=t(i,j,k,nnew,indx)*Hz_inv(i,k)
                else if (indx .ge. 5 .and. indx .le. 8) then
!                   WRITE(*,*) 'indx3=',indx
                   susopa(i,k,indx-4)=t(i,j,k,nnew,indx)*Hz_inv(i,k)
                else 
                   susoil2(i,k,indx-8)=t(i,j,k,nnew,indx)*Hz_inv(i,k)
                endif
            ENDDO
         ENDDO
      ENDDO
! Get oil concentration from OIL3D%Coil
       DO ioil=1,NOIL
          DO k=1,N(ng)
             DO i=Istr,Iend
                susoil(i,k,ioil)=OIL3D(ng)%Coil(i,j,k,1)
             ENDDO
          ENDDO
       ENDDO
! min concentration below which flocculation processes are not
! calculated
!      f_clim=0.001_r8 
       exp1 = 3.0_r8+gls_p(ng)/gls_n(ng)
       exp2 = 1.5_r8+gls_m(ng)/gls_n(ng)
       exp3 = -1.0_r8/gls_n(ng)
       DO i=Istr,Iend
           DO k=1,N(ng)
              f_dt=dt(ng)
              dttemp=0.0_r8
             ! concentration of all mud classes in one grid cell
              cvtotmud=0.0_r8
              DO ised=1,NSED
                 cv_tmp1(ised)=susmud(i,k,ised)
                 cvtotmud=cvtotmud+cv_tmp1(ised)
                 NNin1(ised)=cv_tmp1(ised)/f_mass(ised)
!                 write(*,*) 'NNin1(ised)=',NNin1(ised)
              ENDDO
              DO ioil=1,NOIL
                 cv_tmp2(ioil)=susoil(i,k,ioil)
                 cvtotoil=cvtotoil+cv_tmp2(ioil)
                 NNin2(ioil) = cv_tmp2(ioil)/oil_mass(ioil)
!                 write(*,*) 'oil_mass(ioil)=',oil_mass(ioil)
!                 write(*,*) 'NNin2(ioil)=',NNin2(ioil)
              ENDDO
              DO iopa=1,NOPA
                 cv_tmp3(iopa)=susopa(i,k,iopa)
                 cvtotopa=cvtotopa+cv_tmp3(iopa)
                 NNin3(iopa) = cv_tmp3(iopa)/opa_mass(iopa)
                 write(*,*) 'Number of OPA ',iopa,'is ',NNin3(iopa)
! This is hard-coded because only considering one oil class  
                 cv_tmp4(iopa)=susoil2(i,k,iopa)
                 totoilopa = totoilopa + NNin4(iopa)*oil_mass(1)
                 NNin4(iopa) = cv_tmp4(iopa)/oil_mass(1)
              ENDDO
              DO iv1=1,NSED
                 IF (NNin1(iv1).lt.0.0_r8) THEN
                  WRITE(*,*) '***************************************'
                  WRITE(*,*) 'CAUTION, negative mass at cell i,j,k :',  &

     &                          i,j,k
                  WRITE(*,*) '***************************************'
                 ENDIF
              ENDDO
              IF (cvtotmud .gt. f_clim .and. cvtotoil .gt. f_clim) THEN
!
!ALA dissipation from turbulence clossure
!
                 IF (k.eq.1) THEN
                    tke_av = tke(i,j,k-1,nnew)
                    gls_av = gls(i,j,k-1,nnew)
                 ELSEIF (k.eq.N(ng)) THEN
                    tke_av = tke(i,j,k,nnew)
                    gls_av = gls(i,j,k,nnew)
                 ELSE
                    tke_av = 0.5_r8*(tke(i,j,k-1,nnew)+tke(i,j,k,nnew))
                    gls_av = 0.5_r8*(gls(i,j,k-1,nnew)+gls(i,j,k,nnew))
                ENDIF
!               exp1 = 3.0_r8+gls_p(ng)/gls_n(ng)
!               exp2 = 1.5_r8+gls_m(ng)/gls_n(ng)
!               exp3 = -1.0_r8/gls_n(ng)
                diss = gls_cmu0(ng)**exp1*tke_av**exp2*gls_av**exp3
           CALL flocmod_comp_g(k,i,j,Gval,diss,ng)
           DO WHILE (dttemp .le. dt(ng))
             CALL opamod_comp_fsd(NNin1,NNin2,NNin3,NNin4,              &
                        NNout1,NNout2,NNout3,NNout4,Gval,f_dt,ng)
             CALL opamod_mass_control(NNout1,NNout2,NNout3,mneg1,mneg2,mneg3,ng)
             IF (MIN(mneg1,mneg2,mneg3) .gt. f_mneg_param) THEN
                DO WHILE (MIN(mneg1,mneg2,mneg3) .gt. f_mneg_param)
                  f_dt=MIN(f_dt/2.0_r8,dt(ng)-dttemp)
                  IF (f_dt.lt.epsilon8) THEN
                     CALL opamod_mass_redistribute(NNin1,NNin2,NNin3,ng)
                     dttemp=dt(ng)
                     exit
                  ENDIF
                  CALL opamod_comp_fsd( NNin1,NNin2,NNin3,NNin4,        &
                                   NNout1,NNout2,NNout3,NNout4,Gval,f_dt,ng)
                  CALL opamod_mass_control(NNout1,NNout2,NNout3,mneg1,mneg2,mneg3,ng)
                ENDDO
             ELSE
                IF (f_dt.lt.dt(ng)) THEN
                  DO WHILE (MIN(mneg1,mneg2,mneg3) .lt.f_mneg_param)
                     IF (dttemp+f_dt .eq. dt(ng)) THEN
                        CALL opamod_comp_fsd(NNin1,NNin2,NNin3,NNin4,   &
                                   NNout1,NNout2,NNout3,NNout4,Gval,f_dt,ng)
                        exit
                     ELSE
                        dt1=f_dt
                        f_dt=MIN(2.0_r8*f_dt,dt(ng)-dttemp)
                        CALL opamod_comp_fsd(NNin1,NNin2,NNin3,NNin4,   &
                                     NNout1,NNout2,NNout3,NNout4,Gval,f_dt,ng)
                        CALL opamod_mass_control(NNout1,NNout2,NNout3,mneg1,mneg2,mneg3,ng)
                        IF (MIN(mneg1,mneg2,mneg3) .gt. f_mneg_param) THEN
                          f_dt=dt1
                          CALL opamod_comp_fsd(NNin1,NNin2,NNin3,NNin4, &
                                     NNout1,NNout2,NNout3,NNout4,Gval,f_dt,ng)
                                exit
                        ENDIF
                     ENDIF 
                  ENDDO
                ENDIF 
             ENDIF
             dttemp = dttemp + f_dt
             NNin1 = NNout1
             NNin2 = NNout2
             NNin3 = NNout3
             NNin4 = NNout4
             CALL opamod_mass_redistribute(NNin1,NNin2,NNin3,ng)
!             WRITE(*,*)'NNin1=',NNin1
!             WRITE(*,*)'NNin2=',NNin2
!             WRITE(*,*)'NNin3=',NNin3
             if (dttemp .eq. dt(ng)) exit
           ENDDO !loop on full dt
           ENDIF
           do ised=1,NSED
              susmud(i,k,ised) = NNin1(ised)*f_mass(ised)
!              WRITE(*,*) 'susmud=',susmud(i,k,ised)
           end do
           do iopa=1,NOPA
              susopa(i,k,iopa) = NNin3(iopa)*opa_mass(iopa)
              susoil2(i,k,iopa) = NNin4(iopa)*oil_mass(1)
!              WRITE(*,*) 'susopa=',susopa(i,k,iopa)
           end do
           do ioil=1,NOIL
              susoil(i,k,ioil) = NNin2(ioil)*oil_mass(ioil)
!              WRITE(*,*) 'susoil=',susoil(i,k,ioil)
           end do
           ENDDO
         ENDDO
!
!-----------------------------------------------------------------------
!  Update global tracer variables.
!-----------------------------------------------------------------------
!
      DO ised=1,NCS
         indx = idsed(ised)
          DO k=1,N(ng)
            DO i=Istr,Iend
             if (indx .ge. 3 .and. indx .le. 4) then
               t(i,j,k,nnew,indx)=susmud(i,k,indx-2)*Hz(i,j,k)
!               WRITE(*,*) 'susmud=',t(i,j,k,nnew,indx) 
             else if (indx .ge. 5 .and. indx .le. 8) then
               t(i,j,k,nnew,indx)=susopa(i,k,indx-4)*Hz(i,j,k)
!               WRITE(*,*) 'susopa=',t(i,j,k,nnew,indx) 
!             else if (indx .eq. 9) then
!               t(i,j,k,nnew,indx)=susoil(i,k,indx-8)*Hz(i,j,k)
             else 
               t(i,j,k,nnew,indx)=susoil2(i,k,indx-8)*Hz(i,j,k)
!               WRITE(*,*) 'susooil=',t(i,j,k,nnew,indx) 
             endif
            ENDDO
         ENDDO
      ENDDO
      DO ioil=1,NOIL
         DO k=1,N(ng)
            DO i=Istr,Iend
               OIL3D(ng)%Coil(i,j,k,1) = susoil(i,k,ioil)
            ENDDO
         ENDDO
      ENDDO
      END DO J_LOOP
      END SUBROUTINE sed_opamod_tile
!==========================================================================
!-----------------------------------------------------------------------
! Calculate aggregation coefficients
!-----------------------------------------------------------------------
      SUBROUTINE opamod_comp_coef(f_mass,f_diam,                        &
     &                            oil_mass,oil_diam,                    &
     &                            opa_mass,opa_diam,                    &
     &           opa_g1,oil_l1,sed_l1,opa_coll_prob1,opa_oil1,          &
     &           opa_g2,opa_l2,oil_l2,opa_coll_prob2,opa_oil2,          &
     &           opa_g3,opa_l3,sed_l3,opa_coll_prob3,                   &
     &           sed_g4,sed_l4,opa_coll_prob4)
!***********************************************************************
      USE mod_param
      USE mod_ncparam
      USE mod_scalars
      USE mod_sediment
      USE mod_sedopa
      implicit none
!  Imported variable declarations.
!      integer, intent(in) :: ng, tile
      integer, parameter  :: NSED=2
      integer, parameter  :: NOIL=1
      integer, parameter  :: NOPA=4
      real(r8), intent(inout)  :: f_mass(0:NSED+1)
      real(r8), intent(inout)  :: f_diam(NSED)
      real(r8) :: f_vol(NSED)
      real(r8) :: f_rho(NSED)
      real(r8), intent(inout)  :: oil_mass(NOIL)
      real(r8), intent(inout)  :: oil_diam(NOIL)
      real(r8) :: oil_vol(NOIL)
      real(r8) :: oil_rho(NOIL)
      real(r8), intent(inout)  :: opa_mass(0:NOPA+1)
      real(r8), intent(inout)  :: opa_diam(NOPA)
      real(r8) :: opa_vol(NOPA)
      real(r8) :: opa_rho(NOPA)
      real(r8), intent(inout)  :: opa_g1(NOIL,NSED,NOPA)
      real(r8), intent(inout)  :: oil_l1(NOIL,NSED)
      real(r8), intent(inout)  :: sed_l1(NOIL,NSED)
      real(r8), intent(inout)  :: opa_coll_prob1(NOIL,NSED)
      real(r8), intent(inout)  :: opa_oil1(NOIL,NSED,NOPA)
      real(r8), intent(inout)  :: opa_g2(NOIL,NOPA,NOPA)
      real(r8), intent(inout)  :: opa_l2(NOIL,NOPA)
      real(r8), intent(inout)  :: oil_l2(NOIL,NOPA)
      real(r8), intent(inout)  :: opa_coll_prob2(NOIL,NOPA)
      real(r8), intent(inout)  :: opa_oil2(NOIL,NOPA,NOPA)
      real(r8), intent(inout)  :: opa_g3(NSED,NOPA,NOPA)
      real(r8), intent(inout)  :: opa_l3(NSED,NOPA)
      real(r8), intent(inout)  :: sed_l3(NSED,NOPA)
      real(r8), intent(inout)  :: opa_coll_prob3(NSED,NOPA)
      real(r8), intent(inout)  :: sed_g4(NSED,NSED,NSED)
      real(r8), intent(inout)  :: sed_l4(NSED,NSED)
      real(r8), intent(inout)  :: opa_coll_prob4(NSED,NSED)
!  Local variable declarations.
!
      real(r8), parameter :: f_dp0  = 0.000001_r8
      real(r8), parameter :: f_nf   = 2.39_r8
      real(r8), parameter :: grav   = 9.81_r8
!      real(r8), parameter :: pi     = 3.14159_r8
!      real(r8), parameter :: Gval   = 8.0_r8
      real(r8), parameter :: rhoref = 1025.0_r8
      real(r8), parameter :: opa_alpha1=0.55_r8    ! oil-sed
      real(r8), parameter :: opa_alpha2=0.55_r8    ! oil-opa
      real(r8), parameter :: opa_alpha3=0.35_r8    ! sed-opa
      real(r8), parameter :: opa_alpha4=0.35_r8    ! sed-sed
      real(r8), parameter :: IniVal = -999.0_r8
!      real(r8) :: f_clim
      real(r8) :: f_weight,mult,tmp,tmp2
      integer  :: iv1,iv2,iv3,iv,itrc
      integer  :: ioil,iopa,ised
! compute collision probability
! OIL-
      DO iv1=1,NOIL
        DO iv2=1,NSED
          opa_coll_prob1(iv1,iv2)=1.0_r8/6.0_r8*(oil_diam(iv1)+         &
                                    f_diam(iv2))**3.0_r8
        ENDDO
      ENDDO
!  OIL-OPA
      DO iv1=1,NOIL
        DO iv2=1,NOPA
          opa_coll_prob2(iv1,iv2)=1.0_r8/6.0_r8*(oil_diam(iv1)+         &
                                    opa_diam(iv2))**3.0_r8
        ENDDO
      ENDDO
! SED-OPA
      DO iv1=1,NSED
        DO iv2=1,NOPA
          opa_coll_prob3(iv1,iv2)=1.0_r8/6.0_r8*(f_diam(iv1)+           &
                                    opa_diam(iv2))**3.0_r8
        ENDDO
      ENDDO
! SED-SED
      DO iv1=1,NSED
        DO iv2=1,NSED
         opa_coll_prob4(iv1,iv2)=1.0_r8/6.0_r8*(f_diam(iv1) +           &
                                    f_diam(iv2))**3.0_r8
        ENDDO
      ENDDO
!********************************************************************************
! Shear agregation : GAIN (opa_g1, opa_g2, opa_g3)
!********************************************************************************
! OILSED
      DO iv1=1,NOPA
       DO iv2=1,NOIL
        DO iv3=1,NSED
!           tmp = f_mass(iv3)/(oil_mass(iv2) + f_mass(iv3))
           tmp = oil_mass(iv2) + f_mass(iv3)
! opa_mass(0:NOPA+1)
           IF(tmp .gt. opa_mass(iv1-1) .and. (tmp .le. opa_mass(iv1))) THEN
              f_weight=(tmp-opa_mass(iv1-1))/(opa_mass(iv1)-opa_mass(iv1-1))
           ELSEIF (tmp .gt. opa_mass(iv1) .and.(tmp .lt. opa_mass(iv1+1))) THEN
              IF (iv1 .eq. NOPA) THEN
                 f_weight=1.0_r8
              ELSE
                 f_weight=1.0_r8-(tmp - opa_mass(iv1))/(opa_mass(iv1+1)-opa_mass(iv1))
              ENDIF
           ELSE
              f_weight=0.0_r8
           ENDIF
! opa_alpha1 (oil-sediment)
           opa_g1(iv2,iv3,iv1)=f_weight*opa_alpha1*                     &
                 opa_coll_prob1(iv2,iv3)*tmp/opa_mass(iv1)
! track oil in OPA (oil-sed)
! oil loss equals to oil in OPA
           opa_oil1(iv2,iv3,iv1) = f_weight*opa_alpha1*                 &
                 opa_coll_prob1(iv2,iv3)  !*oil_mass(iv2)/opa_mass(iv1)
        ENDDO
       ENDDO
      ENDDO
!OILOPA
      DO iv1=1,NOPA
       DO iv2=1,NOIL
! OPA (m, iv1) gain from aggregation from smaller OPA(1:iv1) with oil
!         DO iv3=1,iv1
         DO iv3=1,iv1
!           tmp = opa_mass(iv3)*xs(iv3)/(oil_mass(iv2) + opa_mass(iv3))
           tmp =oil_mass(iv2) + opa_mass(iv3)
! opa_mass(0:NOPA+1)
           IF(tmp .gt.opa_mass(iv1-1) .and. tmp .le. opa_mass(iv1)) THEN
                  f_weight=(tmp-opa_mass(iv1-1))/(opa_mass(iv1)-opa_mass(iv1-1))
           ELSEIF (tmp .gt. opa_mass(iv1) .and. tmp .lt. opa_mass(iv1+1)) THEN
              IF (iv1 .eq. NOPA) THEN
                 f_weight=1.0_r8
              ELSE
                 f_weight=1.0_r8-(tmp - opa_mass(iv1))/(opa_mass(iv1+1)-opa_mass(iv1))
              ENDIF
           ELSE
              f_weight=0.0_r8
           ENDIF
! opa_alpha2 (oil-opa)
           opa_g2(iv2,iv3,iv1)=f_weight*opa_alpha2*                     &
                 opa_coll_prob2(iv2,iv3)*tmp/opa_mass(iv1)
! track oil in OPA (oil-OPA)
           opa_oil2(iv2,iv3,iv1) = f_weight*opa_alpha2*                 &
                 opa_coll_prob2(iv2,iv3)
        ENDDO
       ENDDO
      ENDDO
!SEDOPA
      DO iv1=1,NOPA
       DO iv2=1,NSED
! OPA(m, iv1) gain from smaller opa (1:iv1) with sediment
         DO iv3=1,NOPA
!           tmp = (f_mass(iv2) + opa_mass(iv3)*xs(iv3))/(f_mass(iv2) +
!           opa_mass(iv3))
!           write(*,*) 'tmp=',tmp
           tmp = f_mass(iv2) + opa_mass(iv3)
! opa_mass(0:NOPA+1)
           IF(tmp .gt. opa_mass(iv1-1) .and. tmp .le. opa_mass(iv1)) THEN
              f_weight=(tmp-opa_mass(iv1-1))/(opa_mass(iv1)-opa_mass(iv1-1))
           ELSEIF (tmp .gt. opa_mass(iv1) .and.tmp .lt. opa_mass(iv1+1)) THEN
              IF (iv1 .eq. NOPA) THEN
                 f_weight=1.0_r8
              ELSE
                 f_weight=1.0_r8-(tmp - opa_mass(iv1))/(opa_mass(iv1+1)-opa_mass(iv1))
              ENDIF
           ELSE
              f_weight=0.0_r8
           ENDIF
! opa_alpha3 (sed-opa)
           opa_g3(iv2,iv3,iv1)=f_weight*opa_alpha3*                     &
                 opa_coll_prob3(iv2,iv3)*tmp/opa_mass(iv1)
        ENDDO
       ENDDO
      ENDDO
! SED-SED
      DO iv1=1,NSED
        DO iv2=1,NSED
          DO iv3=iv2,NSED
            tmp = f_mass(iv2) + f_mass(iv3)
            IF((tmp .gt. f_mass(iv1-1) .and. (tmp .le. f_mass(iv1)))) THEN
              f_weight=(tmp-f_mass(iv1-1))/(f_mass(iv1)-f_mass(iv1-1))
            ELSEIF ((tmp .gt. f_mass(iv1) .and.(tmp .lt. f_mass(iv1+1)))) THEN
              IF (iv1 .eq. NSED) THEN
                 f_weight=1.0_r8
              ELSE
                 f_weight=1.0_r8-(tmp - f_mass(iv1))/(f_mass(iv1+1)-f_mass(iv1))
              ENDIF
            ELSE
              f_weight=0.0_r8
            ENDIF
! opa_alpha4 (sed-sed)
           sed_g4(iv2,iv3,iv1)=f_weight*opa_alpha4*                     &
                               opa_coll_prob4(iv2,iv3)*tmp/f_mass(iv1)
!           print*,'kernel,sed_g4',sed_g4(iv2,iv3,iv1)
          ENDDO
        ENDDO
      ENDDO
!********************************************************************************
!  Shear agregation : LOSS : opa_l2,opa_l3,oil_l1,oil_l2,sed_l1,sed_l3
!********************************************************************************
!OILSED
      DO iv1=1,NOIL
       DO iv2=1,NSED
        oil_l1(iv1,iv2)=opa_alpha1*opa_coll_prob1(iv1,iv2)
        sed_l1(iv1,iv2)=opa_alpha1*opa_coll_prob1(iv1,iv2)
       ENDDO
      ENDDO
!OILOPA
      DO iv1=1,NOIL
       DO iv2=1,NOPA
        oil_l2(iv1,iv2)=opa_alpha2*opa_coll_prob2(iv1,iv2)
        opa_l2(iv1,iv2)=opa_alpha2*opa_coll_prob2(iv1,iv2)
       ENDDO
      ENDDO
!SEDOPA
      DO iv1=1,NSED
       DO iv2=1,NOPA
        sed_l3(iv1,iv2)=opa_alpha3*opa_coll_prob3(iv1,iv2)
        opa_l3(iv1,iv2)=opa_alpha3*opa_coll_prob3(iv1,iv2)
       ENDDO
      ENDDO
!SEDFSED
      DO iv1=1,NSED
        DO iv2=1,NSED 
         if(iv2 .eq. iv1) then 
           mult = 2.0_r8
         else
           mult = 1.0_r8
         endif
         sed_l4(iv2,iv1) = mult*opa_alpha4*opa_coll_prob4(iv2,iv1)
        ENDDO
      ENDDO
!      write(*,*) 'Sum of kernal coefficients:'
!      write(*,*) 'opa_coll_prob1',sum(opa_coll_prob1)
!      write(*,*) 'opa_coll_prob2',sum(opa_coll_prob2)
!      write(*,*) 'opa_coll_prob3',sum(opa_coll_prob3)
!      write(*,*) 'opa_coll_prob4',sum(opa_coll_prob4)
!      write(*,*) 'opa_g1',sum(opa_g1)
!      write(*,*) 'opa_g2',sum(opa_g2)
!      write(*,*) 'opa_g3',sum(opa_g3)
!      write(*,*) 'opa_l2',sum(opa_l2)
!      write(*,*) 'opa_l3',sum(opa_l3)
!      write(*,*) 'oil_l1',sum(oil_l1)
!      write(*,*) 'oil_l2',sum(oil_l2)
!      write(*,*) 'sed_l1',sum(sed_l1)
!      write(*,*) 'sed_l3',sum(sed_l3)
!      write(*,*) 'sed_g4',sum(sed_g4)
!      write(*,*) 'sed_l4',sum(sed_l4)
!      write(*,*) 'opa_oil1',sum(opa_oil1)
!      write(*,*) 'opa_oil2',sum(opa_oil2)
!      write(*,*) '***END OPAMOD COEFF CALCULATION ***'
     RETURN
      END SUBROUTINE opamod_comp_coef
!==========================================================================
      SUBROUTINE opamod_comp_fsd(NNin1,NNin2,NNin3,NNin4,NNout1,NNout2,NNout3,NNout4,Gval,f_dt,ng)
      USE mod_param
      USE mod_scalars
      USE mod_sedopa
!
      implicit none
      integer, intent(in) :: ng
      real(r8),intent(in) :: Gval,f_dt
      integer,parameter :: NSED = 2
      integer,parameter :: NOIL = 1
      integer,parameter :: NOPA = 4
      real(r8),dimension(1:NSED) :: NNin1
      real(r8),dimension(1:NSED) :: NNout1
      real(r8),dimension(1:NOIL) :: NNin2
      real(r8),dimension(1:NOIL) :: NNout2
      real(r8),dimension(1:NOPA) :: NNin3
      real(r8),dimension(1:NOPA) :: NNout3
      real(r8),dimension(1:NOPA) :: NNin4
      real(r8),dimension(1:NOPA) :: NNout4
      !! * Local declarations
      integer      :: iv1,iv2,iv3
      real(r8) :: tmp_opa_g1,tmp_opa_g2,tmp_opa_g3,tmp_opa_l2,tmp_opa_l3
      real(r8) :: tmp_oil_l1,tmp_oil_l2,tmp_sed_l1,tmp_sed_l3
      real(r8) :: tmp_sed_g4,tmp_sed_l4
! variables used to track oil in OPA
      real(r8) :: tmp_opa_oil1,tmp_opa_oil2
      real(r8),dimension(1:NOIL,1:NSED,1:NOPA)     :: opa_g1_tmp
      real(r8),dimension(1:NOIL,1:NSED)            :: oil_l1_tmp
      real(r8),dimension(1:NSED,1:NOIL)            :: sed_l1_tmp
      real(r8),dimension(1:NOIL,1:NOPA,1:NOPA)    :: opa_g2_tmp
      real(r8),dimension(1:NOIL,1:NOPA)           :: oil_l2_tmp
      real(r8),dimension(1:NOIL,1:NOPA)           :: opa_l2_tmp
      real(r8),dimension(1:NSED,1:NOPA,1:NOPA)     :: opa_g3_tmp
      real(r8),dimension(1:NSED,1:NOPA)            :: sed_l3_tmp
      real(r8),dimension(1:NSED,1:NOPA)            :: opa_l3_tmp
      real(r8),dimension(1:NSED,1:NSED,1:NSED)       :: sed_g4_tmp
      real(r8),dimension(1:NSED,1:NSED)             :: sed_l4_tmp
! variables used to track oil in OPA
      real(r8),dimension(1:NOIL,1:NSED,1:NOPA)     :: opa_oil1_tmp
      real(r8),dimension(1:NOIL,1:NOPA,1:NOPA)    :: opa_oil2_tmp
!--------------------------------------------------------------------------
      tmp_opa_g1 = 0.0_r8
      tmp_opa_g2 = 0.0_r8
      tmp_opa_g3 = 0.0_r8
      tmp_oil_l1 = 0.0_r8
      tmp_oil_l2 = 0.0_r8
      tmp_sed_l1 = 0.0_r8
      tmp_sed_l3 = 0.0_r8
      tmp_opa_l2 = 0.0_r8
      tmp_opa_l3 = 0.0_r8
      tmp_sed_g4 = 0.0_r8
      tmp_sed_l4 = 0.0_r8
      opa_g1_tmp(1:NOIL,1:NSED,1:NOPA)=0.0_r8
      oil_l1_tmp(1:NOIL,1:NSED)=0.0_r8
      sed_l1_tmp(1:NSED,1:NOIL)=0.0_r8
      opa_g2_tmp(1:NOIL,1:NOPA,1:NOPA)=0.0_r8
      oil_l2_tmp(1:NOIL,1:NOPA)=0.0_r8
      opa_l2_tmp(1:NOIL,1:NOPA)=0.0_r8
      opa_g3_tmp(1:NSED,1:NOPA,1:NOPA)=0.0_r8
      opa_l3_tmp(1:NSED,1:NOPA)=0.0_r8
      sed_l3_tmp(1:NSED,1:NOPA)=0.0_r8
      sed_g4_tmp(1:NSED,1:NSED,1:NSED)=0.0_r8
      sed_l4_tmp(1:NSED,1:NSED)=0.0_r8
! track oil in OPA
      tmp_opa_oil1 = 0.0_r8
      tmp_opa_oil2 = 0.0_r8
      opa_oil1_tmp(1:NOIL,1:NSED,1:NOPA)=0.0_r8
      opa_oil2_tmp(1:NOIL,1:NOPA,1:NOPA)=0.0_r8
! NNin1 -sediment, NNin2 - oil, NNin3 - opa
! NNout1 -sediment, NNout2 - oil, NNout3 - opa
!Calculate OPA 
      DO iv1=1,NOPA
!OIL- (opa_g1)
          DO iv2=1,NOIL
            DO iv3=1,NSED
              opa_g1_tmp(iv2,iv3,iv1)=opa_g1_tmp(iv2,iv3,iv1)+          &
      &            SEDOPA(ng)%opa_g1(iv2,iv3,iv1)*Gval
              tmp_opa_g1=tmp_opa_g1 +                                   &
      &            NNin2(iv2)*opa_g1_tmp(iv2,iv3,iv1)*NNin1(iv3)
! track oil in OPA (oil-sed)
              opa_oil1_tmp(iv2,iv3,iv1) = opa_oil1_tmp(iv2,iv3,iv1) +   &
      &            SEDOPA(ng)%opa_oil1(iv2,iv3,iv1)*Gval
              tmp_opa_oil1 = tmp_opa_oil1 +                             &
      &            opa_oil1_tmp(iv2,iv3,iv1)*NNin1(iv3)
            ENDDO
              tmp_opa_oil1 = tmp_opa_oil1*NNin2(iv2)
          ENDDO
! OIL-OPA
          DO iv2=1,NOIL
            DO iv3=1,NOPA
               opa_g2_tmp(iv2,iv3,iv1)=opa_g2_tmp(iv2,iv3,iv1)+         &
      &            SEDOPA(ng)%opa_g2(iv2,iv3,iv1)*Gval
               tmp_opa_g2=tmp_opa_g2 +                                  &
      &            NNin2(iv2)*opa_g2_tmp(iv2,iv3,iv1)*NNin3(iv3)
! track oil in OPA (oil-OPA)
               opa_oil2_tmp(iv2,iv3,iv1) = opa_oil2_tmp(iv2,iv3,iv1)    &
                  + SEDOPA(ng)%opa_oil2(iv2,iv3,iv1)*Gval
               tmp_opa_oil2 = tmp_opa_oil2                              &
                  + opa_oil2_tmp(iv2,iv3,iv1)*NNin3(iv3)
            ENDDO
            opa_l2_tmp(iv2,iv1) = opa_l2_tmp(iv2,iv1)+                  &
                   SEDOPA(ng)%opa_l2(iv2,iv1)*Gval
            tmp_opa_l2= tmp_opa_l2 + opa_l2_tmp(iv2,iv1)*NNin2(iv2)
! track oil in OPA (oil-OPA)
            tmp_opa_oil2 = tmp_opa_oil2*NNin2(iv2)
          ENDDO
          tmp_opa_l2 = tmp_opa_l2*NNin3(iv1)
! -OPA
          DO iv2=1,NSED
            DO iv3=1,NOPA
               opa_g3_tmp(iv2,iv3,iv1)=opa_g3_tmp(iv2,iv3,iv1)+         &
      &            SEDOPA(ng)%opa_g3(iv2,iv3,iv1)*Gval
               tmp_opa_g3=tmp_opa_g3+                                   &
      &            (NNin1(iv2)*(opa_g3_tmp(iv2,iv3,iv1))*NNin3(iv3))
            ENDDO
            opa_l3_tmp(iv2,iv1) = opa_l3_tmp(iv2,iv1) +                 &
                    SEDOPA(ng)%opa_l3(iv2,iv1)*Gval
            tmp_opa_l3 = tmp_opa_l3 + opa_l3_tmp(iv2,iv1)*NNin1(iv2)
          ENDDO
            tmp_opa_l3 = tmp_opa_l3*NNin3(iv1)
!        #endif
       NNout3(iv1)=NNin3(iv1)+ f_dt*(tmp_opa_g1+tmp_opa_g2+             &
               tmp_opa_g3 - (tmp_opa_l2+tmp_opa_l3))
! track oil in OPA
       NNout4(iv1) = NNin4(iv1) + f_dt*(tmp_opa_oil1+tmp_opa_oil2)
      tmp_opa_g1 = 0.0_r8
      tmp_opa_g2 = 0.0_r8
      tmp_opa_g3 = 0.0_r8
      tmp_opa_l2 = 0.0_r8
      tmp_opa_l3 = 0.0_r8
! track oil in OPA
      tmp_opa_oil1 = 0.0_r8
      tmp_opa_oil2 = 0.0_r8
      ENDDO
!Calculate sediment 
      DO iv1=1,NSED
!OIL-  (loss)
         DO iv2=1,NOIL
            sed_l1_tmp(iv1,iv2) = sed_l1_tmp(iv1,iv2) +                 &
      &                            SEDOPA(ng)%sed_l1(iv2,iv1)*Gval
            tmp_sed_l1 = tmp_sed_l1 + sed_l1_tmp(iv1,iv2)*NNin2(iv2)
         ENDDO
         tmp_sed_l1 = tmp_sed_l1*NNin1(iv1)
! -OPA (LOSS)
          DO iv2=1,NOPA
            sed_l3_tmp(iv1,iv2) = sed_l3_tmp(iv1,iv2) +                 &
      &                            SEDOPA(ng)%sed_l3(iv1,iv2)*Gval
            tmp_sed_l3 = tmp_sed_l3 + sed_l3_tmp(iv1,iv2)*NNin3(iv2)
          ENDDO
          tmp_sed_l3 = tmp_sed_l3*NNin1(iv1)
! SED-SED (gain from aggregtion from smaller sediment)
         DO iv2=1,NSED
           DO iv3=1,NSED
             sed_g4_tmp(iv2,iv3,iv1) = sed_g4_tmp(iv2,iv3,iv1)+         &
                   SEDOPA(ng)%sed_g4(iv2,iv3,iv1)*Gval
             tmp_sed_g4 = tmp_sed_g4 +                                  &
             NNin1(iv3)*sed_g4_tmp(iv2,iv3,iv1)*NNin1(iv2)
           ENDDO
           sed_l4_tmp(iv2,iv1) = sed_l4_tmp(iv2,iv1)+                   &
                                    SEDOPA(ng)%sed_l4(iv2,iv1)*Gval
           tmp_sed_l4 = tmp_sed_l4 + sed_l4_tmp(iv2,iv1)*NNin1(iv2)
         ENDDO
        tmp_sed_l4 = tmp_sed_l4*NNin1(iv1)
!        NNout1(iv1) = NNin1(iv1) - f_dt*(tmp_sed_l1 + tmp_sed_l3)
        NNout1(iv1) = NNin1(iv1) + f_dt*(tmp_sed_g4 - tmp_sed_l1 -      &
                      tmp_sed_l3-tmp_sed_l4)
      tmp_sed_l1 = 0.0_r8
      tmp_sed_l3 = 0.0_r8
      tmp_sed_g4 = 0.0_r8
      tmp_sed_l4 = 0.0_r8
      ENDDO
!Calculate oil
      DO iv1=1,NOIL
! OIL-
            DO iv2=1,NSED
               oil_l1_tmp(iv1,iv2) = oil_l1_tmp(iv1,iv2) +              &
                                  SEDOPA(ng)%oil_l1(iv1,iv2)*Gval
               tmp_oil_l1 = tmp_oil_l1 + oil_l1_tmp(iv1,iv2)*NNin1(iv2)
            ENDDO
            tmp_oil_l1 = tmp_oil_l1*NNin2(iv1)
! OIL-OPA
            DO iv2=1,NOPA
               oil_l2_tmp(iv1,iv2) = oil_l2_tmp(iv1,iv2) +              &
                                   SEDOPA(ng)%oil_l2(iv1,iv2)*Gval
               tmp_oil_l2 = tmp_oil_l2 + oil_l2_tmp(iv1,iv2)*NNin3(iv2)
            ENDDO
            tmp_oil_l2 = tmp_oil_l2*NNin2(iv1)
         NNout2(iv1) = NNin2(iv1) - f_dt*(tmp_oil_l1 + tmp_oil_l2)
         !NNout2(iv1) =   f_dt*(tmp_oil_l1 + tmp_oil_l2)
      tmp_oil_l1 = 0.0_r8
      tmp_oil_l2 = 0.0_r8
      END DO
      RETURN
      END SUBROUTINE opamod_comp_fsd
!===========================================================================
      SUBROUTINE opamod_mass_control(NN1,NN2,NN3,mneg1,mneg2,mneg3,ng)
      USE mod_sedopa
      USE mod_param
      USE mod_scalars
      implicit none
      integer, intent(in) :: ng
! Local declarations
      integer,parameter :: NSED=2
      integer,parameter :: NOIL=1
      integer,parameter :: NOPA=4
      integer      :: iv1
      real(r8)     :: mneg1,mneg2,mneg3
      real(r8),dimension(1:NSED)     :: NN1
      real(r8),dimension(1:NOIL)     :: NN2
      real(r8),dimension(1:NOPA)     :: NN3
!--------------------------------------------------------------------------
! * Executable part
      mneg1=0.0_r8
      mneg2=0.0_r8
      mneg3=0.0_r8
      DO iv1=1,NSED
       IF (NN1(iv1).lt.0.0_r8) THEN
         mneg1=mneg1-NN1(iv1)*SEDOPA(ng)%f_mass(iv1)
       ENDIF
      ENDDO
      DO iv1=1,NOIL
       IF (NN2(iv1).lt.0.0_r8) THEN
         mneg2=mneg2-NN2(iv1)*SEDOPA(ng)%oil_mass(iv1)
       ENDIF
      ENDDO
      DO iv1=1,NOPA
       IF (NN3(iv1).lt.0.0_r8) THEN
         mneg3=mneg3-NN3(iv1)*SEDOPA(ng)%opa_mass(iv1)
       ENDIF
      ENDDO
      RETURN
      END SUBROUTINE opamod_mass_control
!==========================================================================
      SUBROUTINE opamod_mass_redistribute(NN1,NN2,NN3,ng)
      USE mod_param
      USE mod_scalars
      USE mod_sedopa
      implicit none
      integer,intent(in) :: ng
      integer      :: iv
      integer, parameter :: NSED = 1
      integer, parameter :: NOIL = 1
      integer, parameter :: NOPA = 4
      real(r8)     :: npos
      real(r8)     :: mneg
      real(r8),dimension(1:NSED)      :: NN1,NN1tmp
      real(r8),dimension(1:NOIL)     :: NN2,NN2tmp
      real(r8),dimension(1:NOPA)     :: NN3,NN3tmp
! check mud classes
      mneg=0.0_r8
      npos=0.0_r8
      NN1tmp(:)=NN1(:)
      DO iv=1,NSED
       IF (NN1(iv).lt.0.0_r8) THEN
         mneg=mneg-NN1(iv)*SEDOPA(ng)%f_mass(iv)
         NN1tmp(iv)=0.0_r8
       ELSE
         npos=npos+1.0_r8
       ENDIF
      ENDDO
!      print*,'mneg for sediment',mneg
      IF (mneg.gt.0.0_r8) THEN
       IF (npos.eq.0.0_r8) THEN
         WRITE(*,*) 'CAUTION : all sediment sizes have negative mass!'
         WRITE(*,*) 'SIMULATION STOPPED'
         STOP
       ELSE
         DO iv=1,NSED
           IF (NN1(iv).gt.0.0_r8) THEN
              NN1(iv)=NN1(iv)-mneg/sum(NN1tmp)*NN1(iv)/SEDOPA(ng)%f_mass(iv)
           ELSE
              NN1(iv)=0.0_r8
           ENDIF
         ENDDO
       ENDIF
      ENDIF
! check oil classes
      mneg=0.0_r8
      npos=0.0_r8
      NN2tmp(:)=NN2(:)
      DO iv=1,NOIL
       IF (NN2(iv).lt.0.0_r8) THEN
         mneg=mneg-NN2(iv)*SEDOPA(ng)%oil_mass(iv)
         NN2tmp(iv)=0.0_r8
       ELSE
         npos=npos+1.0_r8
       ENDIF
      ENDDO
!      print*,'mneg for oil',mneg
      IF (mneg.gt.0.0_r8) THEN
       IF (npos.eq.0.0_r8) THEN
         WRITE(*,*) 'CAUTION : all oil sizes have negative mass!'
         WRITE(*,*) 'SIMULATION STOPPED'
         STOP
       ELSE
         DO iv=1,NOIL
           IF (NN2(iv).gt.0.0_r8) THEN
              NN2(iv)=NN2(iv)-mneg/sum(NN2tmp)*NN2(iv)/SEDOPA(ng)%oil_mass(iv)
           ELSE
              NN2(iv)=0.0_r8
           ENDIF
         ENDDO
       ENDIF
      ENDIF
      mneg=0.0_r8
      npos=0.0_r8
      NN3tmp(:)=NN3(:)
      DO iv=1,NOPA
       IF (NN3(iv).lt.0.0_r8) THEN
         mneg=mneg-NN3(iv)*SEDOPA(ng)%opa_mass(iv)
         NN3tmp(iv)=0.0_r8
       ELSE
         npos=npos+1.0_r8
       ENDIF
      ENDDO
!      print*,'mneg for opa',mneg
      IF (mneg.gt.0.0_r8) THEN
       IF (npos.eq.0.0_r8) THEN
         WRITE(*,*) 'CAUTION : all opa sizes have negative mass!'
         WRITE(*,*) 'SIMULATION STOPPED'
         STOP
       ELSE
         DO iv=1,NOPA
           IF (NN3(iv).gt.0.0_r8) THEN
              NN3(iv)=NN3(iv)-mneg/sum(NN3tmp)*NN3(iv)/SEDOPA(ng)%opa_mass(iv)
           ELSE
              NN3(iv)=0.0_r8
           ENDIF
         ENDDO
       ENDIF
      ENDIF
      RETURN
      END SUBROUTINE opamod_mass_redistribute
      SUBROUTINE flocmod_comp_g(k,i,j,Gval,diss,ng)
!&E--------------------------------------------------------------------------
!&E                 ***  ROUTINE flocmod_comp_g  ***
!&E
!&E ** Purpose : compute shear rate to estimate shear aggregation and
!erosion  
!&E 
!&E ** Description :
!&E
!&E ** Called by : flocmod_main
!&E
!&E ** External calls : 
!&E
!&E ** Reference :
!&E
!&E ** History :
!&E     ! 2013-09 (Romaric Verney)
!&E
!&E--------------------------------------------------------------------------
      USE mod_sedflocs
      USE mod_param
      USE mod_scalars
!
      implicit none
      integer,  intent(in)     :: k,i,j
      integer, intent(in)      :: ng
      real(r8),intent(out)     :: Gval
      real(r8)     :: htn,ustar,z,diss,nueau
       nueau = 1.5E-6_r8
       Gval=sqrt(diss/nueau)
! NO KLUDGE
!      Gval = 8.0_r8
      RETURN
      END SUBROUTINE flocmod_comp_g
      END MODULE sed_opa_mod
