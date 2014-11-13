rock_library(RockBridgePlugin
	SOURCES RockBridge.cpp
	HEADERS RockBridge.hpp
	DEPS_PKGCONFIG orocos-rtt-gnulinux gazebo
	DEPS_CMAKE Boost
	NOINSTALL)
