require "rock/gazebo"
require 'rock_gazebo/orogen_model_from_sdf_world'
require 'sdf'
require 'orocos'
require 'syskit'
require 'rock/models/devices/gazebo/model'
require 'transformer/sdf'
require 'rock_gazebo/syskit/configuration_extension'
require 'rock_gazebo/syskit/profile_extension'
require 'rock_gazebo/syskit/robot_definition_extension'

module RockGazebo
    extend Logger::Root('RockGazebo', Logger::WARN)

    module Syskit
        include Logger::Hierarchy
    end
end
