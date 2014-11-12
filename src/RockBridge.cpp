
#include "RockBridge.hpp"

using namespace gazebo;

//======================================================================================

void RockBridge::Load(physics::WorldPtr _parent, sdf::ElementPtr _sdf)
{
	// Save world and sdf pointer
	sdf = _sdf;
	parent = _parent;

	// In the end of each simulation step the Update method is called to update the simulated sensors and actuators
	endUpdate.push_back(
			event::Events::ConnectWorldUpdateEnd(
					boost::bind(&RockBridge::updateSimulation,this)));

	readWorld();
}

//======================================================================================

void RockBridge::readWorld()
{
//	// Get xml tags defined inside the gazebo .world file
//	if(this->sdf->HasElement("modelName"))
//	{
//		sdf::ElementPtr modelElement = this->sdf->GetElement("modelName");
//		while(modelElement)
//		{
//			model_name = this->sdf->Get<std::string>("modelName");
//			modelElement = modelElement->GetNextElement("modelName");
//		}
//	}

	 // Get xml tags define inside the gazebo .world file
	if(this->sdf->HasElement("modelName"))
		model_name = this->sdf->Get<std::string>("modelName");
	else
		model_name = "stdModel";

	if(this->sdf->HasElement("modelTopicName"))
		topic_name = "/gazebo/rock/model/" + this->sdf->Get<std::string>("modelTopicName");
	else
		topic_name = "/gazebo/rock/model/stdTopicName";


	// Loads the model pointer (points to model_name)
	model = parent->GetModel(this->model_name.c_str());

	// Load robots joints
	robot_left_joint = model->GetJoint("left_wheel_hinge");
	robot_right_joint = model->GetJoint("right_wheel_hinge");

	initRockDCMotor();
}

//======================================================================================

void RockBridge::initRockDCMotor()
{
	// Initialize rock DCMotor component
	dcmotor = new gazebo::DCMotorTask();

	// Import typekits to allow RTT convert the types used by the components
	RTT::types::TypekitRepository::Import(new orogen_typekits::gazeboTypekitPlugin);
	// RTT::types::TypekitRepository::Import(new orogen_typekits::gazeboCorbaTransportPlugin);
	// RTT::types::TypekitRepository::Import(new orogen_typekits::gazeboMQueueTransportPlugin);
	// RTT::types::TypekitRepository::Import(new orogen_typekits::gazeboTypelibTransportPlugin);

	// Export the component interface on CORBA to Ruby access the component
	RTT::corba::TaskContextServer::Create(dcmotor);

	// Set up the component activity
	activity_dcmotor = new RTT::Activity(
			SCHED_OTHER,
			RTT::os::LowestPriority,
			0.01,
			dcmotor->engine(),
			"orogen_default_rock_dcmotor");
}

//======================================================================================

// Callback method triggered every update end by endUpdate()
// It test conditions and implement all rock components functionalities
void RockBridge::updateSimulation()
{
	static double dc_motor_torque;
	dc_motor_torque = dcmotor->getAttribute("torque");
	applyForce(dc_motor_torque);
}

//======================================================================================

void RockBridge::applyForce(double torque)
{
	robot_left_joint->SetForce(robot_left_joint->GetId(),torque);
	robot_right_joint->SetForce(robot_right_joint->GetId(),torque);
}

//======================================================================================
