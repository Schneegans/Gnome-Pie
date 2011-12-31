################################################################
# Project Gnome-Pie
################################################################

project("gnomepie" C)

cmake_minimum_required(VERSION 2.6)

# Location where cmake first looks for modules.
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala)

################################################################
# Find Vala
################################################################

include(ValaPrecompile)
include(ValaVersion)

find_package(Vala)
ensure_vala_version("0.11.0" MINIMUM)

################################################################
# Configure and find libraries
################################################################

find_package(PkgConfig)

# check whether GTK3 is supported
pkg_check_modules(GTK3 gtk+-3.0)

if (${GTK3_FOUND})
    pkg_check_modules(INDICATOR3 appindicator3-0.1)
    pkg_check_modules(UNIQUE REQUIRED unique-3.0)
    pkg_check_modules(WNCK REQUIRED libwnck-3.0)
    pkg_check_modules(BAMF REQUIRED libbamf3)
else (${GTK3_FOUND})
    pkg_check_modules(GTK2 REQUIRED gtk+-2.0)
    pkg_check_modules(INDICATOR appindicator-0.1)
    pkg_check_modules(UNIQUE REQUIRED unique-1.0)
    pkg_check_modules(WNCK REQUIRED libwnck-1.0)
    pkg_check_modules(BAMF REQUIRED libbamf)
endif (${GTK3_FOUND})

pkg_check_modules(GIO REQUIRED gio-unix-2.0)
pkg_check_modules(CAIRO REQUIRED cairo)
pkg_check_modules(GEE REQUIRED gee-1.0)
pkg_check_modules(X11 REQUIRED x11)
pkg_check_modules(XML REQUIRED libxml-2.0)
pkg_check_modules(XTST REQUIRED xtst)
pkg_check_modules(GMENU3 libgnome-menu-3.0)

find_library(M_LIB m)

set(CFLAGS
    ${GIO_CFLAGS}
    ${GTK2_CFLAGS} ${GTK2_CFLAGS_OTHER}
    ${GTK3_CFLAGS} ${GTK3_CFLAGS_OTHER}
    ${CAIRO_CFLAGS} ${CAIRO_CFLAGS_OTHER}
    ${GEE_CFLAGS} ${CAIRO_CFLAGS_OTHER}
    ${X11_CFLAGS} ${X11_CFLAGS_OTHER}
	-DGMENU_I_KNOW_THIS_IS_UNSTABLE
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE
    -DGETTEXT_PACKAGE="gnomepie"
	-s -O3
	#-g
)

# fallback to gtk2 if gtk3 wasn't found
if (${GTK3_FOUND})
    LIST(APPEND CFLAGS -DHAVE_GTK_3)
endif (${GTK3_FOUND})

# fallback to gnome-menus2 if gnome-menus3 wasn't found
if (${GMENU3_FOUND})
    LIST(APPEND CFLAGS -DHAVE_GMENU_3)
else (${GMENU3_FOUND})
    pkg_check_modules(GMENU REQUIRED libgnome-menu)
endif (${GMENU3_FOUND})

# notify application of presence of libappindicator
if (${INDICATOR_FOUND})
    LIST(APPEND CFLAGS -DHAVE_APPINDICATOR)
endif (${INDICATOR_FOUND})

if (${INDICATOR3_FOUND})
    LIST(APPEND CFLAGS -DHAVE_APPINDICATOR3)
endif (${INDICATOR3_FOUND})

add_definitions(${CFLAGS})

set(LIBS
    ${GIO_LIBRARIES}
	${GTK2_LIBRARIES}
	${GTK3_LIBRARIES}
	${CAIRO_LIBRARIES}
	${GEE_LIBRARIES}
	${INDICATOR_LIBRARIES}
	${INDICATOR3_LIBRARIES}
	${XML_LIBRARIES}
	${XTST_LIBRARIES}
	${GMENU_LIBRARIES}
	${GMENU3_LIBRARIES}
	${UNIQUE_LIBRARIES}
	${X11_LIBRARIES}
	${WNCK_LIBRARIES}
	${BAMF_LIBRARIES}
	${M_LIB}
)
link_libraries(${LIBS})

set(LIB_PATHS
    ${GIO_LIBRARY_DIRS}
	${GTK2_LIBRARY_DIRS}
	${GTK3_LIBRARY_DIRS}
	${CAIRO_LIBRARY_DIRS}
	${GEE_LIBRARY_DIRS}
	${INDICATOR_LIBRARY_DIRS}
	${INDICATOR3_LIBRARY_DIRS}
	${XML_LIBRARY_DIRS}
	${XTST_LIBRARY_DIRS}
	${GMENU_LIBRARY_DIRS}
	${GMENU3_LIBRARY_DIRS}
	${UNIQUE_LIBRARY_DIRS}
	${X11_LIBRARY_DIRS}
	${WNCK_LIBRARY_DIRS}
	${BAMF_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})

set(INCLUDE_PATHS
    ${GIO_INCLUDE_DIRS}
	${GTK2_INCLUDE_DIRS}
	${GTK3_INCLUDE_DIRS}
	${CAIRO_INCLUDE_DIRS}
	${GEE_INCLUDE_DIRS}
	${INDICATOR_INCLUDE_DIRS}
	${INDICATOR3_INCLUDE_DIRS}
	${XML_INCLUDE_DIRS}
	${XTST_INCLUDE_DIRS}	
	${GMENU_INCLUDE_DIRS}
	${GMENU3_INCLUDE_DIRS}
	${UNIQUE_INCLUDE_DIRS}
	${X11_INCLUDE_DIRS}
	${BAMF_INCLUDE_DIRS}
	${WNCK_INCLUDE_DIRS}
)
include_directories(${INCLUDE_PATHS})

################################################################
# Add executable
################################################################

set(EXECUTABLE_OUTPUT_PATH ${gnomepie_SOURCE_DIR})

set(VALA_PKGS
  cairo
  gee-1.0
  x11
  gio-unix-2.0
  posix
  libxml-2.0
  xtst
)

if (${INDICATOR_FOUND})
    LIST(APPEND VALA_PKGS appindicator-0.1)
endif (${INDICATOR_FOUND})

if (${INDICATOR3_FOUND})
    LIST(APPEND VALA_PKGS appindicator3-0.1)
endif (${INDICATOR3_FOUND})

if (${GMENU3_FOUND})
    LIST(APPEND VALA_PKGS libgnome-menu-3.0)
else (${GMENU3_FOUND})
    LIST(APPEND VALA_PKGS libgnome-menu)
endif (${GMENU3_FOUND})

if (${GTK3_FOUND})
    LIST(APPEND VALA_PKGS gtk+-3.0)
    LIST(APPEND VALA_PKGS gdk-x11-3.0)
    LIST(APPEND VALA_PKGS libbamf3)
    LIST(APPEND VALA_PKGS libwnck-3.0)
    LIST(APPEND VALA_PKGS unique-3.0)
else (${GTK3_FOUND})
    LIST(APPEND VALA_PKGS gtk+-2.0)
    LIST(APPEND VALA_PKGS gdk-x11-2.0)
    LIST(APPEND VALA_PKGS bamf)
    LIST(APPEND VALA_PKGS libwnck-1.0)
    LIST(APPEND VALA_PKGS unique-1.0)
endif (${GTK3_FOUND})

add_subdirectory(src)

################################################################
# Add uninstall option
################################################################

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/CMake_Uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/CMake_Uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/CMake_Uninstall.cmake)

################################################################
# Summary
################################################################

message( "" )
message( "Summary:" )
message( "  EXECUTABLE_OUTPUT_PATH = ${EXECUTABLE_OUTPUT_PATH}" )
message( "  VALA_EXECUTABLE = ${VALA_EXECUTABLE}" )
message( "Libs:" )
message( "  GTK2_LIBRARIES = ${GTK2_LIBRARIES}" )
message( "  GTK3_LIBRARIES = ${GTK3_LIBRARIES}" )
message( "  CAIRO_LIBRARIES = ${CAIRO_LIBRARIES}" )
message( "  GEE_LIBRARIES = ${GEE_LIBRARIES}" )
message( "  INDICATOR_LIBRARIES = ${INDICATOR_LIBRARIES}" )
message( "  INDICATOR3_LIBRARIES = ${INDICATOR3_LIBRARIES}" )
message( "  XML_LIBRARIES = ${XML_LIBRARIES}" )
message( "  XTST_LIBRARIES = ${XTST_LIBRARIES}" )
message( "  GMENU_LIBRARIES = ${GMENU_LIBRARIES}" )
message( "  GMENU3_LIBRARIES = ${GMENU3_LIBRARIES}" )
message( "  UNIQUE_LIBRARIES = ${UNIQUE_LIBRARIES}" )
message( "  X11_LIBRARIES = ${X11_LIBRARIES}" )
message( "  BAMF_LIBRARIES = ${BAMF_LIBRARIES}" )
message( "  WNCK_LIBRARIES = ${WNCK_LIBRARIES}" )
message( "" )
