package de.numpy.orbital.game.entitiy.components.photon.types;

import de.numpy.orbital.game.entitiy.components.PositionComponent;
import de.numpy.orbital.util.Vector2D;
import de.numpy.orbital.util.math.MathUtils;

/**
 * Nicht wirklich sinusförmig, aber egal
 *
 * Created by Marvin on 05.05.2018.
 */

public class SinusType implements PhotonType
{
  private static final float VEL_R = 60f;
  private static final float VEL_PHI = 150f;
  private static final float FREQUENCY = 6f ;
  
  private PositionComponent pos;
  
  private Vector2D vel;
  private float alpha;
  private float initialPhi;
  
  public SinusType()
  {
    alpha = 0;
  }
  
  public void init ( PositionComponent pos )
  {
    this.pos = pos;
    vel = new Vector2D();
    initialPhi = pos.getPos().direction();
  }
  
  @Override
  public void update ( double dTime )
  {
    alpha += dTime * FREQUENCY;
    vel.x = VEL_R;
    vel.y = VEL_PHI * MathUtils.cos( alpha ) * pos.getPos().length() / 100;
    vel.rotate( initialPhi );
    pos.setVelocity( vel );
    pos.applyVelocity( dTime );
  }
}
