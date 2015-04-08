module RockGazebo
    # Creation of an oroGen deployment model representing what the
    # rock-gazebo plugin would do from a SDF world
    #
    # @param [String] name the name that should be used as deployment name
    # @param [SDF::World] world the SDF world that we have to represent
    # @param [OroGen::Loaders::Base] loader the oroGen loader that we should use
    #   to create the tasks
    # @return [OroGen::Spec::Deployment]
    def self.orogen_model_from_sdf_world(name, world, options = Hash.new)
        options = validate_options options,
            loader: Orocos.default_loader,
            period: 0.01

        project = OroGen::Spec::Project.new(options[:loader])
        project.using_task_library 'rock_gazebo'
        deployment = project.deployment name

        period = options.fetch(:period)
        deployment.task("gazebo:#{world.name}", "rock_gazebo::WorldTask").
            periodic(period)
        world.each_model do |model|
            deployment.task("gazebo:#{world.name}:#{model.name}", "rock_gazebo::ModelTask").
                periodic(period)
        end

        deployment
    end
end

