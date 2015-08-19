module RockGazebo
    module Syskit
        module RobotDefinitionExtension
            attr_reader :sdf_world_name

            def load_sdf(sdf)
                sdf.each_model(recursive: true) do |m|
                    device(Rock::Devices::Gazebo::Model, as: m.name,
                           using: OroGen::RockGazebo::ModelTask).
                           prefer_deployed_tasks(/^gazebo:\w+:#{m.name}$/)
                end
                @sdf_world_name =
                    if world = sdf.each_world.first
                        world.name
                    else
                        'world'
                    end
            end
        end
        ::Syskit::Robot::RobotDefinition.include RobotDefinitionExtension
    end
end

