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

add_library(RockVelocityPlugin SHARED src/gazebo_plugin_velocity.cpp)
target_link_libraries(RockVelocityPlugin ${GAZEBO_LIBRARIES} ${Boost_LIBRARIES})

install(TARGETS RockVelocityPlugin
		PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_WRITE GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
		LIBRARY DESTINATION $ENV{AUTOPROJ_CURRENT_ROOT}/simulation/gazebo/build/plugins)
