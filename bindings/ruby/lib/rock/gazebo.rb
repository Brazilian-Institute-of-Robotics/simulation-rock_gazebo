require 'rock/bundles'
module Rock
    module Gazebo
        def self.model_path
            Bundles.find_dirs('data','gazebo','models', :all => true, :order => :specific_first) +
                (ENV['GAZEBO_MODEL_PATH']||"").split(':') +
                [File.join(Dir.home, '.gazebo', 'models')]
        end

        def self.initialize
            Bundles.load

            require 'sdf'
            model_path = self.model_path
            SDF::XML.model_path = model_path
            ENV['GAZEBO_MODEL_PATH'] = model_path.join(":")
        end
    end
end

