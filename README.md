= Syskit usage

== Directory Layout

In a bundle, scenes go in scenes/$scenename/$scenename.world. Bundle-specific
models go in models/sdf/$modelname/{model.config,model.sdf}.

== Using Gazebo

At the profile level, one can use SDF to declare the type of robot that is
being used. This is done in a profile by calling <tt>use\_gazebo\_model</tt>. The
method accepts any kind of model (i.e. model:// or a path that can be resolved
under models/sdf and scenes/)

```
profile 'Base' do
    # Sets up the transformer based on the model's kinematic structure
    #
    # Also, sets up the robot devices that will allow Syskit to connect
    # to the Gazebo instance
    use_gazebo_model 'model://myrobot'
    # Also imports frame from the environment description defined in the
    # robot configuration
    use_sdf_world
end
```

Gazebo is *not* managed by Syskit. You have to start it manually. The design
rationale is that one does not reboot the world every time one has to reboot its
software system (which would essentially be what having gazebo managed by the
robot look like)

However, there is a limitation. While gazebo itself is not started by syskit,
the tasks that the rock-gazebo plugin spawns are. So, if you start a
visualization with e.g. rock-gazebo-viz, you *must* add the --no-start option.

Global setup is done by adding the following statement in your robot
configuation file's requires statement. It must be done before requiring any
profile that uses use\_sdf\_model.

~~~
Robot.init do
  require 'rock_gazebo/syskit'
end

Robot.requires do
  Syskit.conf.use_gazebo_world('flat_fish')
end
~~~

This declares all the tasks that the rock-gazebo plugin creates to syskit's set
of deployments, thus allowing you to use them in your systems. Note that in most
cases you won't have to use them explicitely as the profile-level declaration
declares all the devices automatically.

The selected world passed to `use_gazebo_world` is a default. It can be
overriden on the command line with the `--set=sdf.world_file=world_name` option.

== Devices bound to the gazebo instance

`use_gazebo_model` defines a number of devices that bind to the gazebo instance,
namely:
 - one device per model, just called `modelname_dev` (e.g. `flat_fish_dev` for a
   model called `flat_fish`)
 - one device per link, which exports the pose of the link in the world. It is
   called `linkname_link_dev` for a link named `linkname`
 - one device per supported sensor, which exports the sensor information as a
   specialized orogen task (see the tasks in the `rock_gazebo` orogen package).
   It is called `sensorname_sensor_dev`

None of the transformations (links and models) are declared on the transformer
as transformation producers (it would lead the transformer to believe that the
knowledge of all the transformations is available to all tasks). Instead, if one
needs this information - for instance to feed to a simulation component that
needs knowledge about the world - one needs to call `transformer_uses_sdf_links_of`
on the definition.

For instance

```
define('simulated_underwater_camera', Compositions::CameraSimulation).
    transformer_uses_sdf_links_of(flat_fish_dev)
```

where the argument is the device that represents a model in the SDF world.

Finally, if some specific link-related transformations are needed, they can be
explicitely exported with `sdf_export_link`

```
robot do
  # Export the transformation from the `flat_fish::dvl` link of the `flat_fish`
  # model to the `flat_fish::imu` link of the `flat_fish` model. The create
  # device is called `dvl_velocity`
  sdf_export_link(flat_fish_dev, as: 'dvl_velocity', from_frame: 'flat_fish::dvl', to_frame: 'flat_fish::dvl')
end
```

`sdf_export_link` returns a device instance. The instance's period can be
controlled in which case the transformation will be exported only at the
specified period, e.g.

```
robot do
  # Export the transformation from the `flat_fish::dvl` link of the `flat_fish`
  # model to the `flat_fish::imu` link of the `flat_fish` model. The create
  # device is called `dvl_velocity`
  sdf_export_link(flat_fish_dev, as: 'dvl_velocity', from_frame: 'flat_fish::dvl', to_frame: 'flat_fish::dvl').
    period(0.1)
end
```

== Using SDF without Gazebo

A number of SDF-related functionality (static environment description,
spherical coordinates, transformer setup) are desirable in a Syskit system even
if not using Gazebo.

This is done at the config level with 

```
Robot.init do
  require 'rock_gazebo/syskit'
end
Robot.requires do
  Syskit.conf.use_sdf_world 'flat_fish'
end
```

and at the profile level 

```
profile 'Base' do
    # Sets up the transformer based on the model's kinematic structure
    use_sdf_model 'model://myrobot'
    # Also imports frame from the environment description defined in the
    # robot configuration
    use_sdf_world
end
```
