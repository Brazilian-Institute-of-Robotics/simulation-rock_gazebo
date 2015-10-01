require 'orocos/ruby_tasks/process'

module RockGazebo
    module Syskit
        class WorldManager
            # Exception raised if one attempts to do name mappings in a gazebo
            # world manager
            class NameMappingsForbidden < ArgumentError; end

            class Status
                def initialize(options = Hash.new)
                    options = Kernel.validate_options options,
                        :exit_code => nil,
                        :signal => nil
                    @exit_code = options[:exit_code]
                    @signal = options[:signal]
                end
                def stopped?; false end
                def exited?; !@exit_code.nil? end
                def exitstatus; @exit_code end
                def signaled?; !@signal.nil? end
                def termsig; @signal end
                def stopsig; end
                def success?; exitstatus == 0 end
            end

            attr_reader :worlds
            attr_reader :loader
            attr_reader :terminated_worlds

            def initialize(loader = Orocos.default_loader)
                @loader = loader
                @worlds = Hash.new
                @terminated_worlds = Hash.new
            end

            def disconnect
            end

            def register_world(path, world_name = nil)
                worlds = SDF::Root.load(path).each_world.to_a
                if world_name
                    world = worlds.find { |w| w.name == world_name }
                    if !world
                        raise ArgumentError, "cannot find a world named #{world_name} in #{path}"
                    end
                elsif worlds.size == 1
                    world = worlds.first
                elsif worlds.empty?
                    raise ArgumentError, "no worlds declared in #{path}"
                else
                    raise ArgumentError, "more than one world declared in #{path}, select one explicitely by providing the world_name argument"
                end

                model = RockGazebo.orogen_model_from_sdf_world("gazebo_world_#{world.name}", world, loader: loader)
                return register_deployment_model(model), world
            end

            def register_deployment_model(model)
                loader.register_deployment_model(model)
            end

            def start(name, deployment_name = name, name_mappings = Hash.new, prefix: nil, **options)
                model = if deployment_name.respond_to?(:to_str)
                            loader.deployment_model_from_name(deployment_name)
                        else deployment_name
                        end
                if worlds[name]
                    raise ArgumentError, "#{name} is already started in #{self}"
                end

                prefix_mappings = Orocos::ProcessBase.resolve_prefix(model, prefix)
                name_mappings = prefix_mappings.merge(name_mappings)
                name_mappings.each do |from, to|
                    if from != to
                        raise NameMappingsForbidden, "cannot do name mapping in gazebo support"
                    end
                end

                gazebo_world = World.new(self, name, model)
                gazebo_world.spawn
                worlds[name] = gazebo_world
            end

            # Requests that the process server moves the log directory at +log_dir+
            # to +results_dir+
            def save_log_dir(log_dir, results_dir)
            end

            # Creates a new log dir, and save the given time tag in it (used later
            # on by save_log_dir)
            def create_log_dir(log_dir, time_tag, metadata = Hash.new)
            end

            # Waits for processes to terminate. +timeout+ is the number of
            # milliseconds we should wait. If set to nil, the call will block until
            # a process terminates
            #
            # Returns a hash that maps deployment names to the Status
            # object that represents their exit status.
            def wait_termination(timeout = nil)
                result, @terminated_worlds =
                   terminated_worlds, Hash.new
                result
            end

            # Requests to stop the given deployment
            #
            # The call does not block until the process has quit. You will have to
            # call #wait_termination to wait for the process end.
            def stop(world_name)
                if w = worlds[world_name]
                    w.kill
                end
            end

            def dead_deployment(world_name, status = Status.new(:exit_code => 0))
                if w = worlds.delete(world_name)
                    terminated_worlds[w] = status
                end
            end
        end
    end
end

