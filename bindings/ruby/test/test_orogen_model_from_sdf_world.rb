require 'rock_gazebo/test'
require 'sdf'
require 'rock_gazebo/orogen_model_from_sdf_world'

module RockGazebo
    describe 'orogen_model_from_sdf_world' do
        before do
            require 'orocos'
            Orocos.load
        end

        def data_dir
            File.expand_path('data', File.dirname(__FILE__))
        end

        it "creates a deployment that represents the rock_gazebo plugin behaviour" do
            world = SDF::Root.load(File.join(data_dir, 'test.world')).each_world.first
            model = RockGazebo.orogen_model_from_sdf_world('gazebo_world_test', world)
            assert(world_task = model.find_task_by_name('gazebo:underwater'), "cannot find task gazebo:underwater in #{model}, tasks are: #{model.each_task.map(&:name).join(", ")}")
            assert_equal 'rock_gazebo::WorldTask', world_task.task_model.name
            assert(model_task = model.find_task_by_name('gazebo:underwater:flat_fish'))
            assert_equal 'rock_gazebo::ModelTask', model_task.task_model.name
            assert(model_task = model.find_task_by_name('gazebo:underwater:oil_rig'))
            assert_equal 'rock_gazebo::ModelTask', model_task.task_model.name
        end

        it "allows to override the task's periodicity" do
            world = SDF::Root.load(File.join(data_dir, 'test.world')).each_world.first
            expected_period = 0.1
            model = RockGazebo.orogen_model_from_sdf_world('gazebo_world_test', world, period: expected_period)

            %w{gazebo:underwater gazebo:underwater:flat_fish gazebo:underwater:oil_rig}.each do |task_name|
                task = model.find_task_by_name(task_name)
                assert_in_delta expected_period, task.period, 0.00001
            end
        end
    end
end
