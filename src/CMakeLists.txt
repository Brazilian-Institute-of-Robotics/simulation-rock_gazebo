rock_library(rock_gazebo
	SOURCES RockBridge.cpp
	HEADERS RockBridge.hpp
	DEPS_PKGCONFIG gazebo
                orocos-rtt-gnulinux
                orocos-rtt-corba-gnulinux
                rock_gazebo-tasks-gnulinux
                std-typekit-gnulinux
                std-transport-corba-gnulinux 
                std-transport-mqueue-gnulinux 
                std-transport-typelib-gnulinux 
                base-typekit-gnulinux
                base-transport-corba-gnulinux 
                base-transport-mqueue-gnulinux 
                base-transport-typelib-gnulinux 
                rock_gazebo-typekit-gnulinux
                rock_gazebo-transport-corba-gnulinux
                rock_gazebo-transport-mqueue-gnulinux
                rock_gazebo-transport-typelib-gnulinux
	DEPS_CMAKE Boost)

configure_file(rock-gzserver.in rock-gzserver @ONLY)
configure_file(rock-gazebo.in rock-gazebo @ONLY)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/rock-gzserver ${CMAKE_CURRENT_BINARY_DIR}/rock-gazebo
        DESTINATION bin
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                    GROUP_READ GROUP_EXECUTE
                    WORLD_READ WORLD_EXECUTE)
