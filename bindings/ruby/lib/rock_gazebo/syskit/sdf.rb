module RockGazebo
    module Syskit
        # SDF-related configuration
        #
        # It is accessible as Conf.sdf
        class SDF
            # Guard value that allows the Gazebo/Syskit integration to check
            # that a profile's use_sdf_model has indeed been called after the
            # configuration's use_sdf_world
            attr_predicate :has_profile_loaded?, true

            # The loaded world
            attr_accessor :world

            # The world name that should be or has been loaded
            attr_accessor :world_path

            # The full path to the worl file
            attr_accessor :world_file_path

            def initialize
                @world = ::SDF::World.empty
            end

            # Force-select the UTM zone that should be used to compute
            # {#global_origin}
            def select_utm_zone(zone, north)
                @utm_zone = zone
                @utm_north = north
            end

            # The currently selected UTM zone
            #
            # It is guessing the zone from the world's spherical coordinates if
            # it has not been set
            def utm_zone
                if !@utm_zone
                    @utm_zone, @utm_north = spherical_coordinates.default_utm_zone
                end
                @utm_zone
            end

            # Whether we're on the north or south part of the UTM zone
            #
            # It is guessing the zone from the world's spherical coordinates if
            # it has not been set
            def utm_north?
                if !@utm_zone
                    @utm_zone, @utm_north = spherical_coordinates.default_utm_zone
                end
                @utm_north
            end

            # Return the global origin in UTM coordinates
            #
            # @return [Eigen::Vector3] the coordinates in ENU convention and at
            #   the origin of the UTM grid
            def utm_global_origin
                utm = spherical_coordinates.utm(zone: utm_zone, north: utm_north?)
                Eigen::Vector3.new(utm.easting, utm.northing,
                                   world.spherical_coordinates.elevation)
            end

            # The world's GPS origin in NWU (Rock coordinates)
            #
            # @return [Eigen::Vector3] the coordinates in Rock's NWU convention
            def global_origin
                utm = utm_global_origin
                Eigen::Vector3.new(utm.y, 1_000_000 - utm.x, utm.z)
            end

            def method_missing(*args, &block)
                world.public_send(*args, &block)
            end
        end
    end
end

