module RockGazebo
    # Library-side implementation of rock-gazebo-viz
    def self.viz(scene, env: nil, start: true, vizkit3d: Vizkit.vizkit3d_widget)
        _, scene = Rock::Gazebo.resolve_worldfiles_and_models_arguments([scene])
        scene = scene.first
        models = Viz.setup_scene(scene, vizkit3d: vizkit3d)
        if env
            if env.respond_to?(:to_str) # this is a plugin name
                env = Vizkit.default_loader.send(env)
            end
            vizkit3d.setEnvironmentPlugin(env)
        end

        if start
            models.each_value do |_, task_proxy|
                task_proxy.on_reachable do
                    begin
                        if task_proxy.rtt_state == :PRE_OPERATIONAL
                            task_proxy.configure
                        end

                        if task_proxy.rtt_state == :STOPPED
                            task_proxy.start
                        end

                        state = task_proxy.rtt_state
                        if state != :RUNNING
                            STDERR.puts "could not start #{task_name} (currently in state #{state})"
                        end
                    rescue Exception => e
                        STDERR.puts "failed to start #{task_name}: #{e}"
                    end
                end
            end
        end
        models
    end
    
    module Viz
        # Sets up the visualization of a complete gazebo scene to a vizkit3d
        # widget
        #
        # @param [SDF::Element] scene the scene
        # @return [{SDF::Model=>(RobotVisualization,Orocos::Async::TaskContext)]] a
        #   mapping from a model name to the vizkit3d plugin and task proxy that
        #   represent it
        def self.setup_scene(scene_path, vizkit3d: Vizkit.vizkit3d_widget)
            conf = Transformer::Configuration.new
            conf.load_sdf(scene_path)
            vizkit3d.apply_transformer_configuration(conf)

            models = Hash.new
            sdf = SDF::Root.load(scene_path)
            puts sdf.xml
            sdf.each_model(recursive: true) do |model|
                models[model] = setup_model(conf, model, vizkit3d: vizkit3d, dir: File.dirname(scene_path))
            end
            models
        end

        # Sets up the visualization of a single model
        #
        # @param [SDF::Model] model the model
        # @return [(RobotVisualization,Orocos::Async::TaskContext)] the vizkit3d
        #   plugin and the async task for this model
        def self.setup_model(transformer_conf, model, vizkit3d: Vizkit.vizkit3d_widget, dir: nil)
            model_viz = Vizkit.default_loader.RobotVisualization

            model_only = model.make_root
            model_viz.loadFromString(model_only.xml.to_s, 'sdf', dir)
            model_viz.frame = model.name
            puts "putting model in frame #{model.name}"

            task_name = "gazebo:#{model.full_name.gsub('::', ':')}"
            task_proxy = Orocos::Async.proxy task_name
            trsf = transformer_conf.dynamic_transform "#{task_name}.pose_samples",
                model.name => (model.parent.full_name || 'osg_world')
            vizkit3d.listen_to_transformation_producer(trsf)
            joints_out = task_proxy.port "joints_samples"

            joints_out.on_data do |sample|
                model_viz.updateData(sample)
            end

            return model_viz, task_proxy
        end
    end
end

