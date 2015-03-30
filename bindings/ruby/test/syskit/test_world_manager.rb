require 'rock_gazebo/test'
require 'rock_gazebo/syskit'

module RockGazebo
    module Syskit
        describe WorldManager do
            def data_dir
                File.expand_path(File.join('..', 'data'), File.dirname(__FILE__))
            end

            attr_reader :manager

            before do
                @manager = WorldManager.new
                Orocos.load
            end

            describe "register_world" do
                it "registers a world from a SDF file" do
                    manager.register_world(File.join(data_dir, 'test.world'))
                    # Note: the world name in the worldfile and the name of the
                    # world file differ, and that is on purpose. We really want
                    # to use the world name here
                    manager.loader.deployment_model_from_name('gazebo_world_underwater')
                end
                it "bails out if multiple worlds are included and the world_name argument not" do
                    assert_raises(ArgumentError) do
                        manager.register_world(File.join(data_dir, 'multi_world.sdf'))
                    end
                end
                it "uses world_name to disambiguate if there are multiple worlds" do
                    manager.register_world(File.join(data_dir, 'multi_world.sdf'), 'test1')
                    manager.loader.deployment_model_from_name("gazebo_world_test1")
                end
                it "bails out if no worlds are declared" do
                    assert_raises(ArgumentError) do
                        manager.register_world(File.join(data_dir, 'no_world.sdf'))
                    end
                end
                it "bails out if a world matching world_name cannot be found" do
                    assert_raises(ArgumentError) do
                        manager.register_world(File.join(data_dir, 'test.world'), 'does_not_exist')
                    end
                end
            end

            describe "start" do
                before do
                    manager.register_world(File.join(data_dir, 'test.world'))
                end

                it "creates a World object to represent the tasks created by the rock_gazebo plugin" do
                    world = manager.start("gazebo_world_underwater", "gazebo_world_underwater")
                    assert_kind_of World, world
                    assert_equal 'gazebo_world_underwater', world.name
                end

                it "bails out if there are name mappings" do
                    assert_raises(WorldManager::NameMappingsForbidden) do
                        manager.start("gazebo_world_underwater", "gazebo_world_underwater", 'gazebo:underwater' => 'test')
                    end
                end
                
                it "refuses to start the same world twice" do
                    manager.start("gazebo_world_underwater", "gazebo_world_underwater")
                    assert_raises(ArgumentError) do
                        manager.start("gazebo_world_underwater", "gazebo_world_underwater")
                    end
                end
            end

            it "asynchronously reports on terminated worlds" do
                manager.register_world(File.join(data_dir, 'test.world'))
                w = manager.start("gazebo_world_underwater", "gazebo_world_underwater")
                manager.dead_deployment("gazebo_world_underwater", (status = flexmock))
                assert_equal Hash[w => status], manager.wait_termination
                assert_equal Hash[], manager.wait_termination
            end

            describe "stop" do
                before do
                    manager.register_world(File.join(data_dir, 'test.world'))
                end

                it "calls kill on a registered world" do
                    w = manager.start("gazebo_world_underwater", "gazebo_world_underwater")
                    flexmock(w).should_receive(:kill).once
                    manager.stop("gazebo_world_underwater")
                end
            end
        end
    end
end

