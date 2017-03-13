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
                when 'gps'
                    require 'rock/models/devices/gazebo/gps'
                    device(Rock::Devices::Gazebo::GPS, as: device_name, using: OroGen::RockGazebo::GPSTask).
                        frame_transform(frame_name => 'world')
                end
            end

            # Setup a link export feature of rock_gazebo::ModelTask
            #
            # @param [Syskit::Robot::MasterDeviceInstance] model_dev the model device that has the requested links
            # @param [String] as the name of the newly created device. It is
            #   also the name of the created port on the model task
            # @param [String] from_frame the 'from' frame of the exported link,
            #   which must match a link, model or frame name on the SDF model
            # @param [String] to_frame the 'to' frame of the exported link,
            #   which must match a link, model or frame name on the SDF model
            # @return [Syskit::Robot::MasterDeviceInstance] the exported link as
            #   a device instance of type Rock::Devices::Gazebo::Link
            def sdf_export_link(model_dev, as: nil, from_frame: nil, to_frame: nil, cov_position: nil, cov_orientation: nil, cov_velocity: nil)
                if !as
                    raise ArgumentError, "provide a name for the device and port through the 'as' option"
                elsif !from_frame
                    raise ArgumentError, "provide a name for the 'from' frame through the 'from_frame' option"
                elsif !to_frame
                    raise ArgumentError, "provide a name for the 'to' frame through the 'to_frame' option"
                end

                link_driver = model_dev.to_instance_requirements.to_component_model.dup
                link_driver_m = OroGen::RockGazebo::ModelTask.specialize
                link_driver_srv = link_driver_m.require_dynamic_service(
                    'link_export', as: as, frame_basename: as,
                    cov_position: cov_position, cov_orientation: cov_orientation,
                    cov_velocity: cov_velocity)

                link_driver.add_models([link_driver_m])
                link_driver.
                    use_frames("#{as}_source" => from_frame,
                               "#{as}_target" => to_frame).
                               select_service(link_driver_srv)

                dev = device(Rock::Devices::Gazebo::Link, as: as, using: link_driver)
                if from_frame != to_frame
                    dev.frame_transform(from_frame => to_frame)
                end
                dev
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
            #
            # @param [Array<SDF::Model>] models the SDF representation of the models
            def expose_gazebo_models(models, deployment_prefix)
                models.each do |m|
                    device(Rock::Devices::Gazebo::Model, as: m.name,
                           using: OroGen::RockGazebo::ModelTask).
                           prefer_deployed_tasks("#{deployment_prefix}:#{m.name}").
                           advanced.
                           sdf(m)
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
                        if period = s.update_period
                            device.period(period)
                        end
                        device.sdf(s).prefer_deployed_tasks("#{deployment_prefix}:#{name}:#{s.name}")
                    else
                        RockGazebo.warn "Robot#load_gazebo: don't know how to handle sensor #{s.full_name} of type #{s.type}"
                    end
                end
            end
        end
        ::Syskit::Robot::RobotDefinition.include RobotDefinitionExtension
    end
end

