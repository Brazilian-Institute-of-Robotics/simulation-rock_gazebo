module RockGazebo
    module Syskit
        module ConfigurationExtension
            def use_gazebo_world(*path)
                app.find_dirs('models', 'sdf', order: :specific_first, all: true).each do |model_dir|
                    if !SDF::XML.model_path.include?(model_dir)
                        SDF::XML.model_path.unshift model_dir
                    end
                end

                full_path = File.expand_path(File.join(*path))
                if !File.exists?(full_path)
                    full_path = Roby.app.find_file(*path, order: :specific_first) ||
                        Roby.app.find_file('scenes', *path, order: :specific_first)

                    if !full_path
                        raise ArgumentError, "cannot find #{File.join(*path)}"
                    end
                end

                # Add the process manager if needed
                if !has_process_server?('gazebo')
                    register_process_server('gazebo', WorldManager.new(app.default_loader), 'logs')
                end

                world_manager = process_server_for('gazebo')
                orogen = world_manager.register_world(full_path)
                use_deployment(orogen, on: 'gazebo')
            end
        end

        ::Syskit::RobyApp::Configuration.include ConfigurationExtension
    end
end

