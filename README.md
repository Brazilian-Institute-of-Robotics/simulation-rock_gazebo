= Syskit usage

== Directory Layout

In a bundle, scenes go in scenes/$scenename/$scenename.world. Bundle-specific
models go in models/sdf/$modelname/{model.config,model.sdf}.

== Using SDF at the model level

As usual with Syskit, there are two different levels you need to think about

At the __model__ level, one can use SDF to declare the type of robot that is
being used. This is done in a profile by calling <tt>use\_sdf\_model</tt>. The
method accepts any kind of model (i.e. model:// or a path that can be resolved
under models/sdf and scenes/)

~~~ ruby
use_sdf_model "model://flat_fish"
~~~

This statement declares the existence of the ModelTask by declaring a device of
type Rock::Devices::Gazebo::Model under the model's name on the profile's robot.
In addition, it sets up the transformer to declare all possible world-to-link
transformations that the model can generate, as well as the world-to-model
transformation.

== Using Gazebo

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
Robot.requires do
  require 'rock_gazebo/syskit'
  Syskit.conf.use_gazebo_world('flat_fish')
end
~~~

This declares all the tasks that the rock-gazebo plugin creates to syskit's set
of deployments, thus allowing you to use them in your systems. Note that in most
cases you won't have to use them explicitely as the profile-level declaration
declares all the devices automatically.

