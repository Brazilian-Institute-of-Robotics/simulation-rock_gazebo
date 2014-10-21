/*
 * gazebo_plugin_velocity.hpp
 *
 *  Created on: Oct 6, 2014
 *      Author: thomio
 */

#ifndef GAZEBO_PLUGIN_VELOCITY_HPP_
#define GAZEBO_PLUGIN_VELOCITY_HPP_



namespace gazebo
{
  class ModelVelocity : public WorldPlugin
  {

    public: void Load(physics::WorldPtr _parent, sdf::ElementPtr _sdf);


  };
}




#endif /* GAZEBO_PLUGIN_VELOCITY_HPP_ */
