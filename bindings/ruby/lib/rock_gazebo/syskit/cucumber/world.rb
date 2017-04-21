require 'rock/gazebo'

module RockGazebo
    module Syskit
        module Cucumber
            module World
                attr_reader :gazebo_pid
                attr_reader :gazebo_ui_pid

                # Raised when a start/stop/join method is called while in a
                # wrong state
                class InvalidState < RuntimeError; end

                # Whether a gazebo instance is running
                def gazebo_running?
                    !!@gazebo_pid
                end

                # Start a Gazebo instance
                def gazebo_start(*args, ui: (ENV['CUCUMBER_VIZ'] && ENV['CUCUMBER_VIZ'] != '0'), working_directory: Dir.pwd)
                    if gazebo_running?
                        raise InvalidState, "a Gazebo instance is already running, stop it with {#gazebo_stop} and/or join it with {#gazebo_join}"
                    end

                    Tempfile.open 'rock_gazebo', working_directory do |tempfile|
                        if ui
                            model_path, filtered_args = Rock::Gazebo.resolve_worldfiles_and_models_arguments(args)
                            world_file = filtered_args.find { |p| p =~ /\.world$/ }
                            Rock::Gazebo.model_path
                            if ENV['CUCUMBER_VIZ'] != '1'
                                extra_options = Shellwords.shellsplit(ENV['CUCUMBER_VIZ'])
                            end
                            @gazebo_ui_pid = spawn('rock-gazebo-viz', '--no-start', world_file,
                                                   *Rock::Gazebo.model_path.flat_map { |p| ["--model-dir", p] },
                                                   *extra_options,
                                                   pgroup: 0,
                                                   chdir: working_directory,
                                                   out: tempfile,
                                                   err: tempfile)
                        end
                        @gazebo_pid = Rock::Gazebo.spawn(
                            'gzserver', *args, pgroup: 0,
                            chdir: working_directory,
                            out: tempfile,
                            err: tempfile)
                        FileUtils.mv tempfile, File.join(working_directory, "#{File.basename('gzserver')}.#{@gazebo_pid}.txt")
                    end
                ensure
                    if gazebo_ui_pid && !gazebo_pid
                        Process.kill('INT', gazebo_ui_pid) 
                        @gazebo_ui_pid = nil
                    end
                end

                # Stop the running Gazebo instance
                def gazebo_stop(join: true)
                    if !gazebo_running?
                        raise InvalidState, "gazebo is not running"
                    end

                    Process.kill('INT', gazebo_ui_pid) if gazebo_ui_pid
                    Process.kill('INT', gazebo_pid)
                    if join
                        gazebo_join
                    end
                end

                # Wait for the gazebo instance to quit
                def gazebo_join
                    if !gazebo_running?
                        raise InvalidState, "cannot call #gazebo_join without a running Gazebo instance"
                    end

                    _, status = Process.waitpid2(gazebo_pid)
                    @gazebo_pid = nil
                    @gazebo_ui_pid = nil
                    status
                rescue Errno::ECHILD
                    @gazebo_pid = nil
                    @gazebo_ui_pid = nil
                end

                # Wait for the remote process to quit
                #
                # It raises an exception if the process does not terminate
                # successfully
                def gazebo_join!
                    if (status = gazebo_join) && !status.success?
                        raise InvalidState, "Gazebo process exited with status #{status}"
                    end
                rescue Errno::ENOCHILD
                    @gazebo_pid = nil
                end
            end
        end
    end
end

After do |scenario|
    if kind_of?(RockGazebo::Syskit::Cucumber::World)
        gazebo_stop if gazebo_running?
    end
end

