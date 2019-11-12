package de.numpy.orbital.util;

public class Vector2DPolar
{
  public float r;
  public float phi;
  
  public Vector2DPolar( float r, float phi )
  {
    this.r = r;
    this.phi = phi;
  }
  
  public Vector2DPolar()
  {
    this( 0, 0 );
  }
  
  public Vector2D toCarth()
  {
    return new Vector2D( r * (float) Math.cos( phi ), r * (float) Math.sin( phi ) );
  }
}
