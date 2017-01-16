require 'rock_gazebo/syskit/test'

module RockGazebo
    module Syskit
        describe SDF do
            describe "#global_origin" do
                def dataset
                    [[48.858093, 2.294694, 31, true, 448_265.91, 5_411_920.65],
                     [-22.970722, -43.182365, 23, false, 686_336.05, 7_458_567.56]]
                end

                it "sets the UTM zone to default and returns the UTM coordinates of the spherical_coordinates element" do
                    dataset.each do |lat, long, zone, zone_north, easting, northing|
                        sdf = SDF.new
                        sdf.world = ::SDF::World.from_string(
                            "<world>
                                <spherical_coordinates>
                                    <latitude_deg>#{lat}</latitude_deg>
                                    <longitude_deg>#{long}</longitude_deg>
                                    <elevation>42</elevation>
                                </spherical_coordinates>
                             </world>")

                        utm = sdf.utm_global_origin
                        assert_equal zone, sdf.utm_zone
                        refute(zone_north ^ sdf.utm_north?)
                        assert_in_delta easting, utm.x, 0.01
                        assert_in_delta northing, utm.y, 0.01
                        assert_in_delta 42, utm.z, 0.01

                        nwu = sdf.global_origin
                        assert_in_delta northing, nwu.x, 0.01
                        assert_in_delta (1_000_000 - easting), nwu.y, 0.01
                        assert_in_delta 42, nwu.z, 0.01
                    end
                end

                it "allows to force the UTM zone used" do
                    sdf = SDF.new
                    flexmock(sdf.world).
                        should_receive(spherical_coordinates: coordinates = flexmock)
                    coordinates.should_receive(:utm).
                        with(zone: 43, north: false).
                        once.and_return(flexmock(easting: 100, northing: 1000))
                    coordinates.should_receive(elevation: 42)

                    sdf.select_utm_zone(43, false)
                    utm = sdf.utm_global_origin
                    assert_equal 43, sdf.utm_zone
                    refute sdf.utm_north?
                    assert_in_delta 100, utm.x, 0.01
                    assert_in_delta 1000, utm.y, 0.01
                    assert_in_delta 42, utm.z, 0.01
                end
            end
        end
    end
end

