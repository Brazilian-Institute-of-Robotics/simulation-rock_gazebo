require 'helpers'

describe "The Rock/Gazebo plugin" do
    include Helpers
    include Orocos::Test::Component

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

        it "converts the position to the configured UTM frame" do
            sample = read_sample 'gps.world', 'position_samples' do |task|
                task.origin = Eigen::Vector3.Zero
                task.utm_zone = 23
                task.utm_north = false
            end
            # The raw values are UTM N/E. Rock is in NWU, so we must convert the
            # UTM coordinates to NWU
            assert_in_delta 687394.89, sample.position.x, 10
            assert_in_delta 7465628.95, sample.position.y, 10
        end

        it "exports the realtime instead of the logical time if use_sim_time is false" do
            sample = read_sample 'gps.world', 'gps_solution' do |task|
                task.use_sim_time = false
            end
            diff_t = (Time.now - sample.time)
            assert(diff_t > 0 && diff_t < 10)
        end
    end
end


