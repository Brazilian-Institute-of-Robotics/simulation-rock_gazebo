//======================================================================================
// Brazilian Institute of Robotics 
// Authors: Thomio Watanabe
// Date: December 2014
//====================================================================================== 
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
//#include <rtt/extras/SlaveActivity.hpp>

#define GROUND 0
#define UNDERWATER 1

namespace gazebo{
	class ModelTask; 
}

namespace gazebo
{
	class RockBridge: public SystemPlugin
	{
		public:
			// Pure virtual function implementation
			virtual void Load(int _argc = 0, char **_argv = NULL);
//			virtual void Load(physics::WorldPtr _world, sdf::ElementPtr _sdf);
			RockBridge(); 
			~RockBridge();
			
		private:
			void worldCreated(std::string const&);
			void modelAdded(std::string const&);
			void createTask(gazebo::physics::WorldPtr, gazebo::physics::ModelPtr,int); 
			void updateBegin(gazebo::common::UpdateInfo const& info);
			void updateEnd();

			gazebo::ModelTask* task;
			std::vector<event::ConnectionPtr> eventHandler;

			typedef std::vector<gazebo::physics::WorldPtr> WorldContainer; 
			WorldContainer worlds; 

			typedef std::vector<gazebo::ModelTask*> ModelTasks;
			ModelTasks tasks;
			
//			typedef std::vector<RTT::extras::SlaveActivity*> Activities;
			typedef std::vector<RTT::Activity*> Activities;
			Activities activities;
	};
	
 	// Register this plugin with the simulator
	GZ_REGISTER_SYSTEM_PLUGIN(RockBridge)
}


#endif


