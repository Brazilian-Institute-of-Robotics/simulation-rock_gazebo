require 'rock_gazebo/orogen_model_from_sdf_world'
require 'sdf'
require 'orocos'
require 'syskit'
require 'rock_gazebo/syskit/world'
require 'rock_gazebo/syskit/world_manager'
require 'rock_gazebo/syskit/configuration_extension'

module RockGazebo
    extend Logger::Root('RockGazebo', Logger::WARN)

    module Syskit
        include Logger::Hierarchy
    end
end
