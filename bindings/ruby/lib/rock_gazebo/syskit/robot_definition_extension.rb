module RockGazebo
    module Syskit
        # Gazebo-specific extensions to {Syskit::Robot::RobotDefinition}
        module RobotDefinitionExtension
            # Given a sensor, returns the device and device driver model that
            # should be used to handle it
            #
            # @return [nil,(Model<Syskit::Device>,Model<Syskit::Component>)]
            #   either nil if this type of sensor is not handled either by the
            #   rock-gazebo plugin or by the syskit integration (yet), or the
            #   device model and device driver that should be used for this
            #   sensor
            def sensors_to_device(sensor, device_name, frame_name)
                case sensor.type
                when 'ray'
                    require 'rock/models/devices/gazebo/ray'
                    device(Rock::Devices::Gazebo::Ray, as: device_name, using: OroGen::RockGazebo::LaserScanTask).
                        frame(frame_name)
                when 'imu'
                    require 'rock/models/devices/gazebo/imu'
                    device(Rock::Devices::Gazebo::Imu, as: device_name, using: OroGen::RockGazebo::ImuTask).
                        frame_transform(frame_name => 'world')
                when 'camera'
                    require 'rock/models/devices/gazebo/camera'
                    device(Rock::Devices::Gazebo::Camera, as: device_name, using: OroGen::RockGazebo::CameraTask).
                        frame(frame_name)
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
            # @param [String] name the name of the model in the world, if it
            #   differs from the robot_model name (e.g. if you have multiple
            #   instances of the same robot)
            # @param [Array<SDF::Model>] models a set of models that should be
            #   exposed as devices on this robot model. Note that sensors and
            #   links are only exposed for the robot_model. It must contain
            #   robot_model
            # @return [void]
            # @raise [ArgumentError] if models does not contain robot_model
            def load_gazebo(robot_model, deployment_prefix, name: robot_model.name, models: [robot_model])
                if !models.any? { |m| m.name == name }
                    raise ArgumentError, "the set of models given to #load_gazebo has no model named #{name}"
                end

                expose_gazebo_models(models, deployment_prefix)
                load_gazebo_robot_model(robot_model, deployment_prefix, name: name)
            end

            # @api private
            #
            # Define devices for each model in the world
            def expose_gazebo_models(models, deployment_prefix)
                models.each do |m|
                    device(Rock::Devices::Gazebo::Model, as: m.name,
                           using: OroGen::RockGazebo::ModelTask).
                           prefer_deployed_tasks("#{deployment_prefix}:#{m.name}").
                           advanced
                end
            end

            # @api private
            #
            # Define devices for all links and sensors in the model
            def load_gazebo_robot_model(model, deployment_prefix, name: model.name)
                driver_m = OroGen::RockGazebo::ModelTask
                find_device(model.name).advanced = false
                model.each_link do |l|
                    link_driver_m = driver_m.specialize
                    frame_basename = l.name.gsub(/[^\w]+/, '_')
                    driver_srv = link_driver_m.require_dynamic_service(
                        'link_export', as: "#{l.name}_link", frame_basename: frame_basename)
                    link_driver_m = link_driver_m.to_instance_requirements.
                        prefer_deployed_tasks("#{deployment_prefix}:#{name}").
                        with_arguments('model_dev' => find_device(name)).
                        use_frames("#{frame_basename}_source" => l.full_name,
                                   "#{frame_basename}_target" => 'world').
                        select_service(driver_srv)
                    device(Rock::Devices::Gazebo::Link, as: "#{l.name}_link", using: link_driver_m).
                        advanced
                end
                model.each_sensor do |s|
                    if device = sensors_to_device(s, "#{s.name}_sensor", s.parent.full_name)
                        device.prefer_deployed_tasks("#{deployment_prefix}:#{name}:#{s.name}")
                    else
                        RockGazebo.warn "Robot#load_gazebo: don't know how to handle sensor #{s.full_name} of type #{s.type}"
                    end
                end
            end
        end
        ::Syskit::Robot::RobotDefinition.include RobotDefinitionExtension
    end
end

