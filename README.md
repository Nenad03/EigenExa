EigenExa
===============

To build the library, do as follows.

 * ./bootstrap
 * ./configure
 * make

For further information, please read the user's manual in doc/.

Configure on Fugaku:
LAPACK_LIBS="-lfjscalapacksve -lfjlapackexsve" ./configure --host=login
