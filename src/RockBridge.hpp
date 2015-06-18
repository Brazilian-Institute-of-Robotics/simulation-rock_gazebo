//======================================================================================
// Brazilian Institute of Robotics 
// Authors: Thomio Watanabe
//====================================================================================== 
#ifndef _ROCK_BRIDGE_HPP_
#define _ROCK_BRIDGE_HPP_

// Gazebo headers
#include <boost/bind.hpp>
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

    class RockBridge: public gazebo::SystemPlugin
    {
        public:
            // Pure virtual function implementation
            virtual void Load(int _argc = 0, char** _argv = NULL);
            RockBridge(); 
            ~RockBridge();

            typedef gazebo::physics::ModelPtr ModelPtr;

        private:
            void worldCreated(std::string const&);
            // void modelAdded(std::string const&);
            void updateBegin(gazebo::common::UpdateInfo const& info);
            void setupTaskActivity(RTT::TaskContext* task);

            void instantiatePluginComponents( sdf::ElementPtr modelElement, ModelPtr model );

            std::vector<gazebo::event::ConnectionPtr> eventHandler;

            typedef std::vector<RTT::TaskContext*> Tasks;
            Tasks tasks;
            typedef std::vector<RTT::base::ActivityInterface*> Activities;
            Activities activities;
    };

    // Register this plugin with the simulator
    GZ_REGISTER_SYSTEM_PLUGIN(RockBridge)

} // end namespace rock_gazebo

#endif
