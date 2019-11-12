package de.numpy.orbital.util;

import de.numpy.orbital.util.math.MathUtils;

/**
 * Created by Marvin on 05.05.2018.
 */

public class Vector2D
{
  public float x;
  public float y;
  
  public Vector2D( float x, float y )
  {
    this.x = x;
    this.y = y;
  }
  
  public Vector2D()
  {
    this( 0,0 );
  }
  
  public void add( Vector2D v )
  {
    x += v.x;
    y += v.y;
  }
  
  public float length()
  {
    return (float) Math.sqrt( x*x + y*y );
  }
  
  public float direction()
  {
    return MathUtils.atan2( y, x );
  }
  
  public Vector2D rotate( float phi )
  {
    float temp = x * MathUtils.cos( phi ) - y * MathUtils.sin( phi );
    y = x * MathUtils.sin( phi ) + y * MathUtils.cos( phi );
    x = temp;
    return this;
  }
  
  public Vector2DPolar toPolar()
  {
    return new Vector2DPolar( length(), direction() );
  }
}
