package de.numpy.orbital.game.entitiy.components.photon.types;

import android.util.Log;

import de.numpy.orbital.game.entitiy.components.PositionComponent;
import de.numpy.orbital.util.Vector2D;

/**
 * Created by Marvin on 05.05.2018.
 */
public class SpiralType implements PhotonType
{
  private static final float VEL_R = 60f;
  private static final float VEL_PHI = 80f;
  private PositionComponent pos;
  private Vector2D vel;
  private int dir;
  
  public SpiralType( int dir )
  {
    this.dir = dir;
  }
  
  public void init ( PositionComponent pos )
  {
    this.pos = pos;
    vel = new Vector2D();
  }
  
  @Override
  public void update ( double dTime )
  {
    vel.x = VEL_R;
    vel.y = VEL_PHI * dir;
    vel.rotate( pos.getPos().direction() );
    pos.setVelocity( vel );
    pos.applyVelocity( dTime );
  }
}
