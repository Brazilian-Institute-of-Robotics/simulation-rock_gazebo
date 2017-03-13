require 'minitest/autorun'
require 'orocos/test/component'
require 'minitest/spec'
require 'rock/gazebo'

module Helpers
    def setup
        Orocos.initialize if !Orocos.initialized?
        @gazebo_output = Tempfile.open 'rock_gazebo'
    end

    def teardown
        if !passed?
            @gazebo_output.rewind
            puts @gazebo_output.read
        end

        if @gazebo_pid
            begin
                Process.kill 'INT', @gazebo_pid
                Process.waitpid @gazebo_pid
            rescue Errno::ESRCH, Errno::ECHILD
            end
        end
        @gazebo_output.close
    end

    def expand_fixture_world(path)
        fixture_world_dir = File.expand_path('worlds', __dir__)
        return File.expand_path(path, fixture_world_dir)
    end
 
    def gzserver(world_file, expected_task_name, timeout: 10)
        @gazebo_pid = Rock::Gazebo.spawn('gzserver', expand_fixture_world(world_file), '--verbose',
                                         out: @gazebo_output,
                                         err: @gazebo_output)

        deadline = Time.now + timeout
        begin
            sleep 0.01
            begin return Orocos.get(expected_task_name)
            rescue Orocos::NotFound
            end
            begin
                if status = Process.waitpid(@gazebo_pid, Process::WNOHANG)
                    gazebo_flunk("gzserver terminated before '#{expected_task_name}' could be reached")
                end
            rescue Errno::ECHILD
                gazebo_flunk("gzserver failed to start")
            end
        end while Time.now < deadline
        gazebo_flunk("failed to gazebo_reach task '#{expected_task_name}' within #{timeout} seconds, available tasks: #{Orocos.name_service.names.join(", ")}")
    end

    def gazebo_flunk(message)
        @gazebo_output.rewind
        puts @gazebo_output.read
        flunk(message)
    end

    def matrix3_rand
        values = (0...9).map { rand.abs }
        Types.base.Matrix3d.new(data: values)
    end

    def assert_matrix3_in_delta(expected, actual, delta = 1e-9)
        9.times do |i|
            assert_in_delta expected.data[i], actual.data[i], delta, "element #{i} differs by more than #{delta}"
        end
    end
end



