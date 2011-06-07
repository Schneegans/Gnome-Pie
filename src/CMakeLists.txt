################################################################
# Actually compile the executable
################################################################

# determine source and header files
file(GLOB VALA_SRC RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.vala)

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
)

add_executable(gnome-pie ${VALA_C})
