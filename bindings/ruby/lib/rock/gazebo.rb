require 'rock/bundles'
require 'sdf'

module Rock
    module Gazebo
        def self.default_model_path
            Bundles.find_dirs('models','sdf', :all => true, :order => :specific_first) +
                (ENV['GAZEBO_MODEL_PATH']||"").split(':') +
                [File.join(Dir.home, '.gazebo', 'models')] +
                [ENV['AUTOPROJ_CURRENT_ROOT'] + '/robots']
        end

        def self.model_path
            @model_path || default_model_path
        end

        def self.model_path=(model_path)
            @model_path = model_path
            SDF::XML.model_path = model_path
            ENV['GAZEBO_MODEL_PATH'] = model_path.join(":")
        end

        def self.resolve_worldfiles_and_models_arguments(argv)
            model_path = self.model_path
            filtered_argv = Array.new
            argv = argv.dup
            while !argv.empty?
                arg = argv.shift

                if arg == '--model-dir'
                    dir = argv.shift
                    if !dir
                        STDERR.puts "no argument given to --model-dir"
                        exit 1
                    elsif !File.dirname(dir)
                        STDERR.puts "#{dir} is not a directory"
                        exit 1
                    end

                    model_path.unshift dir
                elsif File.file?(arg)
                    filtered_argv << arg
                elsif arg =~ /^model:\/\/(\w+)(.*)/
                    model_name, filename = $1, $2
                    require 'sdf'
                    model_dir = File.dirname(SDF::XML.model_path_from_name(model_name, model_path: model_path))
                    filtered_argv << File.join(model_dir, filename)
                elsif File.extname(arg) == '.world'
                    if resolved_path = Bundles.find_file('scenes', 'worlds', arg, all: false, order: :specific_first)
                        filtered_argv << resolved_path
                    else
                        filtered_argv << arg
                    end
                else
                    filtered_argv << arg
                end
            end
            return model_path, filtered_argv
        end

        def self.initialize
            Bundles.load

            self.model_path = self.default_model_path
        end
    end
end

