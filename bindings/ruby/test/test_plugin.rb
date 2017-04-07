require 'helpers'

describe "The Rock/Gazebo plugin" do
    include Helpers
    include Orocos::Test::Component

    describe "Models" do
        attr_reader :task
        before do
            @task = gzserver 'model.world', '/gazebo:w:m'
        end

        it "exports the model using a ModelTask" do
            assert_equal "rock_gazebo::ModelTask", task.model.name
        end

        def configure_start_and_read_one_sample(port_name)
            task.configure
            task.start
            reader = task.port(port_name).reader
            assert_has_one_new_sample reader
        end

        describe "the pose export" do
            it "exports the pose" do
                pose = configure_start_and_read_one_sample 'pose_samples'
                assert Eigen::Vector3.new(1, 2, 3).approx?(pose.position)
                assert Eigen::Quaternion.from_angle_axis(0.1, Eigen::Vector3.UnitZ).
                    approx?(pose.orientation)
            end

            it "sets the model's cov_position from the component's cov_position property" do
                cov = matrix3_rand
                task.cov_position = cov
                pose = configure_start_and_read_one_sample 'pose_samples'
                assert_matrix3_in_delta cov, pose.cov_position
            end

            it "sets the model's cov_orientation from the component's cov_orientation property" do
                cov = matrix3_rand
                task.cov_orientation = cov
                pose = configure_start_and_read_one_sample 'pose_samples'
                assert_matrix3_in_delta cov, pose.cov_orientation
            end

            it "sets the model's cov_velocity from the component's cov_velocity property" do
                cov = matrix3_rand
                task.cov_velocity = cov
                pose = configure_start_and_read_one_sample 'pose_samples'
                assert_matrix3_in_delta cov, pose.cov_velocity
            end
        end

        describe "the link export" do
            before do
            end

            it "exports a link's pose" do
                task.exported_links = [Types.rock_gazebo.LinkExport.new(
                    port_name: 'test', source_link: 'l', target_link: 'root',
                    port_period: Time.at(0))]
                link_pose = configure_start_and_read_one_sample 'test'
                assert Eigen::Vector3.new(2, 3, 4).approx?(link_pose.position)
                assert Eigen::Quaternion.from_angle_axis(0.2, Eigen::Vector3.UnitZ).
                    approx?(link_pose.orientation)
            end

            it "the pose's update period is controlled by the port_period parameter" do
                task.exported_links = [Types.rock_gazebo.LinkExport.new(
                    port_name: 'test', source_link: 'l', target_link: 'root',
                    port_period: Time.at(0.1))]
                task.configure
                task.start
                reader = task.test.reader
                first_pose = assert_has_one_new_sample(reader)
                second_pose = assert_has_one_new_sample(reader)
                assert_in_delta(second_pose.time - first_pose.time, 0.1, 0.025)
            end

            it "refuses to configure if the source link does not exist" do
                task.exported_links = [Types.rock_gazebo.LinkExport.new(
                    port_name: 'test', source_link: 'does_not_exist', target_link: 'root')]
                assert_raises(Orocos::StateTransitionFailed) do
                    task.configure
                end
            end

            it "refuses to configure if the target link does not exist" do
                task.exported_links = [Types.rock_gazebo.LinkExport.new(
                    port_name: 'test', source_link: 'l', target_link: 'does_not_exist')]
                assert_raises(Orocos::StateTransitionFailed) do
                    task.configure
                end
            end

            it "refuses to configure if the port is already in use" do
                task.exported_links = [
                    Types.rock_gazebo.LinkExport.new(
                        port_name: 'test', source_link: 'l', target_link: 'root'),
                    Types.rock_gazebo.LinkExport.new(
                        port_name: 'test', source_link: 'l', target_link: 'root')
                ]
                assert_raises(Orocos::StateTransitionFailed) do
                    task.configure
                end
            end

            it "uses the link names as frames by default" do
                task.exported_links = [Types.rock_gazebo.LinkExport.new(
                    port_name: 'test', source_link: 'l', target_link: 'root',
                    port_period: Time.at(0))]
                pose = configure_start_and_read_one_sample 'test'
                assert_equal 'l', pose.sourceFrame
                assert_equal 'root', pose.targetFrame
            end

            it "allows to override the frame names" do
                task.exported_links = [Types.rock_gazebo.LinkExport.new(
                    port_name: 'test', source_link: 'l', target_link: 'root',
                    source_frame: 'src', target_frame: 'target',
                    port_period: Time.at(0))]
                pose = configure_start_and_read_one_sample 'test'
                assert_equal 'src', pose.sourceFrame
                assert_equal 'target', pose.targetFrame
            end

            it "sets cov_position from the provided cov_position" do
                cov = matrix3_rand
                task.exported_links = [Types.rock_gazebo.LinkExport.new(
                    port_name: 'test', source_link: 'l', target_link: 'root',
                    cov_position: cov, port_period: Time.at(0))]
                pose = configure_start_and_read_one_sample 'test'
                assert_matrix3_in_delta cov, pose.cov_position, 1e-6
            end

            it "sets cov_orientation from the provided cov_orientation" do
                cov = matrix3_rand
                task.exported_links = [Types.rock_gazebo.LinkExport.new(
                    port_name: 'test', source_link: 'l', target_link: 'root',
                    cov_orientation: cov, port_period: Time.at(0))]
                pose = configure_start_and_read_one_sample 'test'
                assert_matrix3_in_delta cov, pose.cov_orientation, 1e-6
            end

            it "sets cov_velocity from the provided cov_velocity" do
                cov = matrix3_rand
                task.exported_links = [Types.rock_gazebo.LinkExport.new(
                    port_name: 'test', source_link: 'l', target_link: 'root',
                    cov_velocity: cov, port_period: Time.at(0))]
                pose = configure_start_and_read_one_sample 'test'
                assert_matrix3_in_delta cov, pose.cov_velocity, 1e-6
            end
        end
    end

    describe "IMU sensor" do
        def read_imu_sample(world_file)
            @task = gzserver world_file, '/gazebo:w:m:i'
            yield(@task) if block_given?
            reader = @task.imu_samples.reader
            @task.configure
            @task.start
            assert_has_one_new_sample(reader)
        ensure
            reader.disconnect if reader
        end

        it "exports the sensor using an ImuTask" do
            task = gzserver 'imu.world', '/gazebo:w:m:i'
            assert_equal "rock_gazebo::ImuTask", task.model.name
        end

        it "exports the raw samples" do
            sample = read_imu_sample 'imu.world'
            assert(sample.time.to_f > 0 && sample.time.to_f < 10)
            assert(sample.acc.norm < 1e-6)
            assert(sample.gyro.norm < 1e-6)
            assert(sample.mag.norm < 1e-6)
        end

        it "stamps raw samples using the realtime instead of the logical time if use_sim_time is false" do
            sample = read_imu_sample 'imu.world' do |task|
                task.use_sim_time = false
            end
            diff_t = (Time.now - sample.time)
            assert(diff_t > 0 && diff_t < 10)
        end
    end

    describe "GPS sensor" do
        def read_sample(world_file, port_name)
            @task = gzserver world_file, '/gazebo:w:m:g'
            yield(@task) if block_given?
            reader = @task.port(port_name).reader
            @task.configure
            @task.start
            assert_has_one_new_sample(reader)
        ensure
            reader.disconnect if reader
        end

        it "exports the sensor using a GPSTask" do
            task = gzserver 'gps.world', '/gazebo:w:m:g'
            assert_equal "rock_gazebo::GPSTask", task.model.name
        end

        it "exports the solution" do
            sample = read_sample 'gps.world', 'gps_solution'
            # Values in the SDF file are in degrees, convert to radians and
            # give a good precision (1e-9 is around 1mm)
            assert_in_epsilon -22.9068, sample.latitude, 1e-9
            assert_in_epsilon -43.1729, sample.longitude, 1e-9
            assert_equal :AUTONOMOUS, sample.positionType;
            assert_in_delta 10, sample.altitude, 0.01;
        end

        it "sets the time to the simulation's logical time" do
            sample = read_sample 'gps.world', 'gps_solution'
            assert(sample.time.to_f > 0 && sample.time.to_f < 10)
        end

        it "exports a 1m deviation in both vertical an horizontal by default" do
            sample = read_sample 'gps.world', 'gps_solution'
            assert_equal 1, sample.deviationLatitude
            assert_equal 1, sample.deviationLongitude
            assert_equal 1, sample.deviationAltitude
        end

        it "uses the GPS noise parameters to set the deviations if present" do
            sample = read_sample 'gps-noise.world', 'gps_solution'
            assert_equal 3, sample.deviationLatitude
            assert_equal 3, sample.deviationLongitude
            assert_equal 2, sample.deviationAltitude
        end

        it "exports the realtime instead of the logical time if use_sim_time is false" do
            sample = read_sample 'gps.world', 'gps_solution' do |task|
                task.use_sim_time = false
            end
            diff_t = (Time.now - sample.time)
            assert(diff_t > 0 && diff_t < 10)
        end

        describe "UTM conversion" do
            # For these tests, we move the model outside of the origin so that
            # we can check the projection parameters
            #
            # The resulting lat/long values are as follows:
            #    latitude   = -22.91582976364718
            #    longitude  = -43.18264805678904
            def read_sample(world_file, port_name)
                super do |task|
                    task.use_proper_utm_conversion = true
                    yield task if block_given?
                end
            end

            it "converts the position to the configured UTM frame" do
                sample = read_sample 'gps-far-from-origin.world', 'utm_samples' do |task|
                    task.gps_frame = 'gps_test'
                    task.utm_frame = 'utm_test'
                    task.nwu_origin = Eigen::Vector3.Zero
                    task.utm_zone = 23
                    task.utm_north = false
                end
                # The position samples are UTM N/E. Rock is in NWU, so we must convert the
                # UTM coordinates to NWU
                assert_equal 'gps_test', sample.sourceFrame
                assert_equal 'utm_test', sample.targetFrame
                assert_in_delta 686382, sample.position.x, 1
                assert_in_delta 7464646, sample.position.y, 1
            end

            it "converts the position to the configured NWU frame" do
                sample = read_sample 'gps-far-from-origin.world', 'position_samples' do |task|
                    task.gps_frame = 'gps_test'
                    task.nwu_frame = 'nwu_test'
                    task.nwu_origin = Eigen::Vector3.new(7465634.13, 312605.41)
                    task.utm_zone = 23
                    task.utm_north = false
                end
                # The position samples are UTM N/E. Rock is in NWU, so we must convert the
                # UTM coordinates to NWU
                assert_equal 'gps_test', sample.sourceFrame
                assert_equal 'nwu_test', sample.targetFrame
                assert_in_delta 1012, sample.position.x, 1
                assert_in_delta 988, sample.position.y, 1
            end

            it "exports the realtime instead of the logical time if use_sim_time is false" do
                sample = read_sample 'gps.world', 'position_samples' do |task|
                    task.use_sim_time = false
                end
                diff_t = (Time.now - sample.time)
                assert(diff_t > 0 && diff_t < 10)
            end

            it "exports the realtime instead of the logical time if use_sim_time is false" do
                sample = read_sample 'gps.world', 'utm_samples' do |task|
                    task.use_sim_time = false
                end
                diff_t = (Time.now - sample.time)
                assert(diff_t > 0 && diff_t < 10)
            end
        end

        describe "Gazebo spherical coordinate conversion" do
            # For these tests, we move the model outside of the origin so that
            # we can check the projection parameters
            #
            # The resulting lat/long values are as follows:
            #    latitude   = -22.91582976364718
            #    longitude  = -43.18264805678904
            def read_sample(world_file, port_name)
                super do |task|
                    task.gps_frame = 'gps_test'
                    task.utm_frame = 'utm_test'
                    task.nwu_frame = 'nwu_test'
                    task.use_proper_utm_conversion = false
                    task.latitude_origin = Types.base.Angle.new(rad: -22.9068 * Math::PI / 180)
                    task.longitude_origin = Types.base.Angle.new(rad: -43.1729 * Math::PI / 180)
                    yield task if block_given?
                end
            end

            it "converts the position to the configured local frame" do
                sample = read_sample 'gps-far-from-origin.world', 'utm_samples'
                # The position samples are UTM N/E. Rock is in NWU, so we must convert the
                # UTM coordinates to NWU
                assert_equal 'gps_test', sample.sourceFrame
                assert_equal 'utm_test', sample.targetFrame
                assert_in_delta -1000, sample.position.x, 1
                assert_in_delta 1000, sample.position.y, 1
            end

            it "converts the position to the local frame" do
                sample = read_sample 'gps-far-from-origin.world', 'position_samples'
                # The position samples are UTM N/E. Rock is in NWU, so we must convert the
                # UTM coordinates to NWU
                assert_equal 'gps_test', sample.sourceFrame
                assert_equal 'nwu_test', sample.targetFrame
                assert_in_delta 1000, sample.position.x, 1
                assert_in_delta 1000, sample.position.y, 1
            end

            it "exports the realtime instead of the logical time if use_sim_time is false" do
                sample = read_sample 'gps.world', 'position_samples' do |task|
                    task.use_sim_time = false
                end
                diff_t = (Time.now - sample.time)
                assert(diff_t > 0 && diff_t < 10)
            end

            it "exports the realtime instead of the logical time if use_sim_time is false" do
                sample = read_sample 'gps.world', 'utm_samples' do |task|
                    task.use_sim_time = false
                end
                diff_t = (Time.now - sample.time)
                assert(diff_t > 0 && diff_t < 10)
            end
        end

    end
end


