module RockGazebo
    module Syskit
        module InstanceRequirementsExtension
            # Call to use the SDF links and models as dynamic transformation
            # producers
            def transformer_uses_sdf_links_of(model_device)
                transformer.dynamic_transform model_device,
                    model_device.name => 'world'
                model_device.robot.each_master_device do |master_dev|
                    if master_dev.model.fullfills?(Rock::Devices::Gazebo::Link)
                        if transform = master_dev.frame_transform
                            transformer.dynamic_transform master_dev,
                                transform.from => transform.to
                        end
                    end
                end
                self
            end

            ::Syskit::InstanceRequirements.include InstanceRequirementsExtension
        end
    end
end

