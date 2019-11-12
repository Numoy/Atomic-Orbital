package de.numpy.orbital.game.menu.layer;

import android.graphics.Bitmap;

import de.numpy.orbital.orbital4.R;
import de.numpy.orbital.constants.Display;
import de.numpy.orbital.game.menu.components.Button.RoundButton;
import de.numpy.orbital.graphic.BitmapType;
import de.numpy.orbital.locator.Locator;
import de.numpy.orbital.util.Vector2D;

/**
 * Created by Marvin on 27.05.2018.
 */

public class UiLayer extends MenuLayer
{
  private RoundButton pauseButton;
  
  public UiLayer()
  {
    super();
    
    initPauseButton();
  }
  
  private void initPauseButton ()
  {
    Bitmap bitmap = Locator.getBitmapLoader().loadBitmap( R.drawable.btn_r_pause );
    pauseButton = new RoundButton( bitmap, 75 );
    pauseButton.setPosition( new Vector2D( Display.WIDTH - 150, 150 ) );
    components.add( pauseButton );
  }
  
  @Override
  protected boolean handleComponentInput ( Vector2D touch )
  {
    if ( pauseButton.contains( touch ) )
    {
      return true;
    }
    return false;
  }
}
