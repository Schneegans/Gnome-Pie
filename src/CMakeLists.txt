################################################################
# Actually compile the executable
################################################################

# determine source and header files
file(GLOB VALA_SRC RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.vala */*.vala)

# use valac to compile sources to c files
vala_precompile(
    VALA_C
        ${VALA_SRC} 
    PACKAGES 
        appindicator-0.1
        gtk+-2.0 
        gdk-2.0 
        gdk-x11-2.0 
        cairo 
        gee-1.0
        x11
        gio-unix-2.0
        posix
        libxml-2.0
        xtst
        libgnome-menu
    OPTIONS
        --vapidir=${CMAKE_SOURCE_DIR}/vapi/
        --thread
)

# compile c-sources
add_executable(gnome-pie ${VALA_C})

# install executable
install(
	TARGETS 
		gnome-pie
	RUNTIME DESTINATION
		${CMAKE_INSTALL_PREFIX}/bin
)

# install credits
install(
	FILES
		${CMAKE_SOURCE_DIR}/README
	DESTINATION
		${CMAKE_INSTALL_PREFIX}/share/doc/gnome-pie
)

# install locales
install(
	DIRECTORY 
		${CMAKE_SOURCE_DIR}/resources/locale
	DESTINATION 
		${CMAKE_INSTALL_PREFIX}/share
	PATTERN *.po EXCLUDE
	PATTERN *.pot EXCLUDE
	PATTERN *.sh EXCLUDE
)

# install themes
install(
	DIRECTORY 
		${CMAKE_SOURCE_DIR}/resources/themes
	DESTINATION 
		${CMAKE_INSTALL_PREFIX}/share/gnome-pie
)

# install default configuration file
install(
	FILES
		${CMAKE_SOURCE_DIR}/resources/pies.conf.default
	DESTINATION
		${CMAKE_INSTALL_PREFIX}/share/gnome-pie
)

# install icons
install(
	FILES
		${CMAKE_SOURCE_DIR}/resources/gnome-pie.svg
		${CMAKE_SOURCE_DIR}/resources/gnome-pie-indicator.svg
	DESTINATION
		${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/apps
)

# desktop file
install(
	FILES
		${CMAKE_SOURCE_DIR}/resources/gnome-pie.desktop
	DESTINATION
		${CMAKE_INSTALL_PREFIX}/share/applications
)

