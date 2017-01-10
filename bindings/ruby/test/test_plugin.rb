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
end


