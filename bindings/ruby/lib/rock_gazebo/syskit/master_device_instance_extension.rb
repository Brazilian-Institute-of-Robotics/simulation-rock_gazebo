module RockGazebo
    module Syskit
        module MasterDeviceInstanceExtension
            def transformer_uses_sdf_links_of(model_device)
                requirements.transformer_uses_sdf_links_of(model_device)
            end
        end

        ::Syskit::Robot::MasterDeviceInstance.include MasterDeviceInstanceExtension
    end
end

