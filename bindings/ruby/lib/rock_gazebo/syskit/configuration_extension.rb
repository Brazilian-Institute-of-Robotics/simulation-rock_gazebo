module RockGazebo
    module Syskit
        module ConfigurationExtension
            # Sets up Syskit to use gazebo configured to use the given world 
            #
            # @return [Syskit::Deployment] a deployment object that represents
            #   gazebo itself
            def use_gazebo_world(*path)
                if Conf.gazebo.has_profile_loaded?
                    raise LoadError, "you need to call #use_gazebo_world before require'ing any profile that uses #use_sdf_model"
                end

                _, resolved_paths = Rock::Gazebo.resolve_worldfiles_and_models_arguments([File.join(*path)])
                full_path = resolved_paths.first
                if !File.file?(full_path)
                    raise ArgumentError, "#{File.join(*path)} cannot be resolved to a valid gazebo world"
                end
                SDF::XML.model_path = Rock::Gazebo.model_path

                # Add the process manager if needed
                if !has_process_server?('gazebo')
                    register_process_server('gazebo', WorldManager.new(app.default_loader), app.log_dir)
                end

                world_manager = process_server_for('gazebo')
                orogen, world = world_manager.register_world(full_path)
                deployment = use_deployment(orogen, on: 'gazebo')
                Conf.gazebo.world_file_path = full_path
                Conf.gazebo.world = world
                deployment
            end
        end

        ::Syskit::RobyApp::Configuration.include ConfigurationExtension
    end
end

