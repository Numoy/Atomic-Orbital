package de.numpy.orbital.game.entitiy.components.photon.types;

import de.numpy.orbital.game.entitiy.components.PositionComponent;

/**
 * Created by Marvin on 05.05.2018.
 */

public interface PhotonType
{
  void init( PositionComponent pos );
  void update( double dTime );
}
