module RockGazebo
    module Syskit
        module ConfigurationExtension
            # Sets up Syskit to use gazebo configured to use the given world 
            #
            # @return [Syskit::Deployment] a deployment object that represents
            #   gazebo itself
            def use_gazebo_world(*path, world_name: nil)
                if Conf.gazebo.world?
                    raise LoadError, "use_gazebo_world already called"
                elsif Conf.gazebo.has_profile_loaded?
                    raise LoadError, "you need to call #use_gazebo_world before require'ing any profile that uses #use_sdf_model"
                end

                if Conf.gazebo.world_file_path?
                    override_path = Conf.gazebo.world_file_path
                    Robot.info "world_file_path set on Conf.gazebo with value #{override_path}, overriding the parameter #{File.join(*path)} given to #use_gazebo_world"
                    path = override_path
                end

                _, resolved_paths = Rock::Gazebo.resolve_worldfiles_and_models_arguments([File.join(*path)])
                full_path = resolved_paths.first
                if !File.file?(full_path)
                    raise ArgumentError, "#{File.join(*path)} cannot be resolved to a valid gazebo world"
                end
                SDF::XML.model_path = Rock::Gazebo.model_path

                world = ConfigurationExtension.world_from_path(full_path)
                deployment_model = ConfigurationExtension.world_to_orogen(world)

                configured_deployment = ::Syskit::Models::ConfiguredDeployment.
                    new('unmanaged_tasks', deployment_model, Hash[], deployment_model.name, Hash.new)
                register_configured_deployment(configured_deployment)
                Conf.gazebo.world_file_path = full_path
                Conf.gazebo.world = world
                configured_deployment
            end

            def self.world_from_path(path, world_name: nil)
                worlds = SDF::Root.load(path).each_world.to_a
                if world_name
                    world = worlds.find { |w| w.name == world_name }
                    if !world
                        raise ArgumentError, "cannot find a world named #{world_name} in #{path}"
                    end
                    return world
                elsif worlds.size == 1
                    return worlds.first
                elsif worlds.empty?
                    raise ArgumentError, "no worlds declared in #{path}"
                else
                    raise ArgumentError, "more than one world declared in #{path}, select one explicitely by providing the world_name argument"
                end
            end

            def self.world_to_orogen(world)
                ::Syskit::Deployment.new_submodel(name: "Deployment::Gazebo::#{world.name}") do
                    RockGazebo.setup_orogen_model_from_sdf_world(self, world)
                end
            end
        end

        ::Syskit::RobyApp::Configuration.include ConfigurationExtension
    end
end

