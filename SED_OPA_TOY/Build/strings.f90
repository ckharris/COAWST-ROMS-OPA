      MODULE strings_mod
!
!svn $Id: strings.F 855 2017-07-29 03:10:57Z arango $
!================================================== Hernan G. Arango ===
!  Copyright (c) 2002-2018 The ROMS/TOMS Group                         !
!    Licensed under a MIT/X style license                              !
!    See License_ROMS.txt                                              !
!=======================================================================
!                                                                      !
!  This module contains several string manipulation functions:         !
!                                                                      !
!    FoundError    check execution flag against no-error code          !
!    find_string   scans a character array for a specified string      !
!    join_string   concatenate character array into a single string    !
!    lowercase     converts input string characters to lowercase       !
!    uppercase     converts input string characters to uppercase       !
!                                                                      !
!  Examples:                                                           !
!                                                                      !
!    IF (.not.find_string(var_name,n_var,'spherical',varid)) THEN      !
!      ...                                                             !
!    END IF                                                            !
!                                                                      !
!    string=lowercase('MY UPPERCASE STRING')                           !
!                                                                      !
!    string=uppercase('my lowercase string')                           !
!                                                                      !
!=======================================================================
!
      implicit none
!
      PRIVATE
!
      PUBLIC :: FoundError
      PUBLIC :: find_string
      PUBLIC :: join_string
      PUBLIC :: lowercase
      PUBLIC :: uppercase
!
      CONTAINS
!
      FUNCTION FoundError (flag, NoErr, line, routine) RESULT (foundit)
!
!=======================================================================
!                                                                      !
!  This logical function checks ROMS execution flag against no-error   !
!  code and issue a message if they are not equal.                     !
!                                                                      !
!  On Input:                                                           !
!                                                                      !
!     flag         ROMS execution flag (integer)                       !
!     NoErr        No Error code (integer)                             !
!     line         Calling model routine line (integer)                !
!     routine      Calling model routine (string)                      !
!                                                                      !
!  On Output:                                                          !
!                                                                      !
!     foundit      The value of the result is TRUE/FALSE if the        !
!                    execution flag is in error.                       !
!                                                                      !
!=======================================================================
!
      USE mod_iounits,  ONLY : stdout
      USE mod_parallel, ONLY : Master
!  Imported variable declarations.
!
      integer, intent(in) :: flag, NoErr, line
      character (len=*), intent(in) :: routine
!
!  Local variable declarations.
!
      logical :: foundit
      character (len=5) :: lstr
!
!-----------------------------------------------------------------------
!  Scan array for requested string.
!-----------------------------------------------------------------------
!
      foundit=.FALSE.
      IF (flag.ne.NoErr) THEN
        foundit=.TRUE.
        IF (Master) THEN
          WRITE (lstr,'(i5)') line
          WRITE (stdout,10) flag, ADJUSTL(TRIM(lstr)), TRIM(routine)
  10      FORMAT (' Found Error: ', i2.2, t20, 'Line: ', a,             &
     &            t35, 'Source: ', a)
        END IF
      END IF
      RETURN
      END FUNCTION FoundError
      FUNCTION find_string (A, Asize, string, Aindex) RESULT (foundit)
!
!=======================================================================
!                                                                      !
!  This logical function scans an array of type character for an       !
!  specific string.                                                    !
!                                                                      !
!  On Input:                                                           !
!                                                                      !
!     A            Array of strings (character)                        !
!     Asize        Size of A (integer)                                 !
!     string       String to search (character)                        !
!                                                                      !
!  On Output:                                                          !
!                                                                      !
!     Aindex       Array element containing the string (integer)       !
!     foundit      The value of the result is TRUE/FALSE if the        !
!                    string was found or not.                          !
!                                                                      !
!=======================================================================
!
!  Imported variable declarations.
!
      integer, intent(in) :: Asize
      integer, intent(out) :: Aindex
      character (len=*), intent(in) :: A(Asize)
      character (len=*), intent(in) :: string
!
!  Local variable declarations.
!
      logical :: foundit
      integer :: i
!
!-----------------------------------------------------------------------
!  Scan array for requested string.
!-----------------------------------------------------------------------
!
      foundit=.FALSE.
      Aindex=0
      DO i=1,Asize
        IF (TRIM(A(i)).eq.TRIM(string)) THEN
          foundit=.TRUE.
          Aindex=i
          EXIT
        END IF
      END DO
      RETURN
      END FUNCTION find_string
!
      SUBROUTINE join_string (A, Asize, string, Lstring)
!
!=======================================================================
!                                                                      !
!  This routine concatenate a character array into a single string     !
!  with each element separated by commas.                              !
!                                                                      !
!  On Input:                                                           !
!                                                                      !
!     A            Array of strings (character)                        !
!     Asize        Size of A (integer)                                 !
!                                                                      !
!  On Output:                                                          !
!                                                                      !
!     string       Concatenated string (character)                     !
!     Lstring      Length of concatenated string (integer)             !
!                                                                      !
!=======================================================================
!
!  Imported variable declarations.
!
      integer, intent(in) :: Asize
      integer, intent(out) :: Lstring
      character (len=*), intent(in) :: A(Asize)
      character (len=*), intent(out) :: string
!
!  Local variable declarations.
!
      integer :: i, ie, is, lstr
!
!-----------------------------------------------------------------------
!  Concatenate input character array.
!-----------------------------------------------------------------------
!
!  Initialize to blank string.
!
      lstr=LEN(string)
      DO i=1,lstr
        string(i:i)=' '
      END DO
!
!  Concatenate.
!
      is=1
      DO i=1,Asize
        lstr=LEN_TRIM(A(i))
        IF (lstr.gt.0) THEN
          ie=is+lstr-1
          string(is:ie)=TRIM(A(i))
          is=ie+1
          string(is:is)=','
          is=is+2
        END IF
      END DO
      Lstring=LEN_TRIM(string)-1
      RETURN
      END SUBROUTINE join_string
!
      FUNCTION lowercase (Sinp) RESULT (Sout)
!
!=======================================================================
!                                                                      !
!  This character function converts input string elements to           !
!  lowercase.                                                          !
!                                                                      !
!  On Input:                                                           !
!                                                                      !
!     Sinp       String with uppercase elements (character)            !
!                                                                      !
!  On Output:                                                          !
!                                                                      !
!     Sout       Lowercase string (character)                          !
!                                                                      !
!  Reference:                                                          !
!                                                                      !
!     Cooper Redwine, 1995: "Upgrading to Fortran 90", Springer-       !
!       Verlag, New York, pp 416.                                      !
!                                                                      !
!=======================================================================
!
!  Imported variable declarations.
!
      character (*), intent(in) :: Sinp
!
!  Local variable definitions.
!
      integer :: i, j, lstr
      character (LEN(Sinp)) :: Sout
      character (26), parameter :: Lcase = 'abcdefghijklmnopqrstuvwxyz'
      character (26), parameter :: Ucase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
!
!-----------------------------------------------------------------------
!  Convert input string to lowercase.
!-----------------------------------------------------------------------
!
      lstr=LEN(Sinp)
      Sout=Sinp
      DO i=1,lstr
        j=INDEX(Ucase, Sout(i:i))
        IF (j.ne.0) THEN
          Sout(i:i)=Lcase(j:j)
        END IF
      END DO
      RETURN
      END FUNCTION lowercase
!
      FUNCTION uppercase (Sinp) RESULT (Sout)
!
!=======================================================================
!                                                                      !
!  This character function converts input string elements to           !
!  uppercase.                                                          !
!                                                                      !
!  On Input:                                                           !
!                                                                      !
!     Sinp       String with lowercase characters (character)          !
!                                                                      !
!  On Output:                                                          !
!                                                                      !
!     Sout       Uppercase string (character)                          !
!                                                                      !
!  Reference:                                                          !
!                                                                      !
!     Cooper Redwine, 1995: "Upgrading to Fortran 90", Springer-       !
!       Verlag, New York, pp 416.                                      !
!                                                                      !
!=======================================================================
!
!  Imported variable declarations.
!
      character (*), intent(in) :: Sinp
!
!  Local variable definitions.
!
      integer :: i, j, lstr
      character (LEN(Sinp)) :: Sout
      character (26), parameter :: Lcase = 'abcdefghijklmnopqrstuvwxyz'
      character (26), parameter :: Ucase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
!
!-----------------------------------------------------------------------
!  Convert input string to uppercase.
!-----------------------------------------------------------------------
!
      lstr=LEN(Sinp)
      Sout=Sinp
      DO i=1,lstr
        j=INDEX(Lcase, Sout(i:i))
        IF (j.ne.0) THEN
          Sout(i:i)=Ucase(j:j)
        END IF
      END DO
      RETURN
      END FUNCTION uppercase
      END MODULE strings_mod
