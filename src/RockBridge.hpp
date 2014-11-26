#ifndef _ROCK_BRIDGE_HPP_
#define _ROCK_BRIDGE_HPP_

// Gazebo headers
#include <boost/bind.hpp>
#include <gazebo/gazebo.hh>
#include <gazebo/physics/physics.hh>
#include <gazebo/common/common.hh>
#include <gazebo/common/Plugin.hh>
// Rock Headers
#include <rtt/types/TypekitRepository.hpp>
#include <rtt/transports/corba/TaskContextServer.hpp>
#include <rtt/TaskContext.hpp>
#include <rtt/Activity.hpp>

namespace gazebo
{
	class ModelTask; 
}

namespace gazebo
{
	class RockBridge: public SystemPlugin
	{
		public:
			// Pure virtual function implementation
			void Load(int _argc = 0, char **_argv = NULL);
			~RockBridge(); 
			
		private:
			void worldCreated(std::string const& worldName);
			void updateBegin(gazebo::common::UpdateInfo const& info);
			void updateEnd();

			std::vector<event::ConnectionPtr> eventHandler;

			typedef std::vector<gazebo::ModelTask*> ModelTasks;
			ModelTasks tasks;
			
			typedef std::vector<RTT::Activity*> Activities;
			Activities activities;
	};
	
 	// Register this plugin with the simulator
	GZ_REGISTER_SYSTEM_PLUGIN(RockBridge)
}


#endif
