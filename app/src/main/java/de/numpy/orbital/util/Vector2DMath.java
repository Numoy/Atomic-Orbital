package de.numpy.orbital.util;

public class Vector2DMath
{
  private Vector2DMath ()
  {
    // Static Helper
  }
  
  public static float xDist ( Vector2D v1, Vector2D v2 )
  {
    return Math.abs( v2.x - v1.x );
  }
  
  public static float yDis ( Vector2D v1, Vector2D v2 )
  {
    return Math.abs( v2.y - v1.y );
  }
  
  public static float dist ( Vector2D v1, Vector2D v2 )
  {
    return (float) Math.sqrt( ( v2.x - v1.x) * (v2.x - v1.x) + (v2.y - v1.y) * (v2.y - v1.y)  ) ;
  }
  
  public static float length( Vector2D v )
  {
    return (float) Math.sqrt( v.x*v.x + v.y*v.y );
  }
  
  public static Vector2D add ( Vector2D v1, Vector2D v2 )
  {
    return new Vector2D( v1.x + v2.x, v1.y + v2.y );
  }
}
