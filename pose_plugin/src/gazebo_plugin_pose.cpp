/*
 * gazebo_plugin_pose.cpp
 *
 *  Created on: Sep 23, 2014
 *      Author: Thomio Watanabe
 *      Brazilian Institute of Robotics
 */


#include <boost/bind.hpp>
#include <gazebo/gazebo.hh>
#include <gazebo/physics/physics.hh>
#include <gazebo/common/common.hh>
#include <stdio.h>

#include <gazebo/transport/transport.hh>
//#include <sdformat-2.0/sdf/parser.hh>
#include <gazebo/msgs/msgs.hh>
//#include <gazebo/msgs/pose.hh>
//#include "build/msgs/pose.pb.h"		// this include contains the pose msg scope

namespace gazebo
{
  class ModelPose : public WorldPlugin
  {
    private: msgs::Pose pose_msg;
	private: transport::NodePtr node; 		// Creates the communication node
	private: transport::MessagePtr msg;
  	private: transport::PublisherPtr posePublisher;		// Publisher to send msgs
    private: event::ConnectionPtr updateConnection;		// Pointer to the update event connection
    
	private: sdf::ElementPtr sdf;
	private: std::string model_name;
	private: std::string model_topic_name;
	private: physics::ModelPtr model;
	
    public: void Load(physics::WorldPtr _parent, sdf::ElementPtr _sdf)
    {
      // Save sdf pointer
	  this->sdf = _sdf; 
	  
	  // Get xml tags define inside the gazebo .world file
	  if(this->sdf->HasElement("modelName"))
	  	this->model_name = this->sdf->Get<std::string>("modelName");
	  else
	  	this->model_name = "stdModel";
	  
	  if(this->sdf->HasElement("modelTopicName"))
	  	this->model_topic_name = "/gazebo/rock/model/" + this->sdf->Get<std::string>("modelTopicName");
	  else
	  	this->model_topic_name = "/gazebo/rock/model/stdTopicName";
	  
	  // loads the model pointer (points to model_name)
	  model = _parent->GetModel(this->model_name.c_str());
	  
	  // Create a position and orientation pointer
      msgs::Vector3d *pos;
      msgs::Quaternion *ori;

      node = transport::NodePtr(new transport::Node());		// Opens comm port
      node->Init(_parent->GetName());	// Initialize the node with the model name
      // Opens publisher port. The topic name is: "/gazebo/rock/model" + "modelTopicName"
      posePublisher = node->Advertise<msgs::Pose>(this->model_topic_name.c_str());

      // Initialize pose_msg
      pose_msg.set_name(this->model_name.c_str());
      pose_msg.set_id(1);
      msgs::Set(pose_msg.mutable_position(),math::Vector3(0,0,0));
      msgs::Set(pose_msg.mutable_orientation(),math::Quaternion(0,0,0,0));

      // Listen to the update event. Triggered every simulation iteration
      this->updateConnection = event::Events::ConnectWorldUpdateBegin(
    		  boost::bind(&ModelPose::OnUpdate, this,_1));

      // PoseMSg.mutable();
      // posePublisher->Publish(pose_msg);
      // node->Publish(topic_name,PoseMsg);
    }

    // Called by the world update event
    public: void OnUpdate(const common::UpdateInfo & _info)
    {
    	// Read pose information, convert it to msgs::Pose and stores it in pose_msg
    	pose_msg = msgs::Convert(model->GetWorldPose());

    	// Publish the model pose inside topic_name
        this->posePublisher->Publish(pose_msg);
    }

  };

  // Register this plugin with the simulator
  GZ_REGISTER_WORLD_PLUGIN(ModelPose)
}

