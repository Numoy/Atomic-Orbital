package de.numpy.orbital.game.entitiy.components.photon.types;

import de.numpy.orbital.game.entitiy.components.PositionComponent;
import de.numpy.orbital.util.Vector2DPolar;

/**
 * Created by Marvin on 05.05.2018.
 */

public class StraightType implements PhotonType
{
  private static final float VEL = 100f;
  private PositionComponent pos;
  
  @Override
  public void init ( PositionComponent pos )
  {
    this.pos = pos;
    Vector2DPolar vel = new Vector2DPolar();
    vel.r = VEL;
    vel.phi = pos.getPos().direction();
    pos.setVelocity( vel );
  }
  
  @Override
  public void update ( double dTime )
  {
    pos.applyVelocity( dTime );
  }
}
