/*
 * gazebo_plugin_force.hpp
 *
 *  Created on: Oct 6, 2014
 *      Author: thomio
 */

#ifndef GAZEBO_PLUGIN_FORCE_HPP_
#define GAZEBO_PLUGIN_FORCE_HPP_



namespace gazebo
{
  class ModelForce : public WorldPlugin
  {

    public: void Load(physics::WorldPtr _parent, sdf::ElementPtr _sdf);


  };
}




#endif /* GAZEBO_PLUGIN_FORCE_HPP_ */
