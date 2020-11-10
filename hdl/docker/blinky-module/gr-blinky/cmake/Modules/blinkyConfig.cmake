INCLUDE(FindPkgConfig)
PKG_CHECK_MODULES(PC_BLINKY blinky)

FIND_PATH(
    BLINKY_INCLUDE_DIRS
    NAMES blinky/api.h
    HINTS $ENV{BLINKY_DIR}/include
        ${PC_BLINKY_INCLUDEDIR}
    PATHS ${CMAKE_INSTALL_PREFIX}/include
          /usr/local/include
          /usr/include
)

FIND_LIBRARY(
    BLINKY_LIBRARIES
    NAMES gnuradio-blinky
    HINTS $ENV{BLINKY_DIR}/lib
        ${PC_BLINKY_LIBDIR}
    PATHS ${CMAKE_INSTALL_PREFIX}/lib
          ${CMAKE_INSTALL_PREFIX}/lib64
          /usr/local/lib
          /usr/local/lib64
          /usr/lib
          /usr/lib64
)

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(BLINKY DEFAULT_MSG BLINKY_LIBRARIES BLINKY_INCLUDE_DIRS)
MARK_AS_ADVANCED(BLINKY_LIBRARIES BLINKY_INCLUDE_DIRS)

