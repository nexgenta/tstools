dnl TS Tools
dnl http://tstools.berlios.de/
dnl http://github.com/nevali/tstools.git

AC_INIT([tstools],[master],,[tstools])
AM_INIT_AUTOMAKE([foreign])
AM_MAINTAINER_MODE

AC_PROG_CC
AC_PROG_LIBTOOL

AC_CHECK_MEMBER([struct sockaddr_in.sin_len], [AC_DEFINE(HAVE_SOCKADDR_IN_SIN_LEN, 1, [Does this system have sockaddr_in.sin_len])],[],[
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
])

AC_CHECK_LIB(m,pow)
AC_CHECK_LIB(socket,getaddrinfo)
AC_CHECK_LIB(nsl,gethostbyname)
AC_CHECK_LIB(resolv,hstrerror)

AC_CONFIG_FILES([
Makefile
])

AC_OUTPUT
