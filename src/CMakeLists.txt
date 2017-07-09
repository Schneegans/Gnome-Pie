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
        ${VALA_PKGS}
    OPTIONS
        --thread
        ${VALA_DEFINES}
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
        ${CMAKE_SOURCE_DIR}/README.md
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

# install UI files
install(
    DIRECTORY
        ${CMAKE_SOURCE_DIR}/resources/ui
    DESTINATION
        ${CMAKE_INSTALL_PREFIX}/share/gnome-pie
)

# install icons
install(
    FILES
        ${CMAKE_SOURCE_DIR}/resources/gnome-pie.svg
        ${CMAKE_SOURCE_DIR}/resources/gnome-pie-symbolic.svg
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

# install manpage
install(
    FILES
        ${CMAKE_SOURCE_DIR}/resources/gnome-pie.1
    DESTINATION
        ${CMAKE_INSTALL_PREFIX}/share/man/man1
)

