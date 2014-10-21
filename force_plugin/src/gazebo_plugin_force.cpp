//============================================================================
// Name        : gazebo_plugin_force.cpp
// Company 	   : Brazilian Institute of Robotics
// Author      : Thomio Watanabe
// Date		   : Oct. 06, 2014
// Version     :
// Copyright   :
// Description : This plugin applies a force over a gazebo robot joint
//============================================================================



// 1 - Alterar o typo de ConstForcePtr para double
// 2 - Colocat os códigos no arquivo .hpp (de todos os códigos)
// 3 - Alterar o código para ser independente da quantidade de atributos do robô


#include <boost/bind.hpp>
#include <gazebo/gazebo.hh>
#include <gazebo/physics/physics.hh>
#include <gazebo/common/common.hh>
#include <stdio.h>

#include <gazebo/transport/transport.hh>
//#include <sdformat-2.0/sdf/sdf.hh>
#include <gazebo/msgs/msgs.hh>
//#include <gazebo/msgs/pose.hh>
//#include "build/msgs/pose.pb.h"		// this include contains the pose msg scope

namespace gazebo
{
	//gazebo::msgs::Vector3d
  typedef const boost::shared_ptr<const msgs::Vector3d> ConstForcePtr;

  class ModelForce : public WorldPlugin
  {
  	// private: msgs::Pose pose_msg;
	private: transport::NodePtr node; 		// Creates the communication node
	// private: transport::MessagePtr msg;

	// private: event::ConnectionPtr updateConnection;		// Pointer to the update event connection

	private: sdf::ElementPtr sdf;
	private: std::string model_name;
	private: std::string topic_name;
	private: physics::ModelPtr model;

	private:transport::SubscriberPtr mpSubs;

	gazebo::physics::JointPtr robot_left_joint;
	gazebo::physics::JointPtr robot_right_joint;


  	public: void Load(physics::WorldPtr _parent, sdf::ElementPtr _sdf)
    {
      // Save sdf pointer
	  this->sdf = _sdf;

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
	  model = _parent->GetModel(this->model_name.c_str());

	  // Load robots joints
	  robot_left_joint = model->GetJoint("left_wheel_hinge");
	  robot_right_joint = model->GetJoint("right_wheel_hinge");

	  // Opens comm port
      node = transport::NodePtr(new transport::Node());

      // Initialize the node with the model name
      node->Init(_parent->GetName());

      // Opens subscriber port. The topic name is: "/gazebo/rock/model" + "modelTopicName"
      mpSubs = node->Subscribe(this->topic_name.c_str(),&ModelForce::ApplyForce,this);
    }

    public: void ApplyForce(ConstForcePtr &_force)
    {
    	// Apply a force over a robot joint. The force must be applied every simulation step.
    	robot_left_joint->SetForce(robot_left_joint->GetId(),_force->x());
    	robot_right_joint->SetForce(robot_right_joint->GetId(),_force->x());
    }

  };

  // Register this plugin with the simulator
  GZ_REGISTER_WORLD_PLUGIN(ModelForce)
}
