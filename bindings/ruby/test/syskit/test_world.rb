require 'rock_gazebo/test'
require 'rock_gazebo/syskit'
require 'orocos/test/ruby_tasks'

module RockGazebo
    module Syskit
        describe World do
            def data_dir
                File.expand_path(File.join('..', 'data'), File.dirname(__FILE__))
            end

            attr_reader :world

            before do
                Orocos.load
                manager = WorldManager.new
                manager.register_world(File.join(data_dir, 'test.world'))
                @world = manager.start('gazebo_world_underwater')
            end

            describe "spawn" do
                it "sets the world as alive" do
                    assert world.alive?
                end
            end

            describe "wait_running" do
                include Orocos::Test::RubyTasks

                before do
                    world.spawn
                end

                it "returns false if the world task is not available" do
                    assert !world.wait_running
                end

                it "returns true as soon as the world task becomes available" do
                    if !Orocos.initialized?
                        Orocos.initialize
                    end
                    new_ruby_task_context 'gazebo:underwater'
                    assert world.wait_running
                end
            end

            describe "task" do
                include Orocos::Test::RubyTasks

                before do
                    if !Orocos.initialized?
                        Orocos.initialize
                    end
                    new_ruby_task_context 'gazebo:underwater'
                end

                it "resolves the task" do
                    task = world.task 'gazebo:underwater'
                    assert_equal '/gazebo:underwater', task.name
                end
                it "caches the resolved task" do
                    task = world.task 'gazebo:underwater'
                    assert_same task, world.task('gazebo:underwater')
                end
            end

            describe "stop" do
                include Orocos::Test::RubyTasks

                attr_reader :task

                before do
                    if !Orocos.initialized?
                        Orocos.initialize
                    end
                    new_ruby_task_context 'gazebo:underwater'
                    @task = world.task 'gazebo:underwater'
                end

                it "stops and cleans up running tasks" do
                    task.configure
                    task.start
                    world.kill
                    assert_equal :PRE_OPERATIONAL, task.rtt_state
                end
                it "cleans up stopped tasks" do
                    task.configure
                    world.kill
                    assert_equal :PRE_OPERATIONAL, task.rtt_state
                end
                it "leaves pre_operational tasks alone" do
                    world.kill
                    assert_equal :PRE_OPERATIONAL, task.rtt_state
                end
            end
        end
    end
end

