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
                    Orocos.initialize
                    new_ruby_task_context 'gazebo:underwater'
                    assert world.wait_running
                end
            end
        end
    end
end

