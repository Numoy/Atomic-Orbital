package de.numpy.orbital.graphic;

import android.graphics.Bitmap;
import android.graphics.Matrix;

import de.numpy.orbital.constants.Display;
import de.numpy.orbital.game.entitiy.components.PositionComponent;
import de.numpy.orbital.game.entitiy.components.basic.SizeComponent;

/**
 * Created by Marvin on 22.04.2018.
 */

public class Camera
{
  private float scaleFac;
  private float xCent;
  private float yCent;
  
  public Camera()
  {
    scaleFac = Display.WIDTH / 200f;
    xCent = Display.WIDTH / 2f;
    yCent = Display.HEIGHT / 2f;
  }
  
  public Matrix map( Bitmap bitmap, PositionComponent pos, SizeComponent size )
  {
    Matrix m = new Matrix();
    float x = calcX( pos.getX(), size.getWidth() );
    float y = calcY( pos.getY(), size.getHeight() );
    float scale = calcScale( bitmap.getWidth(), size.getWidth() );
    m.postRotate( pos.getPos().direction() );
    m.postScale( scale, scale );
    m.postTranslate( x, y );
    
    //Log.i( "Camera", "Pos:" + x + "," + y + " Scale: " + scale + " Rot: " + pos.getPhi() );
    return m;
  }
  
  private float calcScale( float bitmapWidth, float objectWidth )
  {
    return objectWidth * scaleFac / bitmapWidth;
  }
  
  private float calcX( float x, float width )
  {
    return xCent + ( x - width  / 2 ) * scaleFac;
  }
  
  private float calcY( float y, float height )
  {
    return yCent - ( y + height / 2 ) * scaleFac;
  }
  
}
