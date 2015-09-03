module RockGazebo
    module Syskit
        # Gazebo-specific extensions to {Syskit::Robot::RobotDefinition}
        module RobotDefinitionExtension
            # The name of the SDF world loaded with {#load_sdf}
            #
            # The default is 'world'
            #
            # @return [String]
            attr_reader :sdf_world_name

            # Given a sensor, returns the device and device driver model that
            # should be used to handle it
            #
            # @return [nil,(Model<Syskit::Device>,Model<Syskit::Component>)]
            #   either nil if this type of sensor is not handled either by the
            #   rock-gazebo plugin or by the syskit integration (yet), or the
            #   device model and device driver that should be used for this
            #   sensor
            def sensors_to_device(sensor)
                case sensor.type
                when 'ray'
                    require 'rock/models/devices/gazebo/ray'
                    return Rock::Devices::Gazebo::Ray, OroGen::RockGazebo::LaserScanTask
                end
            end

            # Create device information that models how the rock-gazebo plugin
            # will handle this SDF model
            #
            # I.e. it creates devices that match the tasks the rock-gazebo
            # plugin will create when given this SDF information
            #
            # It does it for all the models in 'world', and for links and
            # sensors only for 'model'
            #
            # @param [SDF::Model] robot_model the SDF model for this robot
            # @param [String] world_name the name of the SDF world we are
            #   running in
            # @param [String] name the name of the model in the world, if it
            #   differs from the robot_model name (e.g. if you have multiple
            #   instances of the same robot)
            # @param [Array<SDF::Model>] models a set of models that should be
            #   exposed as devices on this robot model. Note that sensors and
            #   links are only exposed for the robot_model. It must contain
            #   robot_model
            # @return [void]
            # @raise [ArgumentError] if models does not contain robot_model
            def load_sdf(robot_model, world_name: 'world', name: robot_model.name, models: [robot_model])
                @sdf_world_name = world_name.to_str

                expose_sdf_models(models, world_name: world_name)
                if !models.any? { |m| m.name == name }
                    raise ArgumentError, "the set of models given to #load_sdf has no model named #{name}"
                end
                load_sdf_robot_model(robot_model, name: name, world_name: world_name)
            end

            # @api private
            #
            # Define devices for each model in the world
            def expose_sdf_models(models, world_name: 'world')
                models.each do |m|
                    device(Rock::Devices::Gazebo::Model, as: m.name,
                           using: OroGen::RockGazebo::ModelTask).
                           prefer_deployed_tasks(/^gazebo:#{world_name}:#{m.name}$/).
                           advanced
                end
            end

            # @api private
            #
            # Define devices for all links and sensors in the model
            def load_sdf_robot_model(model, name: model.name, world_name: 'world')
                driver_m = OroGen::RockGazebo::ModelTask
                find_device(model.name).advanced = false
                model.each_link do |l|
                    link_driver_m = driver_m.specialize
                    frame_basename = l.name.gsub(/[^\w]+/, '_')
                    driver_srv = link_driver_m.require_dynamic_service(
                        'link_export', as: "#{l.name}_link", frame_basename: frame_basename)
                    link_driver_m = link_driver_m.to_instance_requirements.
                        prefer_deployed_tasks(/^gazebo:#{world_name}:#{name}$/).
                        with_arguments('model_dev' => find_device(name)).
                        use_frames("#{frame_basename}_source" => l.full_name,
                                   "#{frame_basename}_target" => world_name).
                        select_service(driver_srv)
                    device(Rock::Devices::Gazebo::Link, as: "#{l.name}_link", using: link_driver_m).
                        advanced
                end
                model.each_sensor do |s|
                    device_m, driver_m = sensors_to_device(s)
                    if device_m
                        device(device_m, as: "#{s.name}_sensor", using: driver_m).
                            prefer_deployed_tasks(/^gazebo:#{world_name}:#{name}:#{s.parent.name}:#{s.name}$/)
                    else
                        RockGazebo.warn "Robot#load_sdf: don't know how to handle sensor #{s.full_name} of type #{s.type}"
                    end
                end
            end
        end
        ::Syskit::Robot::RobotDefinition.include RobotDefinitionExtension
    end
end

