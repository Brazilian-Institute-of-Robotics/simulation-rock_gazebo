module RockGazebo
    module Syskit
        module ConfigurationExtension
            ::Robot.config do
                if Conf.sdf.world_path?
                    world_path = Conf.sdf.world_path
                end
                Conf.sdf = SDF.new
                if world_path
                    Conf.sdf.world_path = world_path
                end
                Conf.gazebo.use_sim_time = false
            end

            # Load a SDF world into the Syskit instance
            def use_sdf_world(*path, world_name: nil)
                if Conf.sdf.world_file_path
                    raise LoadError, "use_sdf_world already called"
                elsif Conf.sdf.has_profile_loaded?
                    raise LoadError, "you need to call #use_sdf_world before require'ing any profile that uses #use_sdf_model"
                end

                if Conf.sdf.world_path
                    override_path = Conf.sdf.world_path
                    Robot.info "world_file_path set on Conf.sdf.world_path with value #{override_path}, overriding the parameter #{File.join(*path)} given to #use_sdf_world"
                    path = override_path
                end

                Conf.sdf.load_sdf(*path, world_name: world_name)
            end

            # Sets up Syskit to use gazebo configured to use the given world 
            #
            # @return [Syskit::Deployment] a deployment object that represents
            #   gazebo itself
            def use_gazebo_world(*path, world_name: nil, localhost: Conf.gazebo.localhost?)
                world = use_sdf_world(*path, world_name: world_name)
                deployment_model = ConfigurationExtension.world_to_orogen(world)

                if !has_process_server?('gazebo')
                    if localhost
                        options = Hash[host_id: 'localhost'] 
                    else
                        options = Hash.new
                    end
                    ::Syskit.conf.register_process_server(
                        'gazebo', ::Syskit::RobyApp::UnmanagedTasksManager.new, app.log_dir, **options)
                end

                process_server_config =
                    if app.simulation?
                        sim_process_server('gazebo')
                    else
                        process_server_config_for('gazebo')
                    end

                configured_deployment = ::Syskit::Models::ConfiguredDeployment.
                    new(process_server_config.name, deployment_model, Hash[], "gazebo:#{world.name}", Hash.new)
                register_configured_deployment(configured_deployment)
                configured_deployment
            end

            def self.world_from_path(path, world_name: nil)
                worlds = ::SDF::Root.load(path).each_world.to_a
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

