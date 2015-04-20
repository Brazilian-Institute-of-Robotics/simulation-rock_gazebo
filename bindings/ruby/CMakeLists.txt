rock_add_ruby_package(rock_gazebo)
rock_add_ruby_package(rock)
if (rock_AVAILABLE)
    install(PROGRAMS bin/rock-gazebo-viz bin/rock-gazebo-run
        DESTINATION bin)
endif()

