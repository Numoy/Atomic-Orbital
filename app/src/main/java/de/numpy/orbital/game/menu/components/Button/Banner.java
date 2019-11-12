package de.numpy.orbital.game.menu.components.Button;

import android.graphics.Bitmap;

import de.numpy.orbital.game.menu.components.MenuComponent;
import de.numpy.orbital.graphic.Graphic;
import de.numpy.orbital.util.Vector2D;

/**
 * Created by Marvin on 27.05.2018.
 */

public class Banner implements MenuComponent
{
  protected Bitmap bitmap;
  
  protected Vector2D pos;
  protected Vector2D size;
  protected Vector2D center;
  
  public Banner( Bitmap bitmap, Vector2D size )
  {
    this.bitmap = bitmap;
    this.size = size;
    pos = new Vector2D();
    center = new Vector2D();
  }
  
  protected void setPos( Vector2D newPos )
  {
    pos.x = newPos.x;
    pos.y = newPos.y;
    updateCenter();
  }
  
  public void setCenter( Vector2D newCenter )
  {
    center.x = newCenter.x;
    center.y = newCenter.y;
    pos.x = center.x - size.x / 2;
    pos.y = center.y - size.y / 2;
  }
  
  protected void setSize( Vector2D newSize )
  {
    size.x = newSize.x;
    size.y = newSize.y;
    updateCenter();
  }
  
  private void updateCenter()
  {
    center.x = pos.x + size.x / 2;
    center.y = pos.y + size.y / 2;
  }
  
  protected Vector2D getCenter()
  {
    return center;
  }
  
  @Override
  public void render ( Graphic graphic )
  {
    graphic.drawBitmap( bitmap, pos, size );
  }
  
  @Override
  public void handleAnimation ( double dt )
  {
  
  }
}
