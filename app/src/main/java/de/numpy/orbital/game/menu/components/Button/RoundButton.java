package de.numpy.orbital.game.menu.components.Button;

import android.graphics.Bitmap;

import de.numpy.orbital.game.menu.components.Button.Button;
import de.numpy.orbital.graphic.BitmapType;
import de.numpy.orbital.locator.Locator;
import de.numpy.orbital.util.Vector2D;
import de.numpy.orbital.util.Vector2DMath;

/**
 * Created by Marvin on 27.05.2018.
 */

public class RoundButton extends Button
{
  
  
  public RoundButton ( Bitmap bitmap, float radius )
  {
    super( bitmap, new Vector2D( 2* radius, 2* radius ) );
  }
  
  public void setSize( float r )
  {
    setSize( new Vector2D( 2* r, 2* r ) );
  }
  
  public void setPosition ( Vector2D center )
  {
    setCenter( center );
  }
  
  @Override
  public boolean contains ( Vector2D v )
  {
    return Vector2DMath.dist( v, getCenter() ) < size.x;
  }
}
