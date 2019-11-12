package de.numpy.orbital.game.entitiy.components.basic;

import android.graphics.Bitmap;

import de.numpy.orbital.game.entitiy.components.GraphicComponent;
import de.numpy.orbital.game.entitiy.components.PositionComponent;
import de.numpy.orbital.graphic.BitmapType;
import de.numpy.orbital.graphic.Graphic;
import de.numpy.orbital.locator.Locator;

/**
 * Created by Marvin on 05.05.2018.
 */

public class BasicGraphicComponent implements GraphicComponent
{
  private Bitmap bitmap;
  private PositionComponent positionComponent;
  private SizeComponent sizeComponent;
  
  public BasicGraphicComponent ( PositionComponent positionComponent, SizeComponent sizeComponent, BitmapType type )
  {
    this.positionComponent = positionComponent;
    this.sizeComponent = sizeComponent;
    bitmap = Locator.getBitmapLoader().loadBitmap( type );
  }
  
  @Override
  public void render ( Graphic graphic )
  {
    graphic.drawBitmap( bitmap, positionComponent, sizeComponent );
  }
}
