#include "RockBridge.hpp"

#include <gazebo/DCMotorTask.hpp>

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

	// In the end of each simulation step the Update method is called to update the simulated sensors and actuators
//	endUpdate.push_back(
//			event::Events::ConnectWorldUpdateBegin(
//					boost::bind(&RockBridge::updateBegin,this, _1)));
	endUpdate.push_back(
			event::Events::ConnectWorldUpdateEnd(
					boost::bind(&RockBridge::updateEnd,this)));
	endUpdate.push_back(
			event::Events::ConnectWorldCreated(
					boost::bind(&RockBridge::worldCreated,this, _1)));
}

//======================================================================================

void RockBridge::worldCreated(std::string const& worldName)
{
    gzmsg << "rock: initializing for world " << worldName << std::endl;
    
	physics::WorldPtr world = physics::get_world(worldName);
	
    if (!world)
    {
            gzerr << "rock: cannot find world " << worldName << std::endl;
            return;
    }
	
	physics::ModelPtr model = world->GetModel("my_robot");

    if (model)
    {
        gzmsg << "rock: initializing model my_robot" << std::endl;
		// Load robots joints
		robot_left_joint = model->GetJoint("left_wheel_hinge");
		robot_right_joint = model->GetJoint("right_wheel_hinge");
        if (robot_left_joint && robot_right_joint)
                gzmsg << "rock: found expected joints" << std::endl;

    	initRockDCMotor();
    }
}

//======================================================================================

void RockBridge::initRockDCMotor()
{
	// Initialize rock DCMotor component
	dc_motor_task = new gazebo::DCMotorTask();

	// Export the component interface on CORBA to Ruby access the component
	RTT::corba::TaskContextServer::Create(dc_motor_task);

	// Set up the component activity
	activity_dcmotor = new RTT::Activity(
			SCHED_OTHER,
			RTT::os::LowestPriority,
			0.0,
			dc_motor_task->engine(),
			"orogen_default_rock_dcmotor");
			
	dc_motor_port = dynamic_cast<RTT::InputPort<double>*>(dc_motor_task->provides()->getPort("dc_motor_torque"));
}

//======================================================================================

//void RockBridge::updateBegin(common::UpdateInfo const& info)
//{ 
//}


// Callback method triggered every update end by endUpdate()
// It test conditions and implement all rock components functionalities
void RockBridge::updateEnd()
{
	double torque = 0;

    if (dc_motor_port)
            if (dc_motor_port->readNewest(torque) == RTT::NewData)	
                    applyForce(torque);
}

//======================================================================================

void RockBridge::applyForce(double torque=0)
{
	robot_left_joint->SetForce(robot_left_joint->GetId(),torque);
	robot_right_joint->SetForce(robot_right_joint->GetId(),torque);
}

//======================================================================================
