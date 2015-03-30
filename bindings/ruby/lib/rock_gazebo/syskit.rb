require 'rock_gazebo/orogen_model_from_sdf_world'
require 'sdf'
require 'orocos'
require 'syskit'
require 'rock_gazebo/syskit/world'
require 'rock_gazebo/syskit/world_manager'

module RockGazebo
    extend Logger::Root('RockGazebo', Logger::WARN)
end
