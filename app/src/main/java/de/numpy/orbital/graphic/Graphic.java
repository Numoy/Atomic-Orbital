package de.numpy.orbital.graphic;

import android.graphics.Bitmap;
import android.graphics.Matrix;

import de.numpy.orbital.game.entitiy.components.PositionComponent;
import de.numpy.orbital.game.entitiy.components.basic.SizeComponent;
import de.numpy.orbital.util.Vector2D;

/**
 * Created by Marvin on 22.04.2018.
 */

public class Graphic
{
  private GraphicInterface impl;
  private Camera camera;
  
  public Graphic ( GraphicInterface impl )
  {
    this.impl = impl;
    camera = new Camera();
  }
  
  public void drawBitmap ( Bitmap bitmap, PositionComponent pos, SizeComponent size )
  {
    Matrix m = camera.map( bitmap, pos, size );
    impl.drawBitmap( bitmap, m );
  }
  
  public void drawBitmap( Bitmap bitmap, Vector2D pos, Vector2D size )
  {
    Matrix m = createMatrix( bitmap, pos, size );
    impl.drawBitmap( bitmap, m );
  }
  
  public void drawBitmap( Bitmap bitmap, Vector2D pos, Vector2D size, int alpha )
  {
    Matrix m = createMatrix( bitmap, pos, size );
    impl.drawBitmap( bitmap, m, alpha );
  }
  
  private Matrix createMatrix( Bitmap bitmap, Vector2D pos, Vector2D size )
  {
    Matrix m = new Matrix();
    m.setScale( size.x / bitmap.getWidth(), size.y / bitmap.getHeight()  );
    m.postTranslate( pos.x, pos.y );
    return m;
  }
  
  public void start ()
  {
    impl.start();
  }
  
  public void end ()
  {
    impl.end();
  }
}
