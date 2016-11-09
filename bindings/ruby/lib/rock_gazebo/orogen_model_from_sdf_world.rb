module RockGazebo
    # Creation of an oroGen deployment model representing what the
    # rock-gazebo plugin would do from a SDF world
    #
    # @param [String] name the name that should be used as deployment name
    # @param [SDF::World] world the SDF world that we have to represent
    # @param [OroGen::Loaders::Base] loader the oroGen loader that we should use
    #   to create the tasks
    # @return [OroGen::Spec::Deployment]
    def self.orogen_model_from_sdf_world(name, world, loader: Orocos.default_loader, period: 0.1)
        project = OroGen::Spec::Project.new(loader)
        project.using_task_library 'rock_gazebo'
        deployment = project.deployment(name)
        setup_orogen_model_from_sdf_world(deployment, world, period: 0.1)
    end

    def self.setup_orogen_model_from_sdf_world(deployment, world, period: 0.1)
        deployment.task("gazebo:#{world.name}", "rock_gazebo::WorldTask").
            periodic(period)
        world.each_model do |model|
            deployment.task("gazebo:#{world.name}:#{model.name}", "rock_gazebo::ModelTask").
                periodic(period)

            model.each_sensor do |sensor|
                if sensor.type == 'ray'
                    deployment.task("gazebo:#{world.name}:#{model.name}:#{sensor.name}", "rock_gazebo::LaserScanTask").
                        periodic(period)
                elsif sensor.type == 'camera'
                    deployment.task("gazebo:#{world.name}:#{model.name}:#{sensor.name}", "rock_gazebo::CameraTask").
                        periodic(period)
                elsif sensor.type == 'imu'
                    deployment.task("gazebo:#{world.name}:#{model.name}:#{sensor.name}", "rock_gazebo::ImuTask").
                        periodic(period)
                end
            end
            model.each_plugin do |plugin|
                if plugin.filename =~ /gazebo_thruster/
                    deployment.task("gazebo:#{world.name}:#{model.name}:#{plugin.name}", "rock_gazebo::ThrusterTask").
                        periodic(period)
                end
            end
        end

        deployment
    end
end

