require 'rock/gazebo'

module RockGazebo
    module Syskit
        module Cucumber
            module World
                attr_reader :gazebo_pid

                # Raised when a start/stop/join method is called while in a
                # wrong state
                class InvalidState < RuntimeError; end

                # Whether a gazebo instance is running
                def gazebo_running?
                    !!@gazebo_pid
                end

                # Start a Gazebo instance
                def gazebo_start(*args, ui: false, working_directory: Dir.pwd)
                    if gazebo_running?
                        raise InvalidState, "a Gazebo instance is already running, stop it with {#gazebo_stop} and/or join it with {#gazebo_join}"
                    end

                    bin_name =
                        if ui then 'gazebo'
                        else 'gzserver'
                        end

                    Tempfile.open 'rock_gazebo', working_directory do |tempfile|
                        @gazebo_pid = Rock::Gazebo.spawn(bin_name, *args, pgroup: 0,
                                                         chdir: working_directory)
                        FileUtils.mv tempfile, File.join(working_directory, "#{File.basename(bin_name)}.#{@gazebo_pid}.txt")
                    end
                end

                # Stop the running Gazebo instance
                def gazebo_stop(join: true)
                    if !gazebo_running?
                        raise InvalidState, "gazebo is not running"
                    end

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
                    status
                rescue Errno::ECHILD
                    @gazebo_pid = nil
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

