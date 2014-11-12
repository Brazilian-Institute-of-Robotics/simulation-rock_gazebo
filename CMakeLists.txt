cmake_minimum_required(VERSION 2.8 FATAL_ERROR)

find_package(Boost REQUIRED COMPONENTS system)
include_directories(${Boost_INCLUDE_DIRS})
link_directories(${Boost_LIBRARY_DIRS})

include(FindPkgConfig)
if(PKG_CONFIG_FOUND)
	pkg_check_modules(GAZEBO gazebo)
	#pkg_check_modules(SDF sdformat)
endif()

include_directories(${GAZEBO_INCLUDE_DIRS})
link_directories(${GAZEBO_LIBRARY_DIRS})

find_package(orocos-rtt)
include_directories(${orocos-rtt-gnulinux_INCLUDE_DIRS})
link_directories(${orocos-rtt-gnulinux_LIBRARY_DIRS})

#include_directories(~/rock/install/include)

add_library(RockBridgePlugin SHARED src/RockBridge.cpp)
target_link_libraries(RockBridgePlugin ${GAZEBO_LIBRARIES} ${Boost_LIBRARIES} ${orocos-rtt_LIBRARIES})
