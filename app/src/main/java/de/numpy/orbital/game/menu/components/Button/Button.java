package de.numpy.orbital.game.menu.components.Button;

import android.graphics.Bitmap;

import de.numpy.orbital.game.menu.components.MenuComponent;
import de.numpy.orbital.graphic.Graphic;
import de.numpy.orbital.util.Vector2D;

/**
 * Created by Marvin on 27.05.2018.
 */

public abstract class Button extends Banner
{
  protected Button( Bitmap bitmap, Vector2D size )
  {
    super( bitmap, size );
  }
  
  public abstract boolean contains( Vector2D v );
}
