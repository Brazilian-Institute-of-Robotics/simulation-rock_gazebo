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

#define GROUND 0
#define UNDERWATER 1

namespace RTT
{
    class TaskContext;
    namespace base
    {
        class ActivityInterface;
    }
}

namespace gazebo
{
    class ModelTask; 
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
            void setupTaskActivity(RTT::TaskContext* task);

			std::vector<event::ConnectionPtr> eventHandler;

            typedef std::vector<RTT::TaskContext*> Tasks;
            Tasks tasks;
			typedef std::vector<RTT::base::ActivityInterface*> Activities;
			typedef std::vector<gazebo::physics::WorldPtr> WorldContainer; 
			WorldContainer worlds; 

			Activities activities;
	};
	
 	// Register this plugin with the simulator
	GZ_REGISTER_SYSTEM_PLUGIN(RockBridge)
}


#endif


