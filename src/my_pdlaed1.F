!--------*---------*---------*---------*---------*---------*---------*-*
!     
! Module: my_pdlaed1_mod
!--------*---------*---------*---------*---------*---------*---------*-*

      MODULE MY_PDLAED1_MOD

      USE MY_PDLAED2_MOD
      USE MY_PDLAED3_MOD
      USE EIGEN_DEVEL_MOD
      USE EIGEN_DC_MOD
      USE MPI
!$    USE OMP_LIB
      IMPLICIT NONE
      PUBLIC

      CONTAINS

      SUBROUTINE MY_PDLAED1( N, N1, D, ID, Q, IQ, JQ, DESCQ, RHO, WORK,
     &     IWORK, Z, ISTAGE, INFO )
!     
!     This routine is a modified routine of PDLAED1
!     which is contained in the ScaLAPACK
!     Modification is done by T.Imamura
!     
!     .. Scalar Arguments ..
      INTEGER            ID, IQ, JQ, N, N1, ISTAGE
      INTEGER(8) :: INFO
      DOUBLE PRECISION   RHO
!     ..
!     .. Array Arguments ..
      INTEGER            DESCQ( * ), IWORK( * )
      DOUBLE PRECISION   D( * ), Q( * ), WORK( * ), Z ( * )

!     ..
!     
!     Purpose
!     =======
!     
!     MY_PDLAED1 computes the updated eigensystem of a diagonal
!     matrix after modification by a rank-one symmetric matrix,
!     in parallel.
!     
!     T = Q(in) ( D(in) + RHO * Z*Z' ) Q'(in) = Q(out) * D(out) * Q'(out)
!     
!     where Z = Q'u, u is a vector of length N with ones in the
!     N1 and N1 + 1 th elements and zeros elsewhere.
!     
!     The eigenvectors of the original matrix are stored in Q, and the
!     eigenvalues are in D.  The algorithm consists of three stages:
!     
!     The first stage consists of deflating the size of the problem
!     when there are multiple eigenvalues or if there is a zero in
!     the Z vector.  For each such occurence the dimension of the
!     secular equation problem is reduced by one.  This stage is
!     performed by the routine MY_PDLAED2.
!     
!     The second stage consists of calculating the updated
!     eigenvalues. This is done by finding the roots of the secular
!     equation via the routine SLAED4 (as called by MY_PDLAED3).
!     This routine also calculates the eigenvectors of the current
!     problem.
!     
!     The final stage consists of computing the updated eigenvectors
!     directly using the updated eigenvalues.  The eigenvectors for
!     the current problem are multiplied with the eigenvectors from
!     the overall problem.
!     
!     Arguments
!     =========
!     
!     N       (global input) INTEGER
!     The order of the tridiagonal matrix T.  N >= 0.
!     
!     
!     N1      (input) INTEGER
!     The location of the last eigenvalue in the leading
!     sub-matrix.
!     min(1,N) <= N1 <= N.
!     
!     D       (global input/output) DOUBLE PRECISION array, dimension (N)
!     On entry,the eigenvalues of the rank-1-perturbed matrix.
!     On exit, the eigenvalues of the repaired matrix.
!     
!     ID      (global input) INTEGER
!     D's global row/col index, which points to the beginning
!     of the submatrix which is to be operated on.
!     
!     Q       (local output) DOUBLE PRECISION array,
!     global dimension (N, N),
!     local dimension ( LLD_Q, LOCc(JQ+N-1))
!     Q  contains the orthonormal eigenvectors of the symmetric
!     tridiagonal matrix.
!     
!     IQ      (global input) INTEGER
!     Q's global row index, which points to the beginning of the
!     submatrix which is to be operated on.
!     
!     JQ      (global input) INTEGER
!     Q's global column index, which points to the beginning of
!     the submatrix which is to be operated on.
!     
!     DESCQ   (global and local input) INTEGER array of dimension DLEN_.
!     The array descriptor for the distributed matrix Z.
!     
!     RHO    (input) DOUBLE PRECISION
!     The subdiagonal entry used to create the rank-1 modification.
!     
!     WORK    (local workspace/output) DOUBLE PRECISION array,
!     dimension 6*N + 2*NP*NQ
!     
!     IWORK   (local workspace/output) INTEGER array,
!     dimension 7*N + 8*NPCOL + 2
!     
!     INFO    (global output) INTEGER
!     = 0:  successful exit
!     < 0:  If the i-th argument is an array and the j-entry had
!     an illegal value, then INFO = -(i*100+j), if the i-th
!     argument is a scalar and had an illegal value, then
!     INFO = -i.
!     > 0:  The algorithm failed to compute the ith eigenvalue.
!     
!     =====================================================================
!     
!     .. Parameters ..
!     
      INTEGER            BLOCK_CYCLIC_2D, DLEN_, DTYPE_, CTXT_, M_, N_,
     &     MB_, NB_, RSRC_, CSRC_, LLD_
      PARAMETER          ( BLOCK_CYCLIC_2D = 1, DLEN_ = 9, DTYPE_ = 1,
     &     CTXT_ = 2, M_ = 3, N_ = 4, MB_ = 5, NB_ = 6,
     &     RSRC_ = 7, CSRC_ = 8, LLD_ = 9 )
!     DOUBLE PRECISION   ZERO, ONE
!     PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
      INTEGER            COL, COLTYP, ICTOT, ICTXT, IDLMDA, IIQ,
     &     INDCOL, INDROW, INDX, INDXC, INDXP, INDXR, INQ,
     &     IPQ2, IPSM, IPWORK, IQ1, IQ2, IQCOL,
     &     IQQ, IQROW, IW, IZ, J, JC, JJ2C, JJC, JJQ, JNQ,
     &     K, LDQ, LDQ2, LDU, MYCOL, MYROW, NB, NN, NN1,
     &     NN2, NP, NPCOL, NPROW, NQ
      INTEGER :: I
      INTEGER(8) :: IBUF, INQ_I8, IPU, IPQ, IQ2_I8
      INTEGER :: INFO_I4
!     ..
!     .. Local Arrays ..
      INTEGER            DESCQ2( DLEN_ ), DESCU( DLEN_ )
!     ..
!     .. External Functions ..
      INTEGER            NUMROC
      EXTERNAL           NUMROC
!     ..
!     .. External Subroutines ..
      EXTERNAL           BLACS_GRIDINFO, DCOPY, DESCINIT, INFOG1L,
     &     INFOG2L, PDGEMM,
     &     PDLASET, PXERBLA
!     ..
!     .. Intrinsic Functions ..
      INTRINSIC          MAX, MIN

      real(8) :: t1,t2,z1,z2
      integer :: MY_RANK
!     ..
!     .. Executable Statements ..
!     
      t1=eigen_get_wtime()
!     This is just to keep ftnchek and toolpack/1 happy
!      IF( BLOCK_CYCLIC_2D*CSRC_*CTXT_*DLEN_*DTYPE_*LLD_*MB_*M_*NB_*N_*
!     &     RSRC_.LT.0 )RETURN
!     
!     
!     Test the input parameters.
!     
      CALL BLACS_GRIDINFO( DESCQ( CTXT_ ), NPROW, NPCOL, MYROW, MYCOL )
      INFO = 0
      IF( NPROW.EQ.-1 ) THEN
         INFO = -( 600+CTXT_ )
      ELSE IF( N.LT.0 ) THEN
         INFO = -1
      ELSE IF( ID.GT.DESCQ( N_ ) ) THEN
         INFO = -4
      ELSE IF( N1.GE.N ) THEN
         INFO = -2
      END IF
      IF( INFO.NE.0 ) THEN
         INFO_I4 = INFO
         CALL PXERBLA( DESCQ( CTXT_ ), 'MY_PDLAED1', -INFO_I4 )
         INFO = INFO_I4
         RETURN
      END IF
!     
!     Quick return if possible
!     
      IF( N.EQ.0 )
     &     RETURN
!     
!     The following values are  integer pointers which indicate
!     the portion of the workspace used by a particular array
!     in MY_PDLAED2 and MY_PDLAED3.
!     
      ICTXT = DESCQ( CTXT_ )
      NB = DESCQ( NB_ )
      LDQ = DESCQ( LLD_ )
!     
      CALL INFOG2L( IQ-1+ID, JQ-1+ID, DESCQ, NPROW, NPCOL, MYROW, MYCOL,
     &     IIQ, JJQ, IQROW, IQCOL )
!     
      NP = NUMROC( N, DESCQ( MB_ ), MYROW, IQROW, NPROW )
      NQ = NUMROC( N, DESCQ( NB_ ), MYCOL, IQCOL, NPCOL )
!     
      LDQ2 = MAX( NP, 1 )
      LDU = LDQ2
!     
      IZ = 1
      IDLMDA = IZ + N
      IW = IDLMDA + N
      IPQ2 = IW + N
      IPU = IPQ2 + INT(LDQ2,8)*INT(NQ,8)
      IBUF = IPU + INT(LDU,8)*INT(NQ,8)
!     (IBUF est de taille 3*N au maximum)
!     
      ICTOT = 1
      IPSM = ICTOT + NPCOL*4
      INDX = IPSM + NPCOL*4
      INDXC = INDX + N
      INDXP = INDXC + N
      INDCOL = INDXP + N
      COLTYP = INDCOL + N
      INDROW = COLTYP + N
      INDXR = INDROW + N
!     
      INFO_I4 = INFO
      CALL DESCINIT( DESCQ2, N, N, NB, NB, IQROW, IQCOL, ICTXT, LDQ2,
     &     INFO_I4 )
      CALL DESCINIT( DESCU, N, N, NB, NB, IQROW, IQCOL, ICTXT, LDU,
     &     INFO_I4 )
      INFO = INFO_I4
!     
!     Form the z-vector which consists of the last row of Q_1 and the
!     first row of Q_2.
!     
      IPWORK = IDLMDA
!     CALL PDLAEDZ( N, N1, ID, Q, IQ, JQ, LDQ, DESCQ, WORK( IZ ),
!     $              WORK( IPWORK ) )
!     
!     Modified by Phuong
!     To be able to use this funtion with other Z, we set Z as an input 
!     
      
!     CALL DCOPY(N, Z( 1 ), 1, WORK( IZ ), 1);
!$OMP PARALLEL DO
      DO I = 1, N
         WORK(IZ+I-1) = Z(I)
      END DO
!$OMP END PARALLEL DO

!     Deflate eigenvalues.

      IPQ = IIQ + INT( JJQ-1,8 )*INT(LDQ,8)

      z1=eigen_get_wtime()
      CALL MY_PDLAED2(
     &     ICTXT, K, N, N1, NB, D, IQROW, IQCOL, Q( IPQ ), LDQ,
     &     RHO, WORK( IZ ), WORK( IW ), WORK( IDLMDA ),
     &     WORK( IPQ2 ), LDQ2, WORK( IBUF ), IWORK( ICTOT ),
     &     IWORK( IPSM ), NPCOL, IWORK( INDX ), IWORK( INDXC ),
     &     IWORK( INDXP ), IWORK( INDCOL ), IWORK( COLTYP ),
     &     NN, NN1, NN2, IQ1, IQ2 )
      z2=eigen_get_wtime()
      p_time2 = p_time2 + (z2-z1)
!     
!     
!     Solve Secular Equation.
!     

      IF( K.NE.0 ) THEN

         z1=eigen_get_wtime()
         CALL PDLASET( 'A', N, N, ZERO, ONE, WORK( IPU ), 1, 1, DESCU )
         z2=eigen_get_wtime()
         p_times = p_times + (z2-z1)
         
         z1=eigen_get_wtime()
         INFO_I4=0
!$OMP PARALLEL
!$OMP+         REDUCTION(MAX:INFO_I4)
         INFO = INFO_I4
         CALL MY_PDLAED3(
     &        ICTXT, K, N, NB, D, IQROW, IQCOL, RHO,
     &        WORK( IDLMDA ), WORK( IW ), WORK( IZ ),
     &        WORK( IPU ), LDQ2, WORK( IBUF ), IWORK( INDX ),
     &        IWORK( INDCOL ), IWORK( INDROW ), IWORK( INDXR ),
     &        IWORK( INDXC ), IWORK( ICTOT ), NPCOL, INFO )
         INFO_I4 = INFO
!$OMP END PARALLEL
         INFO = INFO_I4
         z2=eigen_get_wtime()
         p_time3 = p_time3 + (z2-z1)

!     
!     Compute the updated eigenvectors.
!     
         IF ( ISTAGE == 1 ) THEN

            IQQ = MIN( IQ1, IQ2 )
            IF( NN1.GT.0 ) THEN
               INQ = IQ - 1 + ID
               JNQ = JQ - 1 + ID + IQQ - 1
               z1=eigen_get_wtime()
               CALL PDGEMM( 'N', 'N', N1, NN, NN1, ONE, WORK( IPQ2 ), 1,
     &              IQ1, DESCQ2, WORK( IPU ), IQ1, IQQ, DESCU,
     &              ZERO, Q, INQ, JNQ, DESCQ )
               z2=eigen_get_wtime()
               flops = flops+(2*DBLE(N1)*DBLE(NN)*DBLE(NN1))
               dgemm_time = dgemm_time+(z2-z1)
            END IF
            
            IF( NN2.GT.0 ) THEN
               INQ = IQ - 1 + ID + N1
               JNQ = JQ - 1 + ID + IQQ - 1
               z1=eigen_get_wtime()
               CALL PDGEMM( 'N', 'N', N-N1, NN, NN2, ONE, WORK( IPQ2 ),
     &              N1+1, IQ2, DESCQ2, WORK( IPU ), IQ2, IQQ,
     &              DESCU, ZERO, Q, INQ, JNQ, DESCQ )
               z2=eigen_get_wtime()
               flops = flops+(2*DBLE(N-N1)*DBLE(NN)*DBLE(NN2))
               dgemm_time = dgemm_time+(z2-z1)
            END IF

         ELSE IF ( NN.GT.0 ) THEN

            IQQ = MIN( IQ1, IQ2 )
            INQ = IQ - 1 + ID
            JNQ = JQ - 1 + ID + IQQ - 1
            z1=eigen_get_wtime()
            CALL PDGEMM( 'N', 'N', N, NN, NN, ONE, WORK( IPQ2 ), 1,
     &           IQQ, DESCQ2, WORK( IPU ), IQQ, IQQ, DESCU,
     &           ZERO, Q, INQ, JNQ, DESCQ )
            z2=eigen_get_wtime()
            flops = flops+(2*DBLE(N)*DBLE(NN)*DBLE(NN))
            dgemm_time = dgemm_time+(z2-z1)

         ENDIF
!     
!$OMP PARALLEL DO
!$OMP+         PRIVATE(J,JC,JJC,JJ2C,COL,IQ2_I8,INQ_I8)
         DO 10 J = K + 1, N
            JC = IWORK( INDX+J-1 )
            CALL INFOG1L( JQ-1+JC, NB, NPCOL, MYCOL, IQCOL, JJC, COL )
            CALL INFOG1L( JC, NB, NPCOL, MYCOL, IQCOL, JJ2C, COL )
            IF( MYCOL.EQ.COL ) THEN
               IQ2_I8 = IPQ2 + INT( JJ2C-1,8 )*INT(LDQ2,8)
               INQ_I8 = IPQ + INT( JJC-1,8 )*INT(LDQ,8)
               CALL DCOPY( NP, WORK( IQ2_I8 ), 1, Q( INQ_I8 ), 1 )
            END IF
 10      CONTINUE
!$OMP END PARALLEL DO

      END IF
      t2=eigen_get_wtime()
!     
      RETURN
!     
!     End of MY_PDLAED1
!     
      END SUBROUTINE MY_PDLAED1

      END MODULE MY_PDLAED1_MOD
