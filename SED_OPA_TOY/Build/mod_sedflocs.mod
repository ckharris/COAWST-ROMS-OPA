  ¢  ?   k820309    l          18.0        Êm]                                                                                                          
       mod_sedflocs.f90 MOD_SEDFLOCS          @                                         
                                                                                                                                                                                                                                                                                                                                                                                                                                                           
                                                   	     
                                                   
     
                                                        
                                                       
                                                        
                                                       
                                                        
                                                        
                                                        
                                                       
                                                       
                                                        
                                                        
                
                      @        1030.0                  @                                'X                   #F_DIAM    #F_VOL    #F_RHO    #F_CV    #F_L3    #F_MASS    #F_COLL_PROB_SH    #F_COLL_PROB_DS    #F_L1_SH    #F_L1_DS     #F_G3 !   #F_L4 "   #F_G1_SH #   #F_G1_DS $   #F_G4 %                                                                          
            &                                                                                                H                 
            &                                                                                                                 
            &                                                                                                Ø                 
            &                                                                                                                 
            &                                                                                                h                
            &                                                                                                °                
            &                   &                                                                                                                
            &                   &                                                                                                p             	   
            &                   &                                                                                                 Ð             
   
            &                   &                                                                                    !            0                
            &                   &                                                                                    "                            
            &                   &                                                                                    #            ð                
            &                   &                   &                                                                                    $            h                
            &                   &                   &                                                                                    %            à                
            &                   &                   &                                                    @ @                               &            X                       &                                           #T_SEDFLOCS    #         @                                   '                    #NG (   #LBI )   #UBI *   #LBJ +   #UBJ ,                                       
                                  (                     
                                  )                     
                                  *                     
                                  +                     
                                  ,           #         @                                   -                    #NG .   #TILE /   #MODEL 0                                         
  @                               .                     
  @                               /                     
                                  0           #         @                                  1                   #INITIALIZE_SEDFLOCS_PARAM%NCS 2   #NG 3   #TILE 4   #F_MASS 5   #F_DIAM 6   #F_G1_SH 7   #F_G1_DS 8   #F_G3 9   #F_L1_SH :   #F_L1_DS ;   #F_COLL_PROB_SH <   #F_COLL_PROB_DS =   #F_L3 >                                                                                                                  2                      
                                  3                     
                                  4                    
D                                5                    
     p           & p          5 r 2   n                                       1       5 r 2   n                                      1p         p                                            
D                                6                    
     p          5 r 2       5 r 2                              
D @                              7                    
         p        5 r 2   p        5 r 2   p          5 r 2     5 r 2     5 r 2       5 r 2     5 r 2     5 r 2                              
D @                              8                    
         p        5 r 2   p        5 r 2   p          5 r 2     5 r 2     5 r 2       5 r 2     5 r 2     5 r 2                              
D @                              9                    
       p        5 r 2   p          5 r 2     5 r 2       5 r 2     5 r 2                              
D @                              :                    
       p        5 r 2   p          5 r 2     5 r 2       5 r 2     5 r 2                              
D @                              ;                    
       p        5 r 2   p          5 r 2     5 r 2       5 r 2     5 r 2                              
D @                              <                    
       p        5 r 2   p          5 r 2     5 r 2       5 r 2     5 r 2                              
D @                              =                    
       p        5 r 2   p          5 r 2     5 r 2       5 r 2     5 r 2                              
D @                              >                    
     p          5 r 2       5 r 2                            &      fn#fn    Æ   @   J   MOD_KINDS      p       R8+MOD_KINDS    v  @       L_ASH    ¶  @       L_ADS    ö  @       L_COLLFRAG    6  @       L_TESTCASE    v  @       F_ERO_IV    ¶  @       F_DP0    ö  @       F_ALPHA    6  @       F_BETA    v  @       F_NB_FRAG    ¶  @       F_DMAX    ö  @       F_ATER    6  @       F_CLIM    v  @       F_ERO_FRAC    ¶  @       F_ERO_NBFRAG    ö  @       F_NF    6  @       F_FRAG    v  @       F_FTER     ¶  @       F_COLLFRAGPARAM    ö  v       RHOREF    l        T_SEDFLOCS "   x     a   T_SEDFLOCS%F_DIAM !        a   T_SEDFLOCS%F_VOL !         a   T_SEDFLOCS%F_RHO     4	     a   T_SEDFLOCS%F_CV     È	     a   T_SEDFLOCS%F_L3 "   \
     a   T_SEDFLOCS%F_MASS *   ð
  ¬   a   T_SEDFLOCS%F_COLL_PROB_SH *     ¬   a   T_SEDFLOCS%F_COLL_PROB_DS #   H  ¬   a   T_SEDFLOCS%F_L1_SH #   ô  ¬   a   T_SEDFLOCS%F_L1_DS        ¬   a   T_SEDFLOCS%F_G3     L  ¬   a   T_SEDFLOCS%F_L4 #   ø  Ä   a   T_SEDFLOCS%F_G1_SH #   ¼  Ä   a   T_SEDFLOCS%F_G1_DS       Ä   a   T_SEDFLOCS%F_G4    D         SEDFLOCS "   à         ALLOCATE_SEDFLOCS %   n  @   a   ALLOCATE_SEDFLOCS%NG &   ®  @   a   ALLOCATE_SEDFLOCS%LBI &   î  @   a   ALLOCATE_SEDFLOCS%UBI &   .  @   a   ALLOCATE_SEDFLOCS%LBJ &   n  @   a   ALLOCATE_SEDFLOCS%UBJ $   ®         INITIALIZE_SEDFLOCS '   /  @   a   INITIALIZE_SEDFLOCS%NG )   o  @   a   INITIALIZE_SEDFLOCS%TILE *   ¯  @   a   INITIALIZE_SEDFLOCS%MODEL *   ï  I      INITIALIZE_SEDFLOCS_PARAM 8   8  @     INITIALIZE_SEDFLOCS_PARAM%NCS+MOD_PARAM -   x  @   a   INITIALIZE_SEDFLOCS_PARAM%NG /   ¸  @   a   INITIALIZE_SEDFLOCS_PARAM%TILE 1   ø  6  a   INITIALIZE_SEDFLOCS_PARAM%F_MASS 1   .     a   INITIALIZE_SEDFLOCS_PARAM%F_DIAM 2   Â    a   INITIALIZE_SEDFLOCS_PARAM%F_G1_SH 2   Ö    a   INITIALIZE_SEDFLOCS_PARAM%F_G1_DS /   ê  Ô   a   INITIALIZE_SEDFLOCS_PARAM%F_G3 2   ¾  Ô   a   INITIALIZE_SEDFLOCS_PARAM%F_L1_SH 2     Ô   a   INITIALIZE_SEDFLOCS_PARAM%F_L1_DS 9   f  Ô   a   INITIALIZE_SEDFLOCS_PARAM%F_COLL_PROB_SH 9   :  Ô   a   INITIALIZE_SEDFLOCS_PARAM%F_COLL_PROB_DS /        a   INITIALIZE_SEDFLOCS_PARAM%F_L3 