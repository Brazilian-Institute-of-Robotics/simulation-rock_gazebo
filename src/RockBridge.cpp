#include "RockBridge.hpp"

#include <gazebo/ModelTask.hpp>

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

using namespace gazebo;


//======================================================================================

void RockBridge::Load(int _argc, char **_argv)
{
	RTT::corba::ApplicationServer::InitOrb(_argc, _argv);
	
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
// worldCreated() is called every time a world in inserted in gazebo
void RockBridge::worldCreated(std::string const& worldName)
{
    gzmsg << "RockBridge: initializing world: " << worldName << std::endl;

	physics::WorldPtr world = physics::get_world(worldName);
    if (!world)
    {
            gzerr << "rock: cannot find world " << worldName << std::endl;
            return;
    }
    
    		
    typedef physics::Model_V Model_V;
    Model_V model_list = world->GetModels();
	for(Model_V::iterator it = model_list.begin(); it != model_list.end(); ++it)
	{
		gzmsg << "RockBridge: initializing model: "<< (*it)->GetName() << std::endl;

		// Create and initialize rock component
		gazebo::ModelTask* task = new gazebo::ModelTask();
		tasks.push_back(task);
		task->setGazeboModel(world, *it);
		
		
		// Export the component interface on CORBA to Ruby access the component
		RTT::corba::TaskContextServer::Create( task );

		// Set up the component activity
		RTT::Activity* activity = new RTT::Activity(
				SCHED_OTHER,
				RTT::os::LowestPriority,
				0.0,
				task->engine(),
				"orogen_default_rock_gazebo");
		activities.push_back(activity);
		
		task->start();
		
		RTT::corba::TaskContextServer::ThreadOrb(SCHED_OTHER, RTT::os::LowestPriority, 0);
	}
	model_list.clear();
}

//======================================================================================
// Callback method triggered every update begin
// It test conditions and implement all rock components functionalities
void RockBridge::updateBegin(common::UpdateInfo const& info)
{
	for(ModelTasks::iterator it = tasks.begin(); it != tasks.end(); ++it)
	{
		(*it)->updateModel();
	}

//	for (Activities::iterator it = activities.begin(); it != activities.end(); ++it)
//	{
//		(*it)->step();
//	}
}

//======================================================================================

void RockBridge::updateEnd()
{
}
//======================================================================================
RockBridge::~RockBridge()
{
	activities.clear();
	tasks.clear();
    RTT::corba::TaskContextServer::ShutdownOrb();
    RTT::corba::TaskContextServer::DestroyOrb();	
}
//======================================================================================
