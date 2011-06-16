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
pkg_check_modules(GTK REQUIRED gtk+-2.0) 
pkg_check_modules(CAIRO REQUIRED cairo) 
pkg_check_modules(GEE REQUIRED gee-1.0)
pkg_check_modules(X11 REQUIRED x11)
pkg_check_modules(INDICATOR REQUIRED appindicator-0.1)
pkg_check_modules(RSVG REQUIRED librsvg-2.0)
pkg_check_modules(XML REQUIRED libxml-2.0)

set(CFLAGS
	${GTK_CFLAGS} ${GTK_CFLAGS_OTHER}
	${CAIRO_CFLAGS} ${CAIRO_CFLAGS_OTHER}
	${GEE_CFLAGS} ${CAIRO_CFLAGS_OTHER}
	-s -O2
)
add_definitions(${CFLAGS})

set(LIBS
	${GTK_LIBRARIES}
	${CAIRO_LIBRARIES}
	${GEE_LIBRARIES}
	${INDICATOR_LIBRARIES}
	${RSVG_LIBRARIES}
	${XML_LIBRARIES}
)
link_libraries(${LIBS})

set(LIB_PATHS
	${GTK_LIBRARY_DIRS}
	${CAIRO_LIBRARY_DIRS}
	${GEE_LIBRARY_DIRS}
	${INDICATOR_LIBRARY_DIRS}
	${RSVG_LIBRARY_DIRS}
	${XML_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})

set(INCLUDE_PATHS
	${GTK_INCLUDE_DIRS}
	${CAIRO_INCLUDE_DIRS}
	${GEE_INCLUDE_DIRS}
	${INDICATOR_INCLUDE_DIRS}
	${RSVG_INCLUDE_DIRS}
	${XML_INCLUDE_DIRS}
)
include_directories(${INCLUDE_PATHS})

################################################################
# Add executable
################################################################

set(EXECUTABLE_OUTPUT_PATH ${gnomepie_SOURCE_DIR})

add_subdirectory(src)

################################################################
# Summary
################################################################

message( "" )
message( "Summary:" )
message( "  EXECUTABLE_OUTPUT_PATH = ${EXECUTABLE_OUTPUT_PATH}" )
message( "  VALA_EXECUTABLE = ${VALA_EXECUTABLE}" )
message( "Libs:" )
message( "  GTK_LIBRARIES = ${GTK_LIBRARIES}" )
message( "  CAIRO_LIBRARIES = ${CAIRO_LIBRARIES}" )
message( "  GEE_LIBRARIES = ${GEE_LIBRARIES}" )
message( "  INDICATOR_LIBRARIES = ${INDICATOR_LIBRARIES}" )
message( "  RSVG_LIBRARIES = ${RSVG_LIBRARIES}" )
message( "  XML_LIBRARIES = ${XML_LIBRARIES}" )
message( "" )
