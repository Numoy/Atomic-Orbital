package de.numpy.orbital.game.entitiy.components;

import de.numpy.orbital.util.Vector2D;
import de.numpy.orbital.util.Vector2DPolar;

public class PositionComponent
{
  private Vector2D pos;
  private Vector2D vel;
  private float dir;
  
  public PositionComponent ()
  {
    pos = new Vector2D(0,0);
    vel = new Vector2D(0,0);
    dir = 0;
  }
  
  public void applyVelocity( double dt )
  {
    pos.x += dt * vel.x;
    pos.y += dt * vel.y;
  }
  
  public void setPosition( Vector2D v )
  {
    pos = v;
  }
  
  public void setPosition( Vector2DPolar v )
  {
    pos = v.toCarth();
  }
  
  public void setVelocity( Vector2D v )
  {
    vel = v;
  }
  
  public void setVelocity( Vector2DPolar v )
  {
    vel = v.toCarth();
  }
  
  public void setDirection( float dir )
  {
    this.dir = dir;
  }
  
  public Vector2D getPos ()
  {
    return pos;
  }
  
  public float getX ()
  {
    return pos.x;
  }
  
  public float getY ()
  {
    return pos.y;
  }
}
