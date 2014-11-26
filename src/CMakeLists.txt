rock_library(RockBridgePlugin
	SOURCES RockBridge.cpp
	HEADERS RockBridge.hpp
	DEPS_PKGCONFIG gazebo
                orocos-rtt-gnulinux
                orocos-rtt-corba-gnulinux
                gazebo-tasks-gnulinux
                std-typekit-gnulinux
                std-transport-corba-gnulinux 
                std-transport-mqueue-gnulinux 
                std-transport-typelib-gnulinux 
                base-typekit-gnulinux
                base-transport-corba-gnulinux 
                base-transport-mqueue-gnulinux 
                base-transport-typelib-gnulinux 
                gazebo-typekit-gnulinux
                gazebo-transport-corba-gnulinux 
                gazebo-transport-mqueue-gnulinux 
                gazebo-transport-typelib-gnulinux 
	DEPS_CMAKE Boost)

configure_file(rock-gzserver.in rock-gzserver @ONLY)
configure_file(rock-gazebo.in rock-gazebo @ONLY)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/rock-gzserver ${CMAKE_CURRENT_BINARY_DIR}/rock-gazebo
        DESTINATION bin
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                    GROUP_READ GROUP_EXECUTE
                    WORLD_READ WORLD_EXECUTE)
