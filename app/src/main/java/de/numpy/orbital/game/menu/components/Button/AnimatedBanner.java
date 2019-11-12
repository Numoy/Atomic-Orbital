package de.numpy.orbital.game.menu.components.Button;

import android.graphics.Bitmap;
import android.util.Log;

import de.numpy.orbital.graphic.Graphic;
import de.numpy.orbital.util.Vector2D;

/**
 * Created by Marvin on 27.05.2018.
 */

public class AnimatedBanner extends Banner
{
  private int alpha;
  private float t;
  private static final double FREQUENCY = 3;
  
  public AnimatedBanner ( Bitmap bitmap, Vector2D size )
  {
    super( bitmap, size );
    alpha = 255;
    t = 0;
  }
  
  @Override
  public void handleAnimation ( double dt )
  {
    t+= FREQUENCY * dt;
    alpha = 128 + (int) ( 128 * Math.sin( t ) );
  }
  
  @Override
  public void render ( Graphic graphic )
  {
    graphic.drawBitmap( bitmap, pos, size, alpha );
  }
}
