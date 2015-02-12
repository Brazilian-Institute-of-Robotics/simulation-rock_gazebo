//======================================================================================
// Brazilian Institute of Robotics 
// Authors: Thomio Watanabe
//====================================================================================== 
#ifndef _ROCK_BRIDGE_HPP_
#define _ROCK_BRIDGE_HPP_

// Gazebo headers
#include <boost/bind.hpp>
#include <gazebo/gazebo.hh>
#include <gazebo/physics/physics.hh>
#include <gazebo/common/common.hh>
#include <gazebo/common/Plugin.hh>

namespace RTT
{
    class TaskContext;
    namespace base
    {
        class ActivityInterface;
    }
}


namespace rock_gazebo
{
    class ModelTask; 
    class WorldTask;

	class RockBridge: public gazebo::SystemPlugin
	{
		public:
			// Pure virtual function implementation
			virtual void Load(int _argc = 0, char** _argv = NULL);
//			virtual void Load(physics::WorldPtr _world, sdf::ElementPtr _sdf);
			RockBridge(); 
			~RockBridge();
			
		private:
			void worldCreated(std::string const&);
//			void modelAdded(std::string const&);
			void createTask(gazebo::physics::WorldPtr, gazebo::physics::ModelPtr); 
			void updateBegin(gazebo::common::UpdateInfo const& info);
			void updateEnd();
            void setupTaskActivity(RTT::TaskContext* task);

			std::vector<gazebo::event::ConnectionPtr> eventHandler;

//          typedef std::vector<RTT::TaskContext*> Tasks;
//          Tasks tasks;
			typedef std::vector<RTT::base::ActivityInterface*> Activities;
			Activities activities;
//			typedef std::vector<gazebo::physics::WorldPtr> WorldContainer; 
//			WorldContainer worlds; 
	};
	
 	// Register this plugin with the simulator
	GZ_REGISTER_SYSTEM_PLUGIN(RockBridge)

} // end namespace rock_gazebo

#endif
