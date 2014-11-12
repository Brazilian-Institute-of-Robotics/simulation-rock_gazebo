
#ifndef _ROCK_BRIDGE_HPP_
#define _ROCK_BRIDGE_HPP_

// Gazebo headers
#include <boost/bind.hpp>
#include <gazebo/gazebo.hh>
#include <gazebo/physics/physics.hh>
#include <gazebo/common/common.hh>
#include <gazebo/common/Plugin.hh>
// Rock Headers
#include <rtt/RTT.hpp>
#include <rtt/transports/corba/TaskContextServer.hpp>
// Rock DCMotor headers
#include <orocos/gazebo/DCMotorTask.hpp>
#include <orocos/gazebo/typekit/Plugin.hpp>
// #include <stdio.h>

namespace gazebo
{
	class RockBridge: public SystemPlugin
	{
		public:
			// Pure virtual function implementation
			void Load(int _argc = 0, char **_argv = NULL);

			void Load(physics::WorldPtr, sdf::ElementPtr);

		private:
			RTT::TaskContext* dcmotor;
			RTT::Activity* activity_dcmotor;

			sdf::ElementPtr sdf;
			std::string model_name;
			std::string topic_name;
			std::vector<event::ConnectionPtr> endUpdate;
			physics::ModelPtr model;
			physics::WorldPtr parent;
			physics::JointPtr robot_left_joint;
			physics::JointPtr robot_right_joint;

			void readWorld();
			void updateSimulation();
			void applyForce(double);
			void initRockDCMotor();
	};
    // Register this plugin with the simulator
	GZ_REGISTER_SYSTEM_PLUGIN(RockBridge)
}


#endif
