
#ifndef _ROCK_BRIDGE_HPP_
#define _ROCK_BRIDGE_HPP_

// Gazebo headers
#include <boost/bind.hpp>
#include <gazebo/gazebo.hh>
#include <gazebo/physics/physics.hh>
#include <gazebo/common/common.hh>
#include <gazebo/common/Plugin.hh>
// Rock Headers
// #include <rtt/RTT.hpp>
#include <rtt/types/TypekitRepository.hpp>
#include <rtt/transports/corba/TaskContextServer.hpp>
#include <rtt/TaskContext.hpp>
#include <rtt/Activity.hpp>
// Rock DCMotor headers
#include <orocos/gazebo/DCMotorTask.hpp>
// #include <stdio.h>

namespace gazebo
{
	class RockBridge: public SystemPlugin
	{
		public:
			// Pure virtual function implementation
			void Load(int _argc = 0, char **_argv = NULL);

		private:
			RTT::TaskContext* dc_motor_task;
			RTT::Activity* activity_dcmotor;

			std::vector<event::ConnectionPtr> endUpdate;
			
			physics::JointPtr robot_left_joint;
			physics::JointPtr robot_right_joint;
			RTT::InputPort<double> *dc_motor_port;

			void worldCreated(std::string const& worldName);
			// void updateBegin(gazebo::common::UpdateInfo const& info);
			void updateEnd();
			void initRockDCMotor();
			void applyForce(double);
	};
	
    // Register this plugin with the simulator
	GZ_REGISTER_SYSTEM_PLUGIN(RockBridge)
}


#endif
