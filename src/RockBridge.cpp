//====================================================================================== 
#include "RockBridge.hpp"

#include <gazebo/ModelTask.hpp>
#include <gazebo/WorldTask.hpp>

#include <std/typekit/Plugin.hpp>
#include <std/transports/corba/TransportPlugin.hpp>
#include <std/transports/typelib/TransportPlugin.hpp>
#include <std/transports/mqueue/TransportPlugin.hpp>

#include <base/typekit/Plugin.hpp>
#include <base/transports/corba/TransportPlugin.hpp>
#include <base/transports/typelib/TransportPlugin.hpp>
#include <base/transports/mqueue/TransportPlugin.hpp>

#include <gazebo/typekit/Plugin.hpp>
#include <gazebo/transports/corba/TransportPlugin.hpp>
#include <gazebo/transports/typelib/TransportPlugin.hpp>
#include <gazebo/transports/mqueue/TransportPlugin.hpp>

#include <rtt/base/ActivityInterface.hpp>
#include <rtt/TaskContext.hpp>
#include <rtt/extras/SequentialActivity.hpp>
#include <rtt/transports/corba/ApplicationServer.hpp>
#include <rtt/transports/corba/TaskContextServer.hpp>


using namespace gazebo;
using namespace rock_gazebo;

//======================================================================================

void RockBridge::Load(int _argc , char** _argv)
{
    RTT::corba::ApplicationServer::InitOrb(_argc, _argv);
    RTT::corba::TaskContextServer::ThreadOrb(ORO_SCHED_OTHER, RTT::os::LowestPriority, 0);

    // Import typekits to allow RTT convert the types used by the components
    RTT::types::TypekitRepository::Import(new orogen_typekits::stdTypekitPlugin);
    RTT::types::TypekitRepository::Import(new orogen_typekits::stdCorbaTransportPlugin);
    RTT::types::TypekitRepository::Import(new orogen_typekits::stdMQueueTransportPlugin);
    RTT::types::TypekitRepository::Import(new orogen_typekits::stdTypelibTransportPlugin);

    RTT::types::TypekitRepository::Import(new orogen_typekits::baseTypekitPlugin);
    RTT::types::TypekitRepository::Import(new orogen_typekits::baseCorbaTransportPlugin);
    RTT::types::TypekitRepository::Import(new orogen_typekits::baseMQueueTransportPlugin);
    RTT::types::TypekitRepository::Import(new orogen_typekits::baseTypelibTransportPlugin);

    RTT::types::TypekitRepository::Import(new orogen_typekits::gazeboTypekitPlugin);
    RTT::types::TypekitRepository::Import(new orogen_typekits::gazeboCorbaTransportPlugin);
    RTT::types::TypekitRepository::Import(new orogen_typekits::gazeboMQueueTransportPlugin);
    RTT::types::TypekitRepository::Import(new orogen_typekits::gazeboTypelibTransportPlugin);


    // Each simulation step the Update method is called to update the simulated sensors and actuators
    eventHandler.push_back(
            event::Events::ConnectWorldUpdateBegin(
                boost::bind(&RockBridge::updateBegin,this, _1)));
    eventHandler.push_back(
            event::Events::ConnectWorldUpdateEnd(
                boost::bind(&RockBridge::updateEnd,this)));
    eventHandler.push_back(
            event::Events::ConnectWorldCreated(
                boost::bind(&RockBridge::worldCreated,this, _1)));
}
//======================================================================================
// worldCreated() is called every time a world is added
void RockBridge::worldCreated(std::string const& worldName)
{
    gzmsg << "RockBridge: initializing world: " << worldName << std::endl;

    physics::WorldPtr world = physics::get_world(worldName);
    if (!world)
    {
        gzerr << "RockBridge: cannot find world " << worldName << std::endl;
        return;
    }

    WorldTask* world_task = new WorldTask();
    world_task->setGazeboWorld(world);
    setupTaskActivity(world_task);
    tasks.push_back(world_task);

    typedef physics::Model_V Model_V;
    Model_V model_list = world->GetModels();
    for(Model_V::iterator model_it = model_list.begin(); model_it != model_list.end(); ++model_it)
    {
        createTask(world,*model_it);
    }
    model_list.clear();
}

void RockBridge::setupTaskActivity(RTT::TaskContext* task)
{
    // Export the component interface on CORBA to Ruby access the component
    RTT::corba::TaskContextServer::Create( task );

    // Set up the component activity_signal
    RTT::extras::SequentialActivity* activity =
        new RTT::extras::SequentialActivity(task->engine());
    activity->start();
    activities.push_back(activity);
    tasks.push_back(task);
}

//======================================================================================
void RockBridge::createTask(physics::WorldPtr world, physics::ModelPtr model)
{
    std::cout << " ~ " << std::endl;
    gzmsg << "RockBridge: initializing model: "<< (model)->GetName() << std::endl;

    // Create and initialize one rock component for each gazebo model
    ModelTask* task = new ModelTask();
    task->setGazeboModel(world, model);
    setupTaskActivity(task);
}
//======================================================================================
// Callback method triggered every update begin
// It test conditions and implement all rock components functionalities
void RockBridge::updateBegin(common::UpdateInfo const& info)
{
    for(Activities::iterator it = activities.begin(); it != activities.end(); ++it)
    {
        (*it)->trigger();
    }
}

//======================================================================================
void RockBridge::updateEnd()
{
}
//======================================================================================
RockBridge::RockBridge()
{
}
//======================================================================================
RockBridge::~RockBridge()
{
    // Delete pointers to activity
    for(Activities::iterator activity_it = activities.begin(); 
            activity_it != activities.end(); ++activity_it)
    {
        delete *activity_it;
    }
    activities.clear();

    // Delete pointers to tasks
    for(Tasks::iterator task_it = tasks.begin();
            task_it != tasks.end(); ++task_it)
    {
        delete *task_it;
    }
    tasks.clear();

    RTT::corba::TaskContextServer::ShutdownOrb();
    RTT::corba::TaskContextServer::DestroyOrb();	
}
//======================================================================================
