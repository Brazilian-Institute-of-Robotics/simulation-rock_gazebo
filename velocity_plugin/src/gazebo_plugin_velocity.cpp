//============================================================================
// Name        : gazebo_plugin_velocity.cpp
// Company 	   : Brazilian Institute of Robotics
// Author      : Thomio Watanabe
// Date		   : Oct. 06, 2014
// Version     :
// Copyright   :
// Description : This plugin applies a velocity over a gazebo robot (model)
//============================================================================

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
  typedef const boost::shared_ptr<const gazebo::msgs::Vector3d> ConstVelocityPtr;

  class ModelVelocity : public WorldPlugin
  {
  	// private: msgs::Pose pose_msg;
	private: transport::NodePtr node; 		// Creates the communication node
	// private: transport::MessagePtr msg;
	private: event::ConnectionPtr updateConnection;		// Pointer to the update event connection

	private: sdf::ElementPtr sdf;
	private: std::string model_name;
	private: std::string topic_name;
	private: physics::ModelPtr model;

	private:transport::SubscriberPtr mpSubs;


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

	  // Opens comm port
      node = transport::NodePtr(new transport::Node());

      // Initialize the node with the model name
      node->Init(_parent->GetName());

      // Opens Subscriber port. The topic name is: "/gazebo/rock/model" + "modelTopicName"
      mpSubs = node->Subscribe(this->topic_name.c_str(),&ModelVelocity::ApplyVelocity,this);

    }

    public: void ApplyVelocity(ConstVelocityPtr &_velocity)
    {
    	// Apply a velocity over a model. The velocity must be applied every simulation step.
    	model->SetLinearVel(msgs::Convert(*_velocity));
    }

  };

  // Register this plugin with the simulator
  GZ_REGISTER_WORLD_PLUGIN(ModelVelocity)
}
