rock_library(rock_gazebo
	SOURCES RockBridge.cpp
	HEADERS RockBridge.hpp
	DEPS_PKGCONFIG gazebo
                orocos-rtt-gnulinux
                orocos-rtt-corba-gnulinux
                std-typekit-gnulinux
                std-transport-corba-gnulinux 
                std-transport-mqueue-gnulinux 
                std-transport-typelib-gnulinux 
                base-typekit-gnulinux
                base-transport-corba-gnulinux 
                base-transport-mqueue-gnulinux 
                base-transport-typelib-gnulinux 
                gps_base-typekit-gnulinux
                gps_base-transport-corba-gnulinux 
                gps_base-transport-mqueue-gnulinux 
                gps_base-transport-typelib-gnulinux 
                rock_gazebo-tasks-gnulinux
                rock_gazebo-typekit-gnulinux
                rock_gazebo-transport-corba-gnulinux
                rock_gazebo-transport-mqueue-gnulinux
                rock_gazebo-transport-typelib-gnulinux
                logger-tasks-gnulinux
                logger-typekit-gnulinux
                logger-transport-corba-gnulinux
                logger-transport-mqueue-gnulinux
                logger-transport-typelib-gnulinux
	DEPS_CMAKE Boost)
