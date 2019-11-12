package de.numpy.orbital.game.entitiy.components.basic;

import java.util.Vector;

import de.numpy.orbital.util.CoordinateSystem;
import de.numpy.orbital.util.Vector2D;

/**
 * Created by Marvin on 05.05.2018.
 */

public class VelocityComponent
{
  private float xVel;
  private float yVel;
  
  private Vector2D vector = new Vector2D();
  
  public void setVelocity ( float v1, float v2, CoordinateSystem system )
  {
    if ( system == CoordinateSystem.CARTESIAN )
    {
      xVel = v1;
      yVel = v2;
    }
    if ( system == CoordinateSystem.POLAR )
    {
      xVel = v1 * (float) Math.cos( v2 );
      yVel = v1 * (float) Math.sin( v2 );
    }
  }
  
  public void setVelocity ( float x, float y )
  {
    setVelocity( x,y,CoordinateSystem.CARTESIAN );
  }
  
  public void addVelocity( float v1, float v2, CoordinateSystem system )
  {
    if( system == CoordinateSystem.CARTESIAN )
    {
      xVel += v1;
      yVel += v2;
    }
    if ( system == CoordinateSystem.POLAR )
    {
      xVel += v1 * (float) Math.cos( v2 );
      yVel += v1 * (float) Math.sin( v2 );
    }
  }
  
  public void addVelocity( float x, float y )
  {
    setVelocity( x, y, CoordinateSystem.CARTESIAN );
  }
  
  public float getXVel()
  {
    return xVel;
  }
  
  public float getYVel()
  {
    return yVel;
  }
  
  public Vector2D getVector()
  {
    vector.x = xVel;
    vector.y = yVel;
    return vector;
  }
  
  public float getTotalVel()
  {
    return (float) Math.sqrt( xVel*xVel + yVel*yVel );
  }
  
  public float getDir()
  {
    return (float) Math.atan2( yVel, xVel );
  }
  
}
