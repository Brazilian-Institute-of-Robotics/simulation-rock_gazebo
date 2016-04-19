module RockGazebo
    module Syskit
        class World < Orocos::ProcessBase
            # The {WorldManager} object which created this World object
            #
            # If non-nil, the object's #dead_deployment will be called when self is
            # stopped
            #
            # @return [#dead_deployment,nil]
            attr_reader :world_manager

            # The set of deployed tasks
            #
            # @return [{String=>TaskContext}] mapping from the deployed task name as
            #   defined in {model} to the actual {Orocos::TaskContext}
            attr_reader :deployed_tasks

            # The host on which this process' tasks run
            #
            # @return [String]
            attr_reader :host_id

            # Whether the tasks in this process are running on the same machine than
            # the ruby process
            #
            # This is always true as ruby tasks are instanciated inside the ruby
            # process
            #
            # @return [Boolean]
            def on_localhost?; host_id == 'localhost' end

            # The PID of the process in which the tasks run
            #
            # This is always Process.pid as ruby tasks are instanciated inside the ruby
            # process
            #
            # @return [Integer]
            attr_reader :pid

            # The name service object which should be used to resolve the tasks
            attr_reader :name_service

            # Creates a new object managing the tasks that represent a single gazebo world
            #
            # @param [nil,#dead_deployment] world_manager the world manager
            #   which created this process. If non-nil, its #dead_deployment method
            #   will be called when {stop} is called
            # @param [String] name the process name
            # @param [OroGen::Spec::Deployment] model the deployment model
            def initialize(world_manager, name, model, options = Hash.new)
                @world_manager = world_manager
                @deployed_tasks = Hash.new
                options = Kernel.validate_options options,
                    name_service: Orocos.name_service
                @name_service = options[:name_service]
                @host_id = options[:host_id]
                super(name, model)
            end

            # "Starts" this world
            #
            # This does nothing. Connectivity to expected tasks is done in
            # {wait_running}
            #
            # @return [void]
            def spawn(options = Hash.new)
                deployed_tasks.clear
                @alive = true
            end

            # Waits for the tasks to be ready
            #
            # This is a no-op as the tasks get resolved in #spawn
            def wait_running(blocking = false)
                # Just access the world task as a cheap check
                world_task = model.task_activities.find { |t| t.task_model.name == 'rock_gazebo::WorldTask' }
                world_task = task(world_task.name)
                true
            rescue Orocos::NotFound
                @last_error_message ||= Time.now
                if(Time.now-@last_error_message).to_f > 5.0
                    ::Robot.warn "#{name}: Waiting for Gazebo Sever."
                    ::Robot.warn "You have to start the simulation via 'rock-gzserver WORLD_FILE'."
                    @last_error_message = Time.now
                end
                false
            end

            def task(task_name)
                deployed_tasks[task_name] ||= name_service.get(task_name)
            end

            def kill(wait = true, status = WorldManager::Status.new(:exit_code => 0))
                deployed_tasks.each_value do |task|
                    if task.rtt_state == :RUNNING
                        task.stop
                    end
                    if task.rtt_state == :STOPPED
                        task.cleanup
                    end
                end
                dead!(status)
            end

            def dead!(status = WorldManager::Status.new(:exit_code => 0))
                @alive = false
                if world_manager
                    world_manager.dead_deployment(name, status)
                end
            end

            def join
                raise NotImplementedError, "World#join is not implemented"
            end

            # True if the process is running. This is an alias for running?
            def alive?; @alive end
            # True if the process is running. This is an alias for alive?
            def running?; @alive end
        end
    end
end

