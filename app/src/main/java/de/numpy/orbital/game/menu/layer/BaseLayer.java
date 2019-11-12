package de.numpy.orbital.game.menu.layer;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import java.util.ArrayList;
import java.util.List;

import de.numpy.orbital.orbital4.R;
import de.numpy.orbital.constants.Display;
import de.numpy.orbital.game.event.EventType;
import de.numpy.orbital.game.menu.components.Button.AnimatedBanner;
import de.numpy.orbital.game.menu.components.Button.Banner;
import de.numpy.orbital.game.menu.components.Button.RoundButton;
import de.numpy.orbital.graphic.BitmapType;
import de.numpy.orbital.locator.Locator;
import de.numpy.orbital.util.Observable;
import de.numpy.orbital.util.Observer;
import de.numpy.orbital.util.Vector2D;

/**
 * TODO Banner weg und durch Text ersetzen
 * TODO Buttongröße abhängig von Display größe
 *
 * Created by Marvin on 27.05.2018.
 */

public class BaseLayer extends MenuLayer
{
  private RoundButton dontStartButton1;
  private RoundButton dontStartButton2;
  private RoundButton dontStartButton3;
  private RoundButton restartButton;
  private Banner tapToStartBanner;
  
  public BaseLayer()
  {
    super();
    initWIPButtons();
    initTapToStartBanner();
    initRestartButton();
  }
  
  private void initRestartButton ()
  {
    Bitmap bitmap = Locator.getBitmapLoader().loadBitmap( R.drawable.btn_r_wip );
    restartButton = new RoundButton( bitmap, 100 );
    restartButton.setPosition( new Vector2D( Display.WIDTH - 150, 300 ) );
    components.add( restartButton );
  }
  
  private void initTapToStartBanner ()
  {
    Bitmap bitmap = Locator.getBitmapLoader().loadBitmap( R.drawable.lbl_tap_to_start );
    float width = Display.WIDTH / 2;
    tapToStartBanner = new AnimatedBanner( bitmap, new Vector2D( width, width / 4 ));
    tapToStartBanner.setCenter( new Vector2D( Display.WIDTH / 2f, Display.HEIGHT * 3 / 4f ) );
    components.add( tapToStartBanner );
  }
  
  private void initWIPButtons ()
  {
    Bitmap bitmap = Locator.getBitmapLoader().loadBitmap( R.drawable.btn_r_wip );
    dontStartButton1 = new RoundButton( bitmap, 100 );
    dontStartButton1.setPosition( new Vector2D( Display.WIDTH / 4, Display.HEIGHT - 250 ) );
    components.add( dontStartButton1 );
  
    dontStartButton2 = new RoundButton( bitmap, 100 );
    dontStartButton2.setPosition( new Vector2D( Display.WIDTH / 2, Display.HEIGHT - 250 ) );
    components.add( dontStartButton2 );
  
    dontStartButton3 = new RoundButton( bitmap, 100 );
    dontStartButton3.setPosition( new Vector2D( Display.WIDTH / 4 * 3, Display.HEIGHT - 250 ) );
    components.add( dontStartButton3 );
  }
  
  @Override
  protected boolean handleComponentInput ( Vector2D touch )
  {
    if ( dontStartButton1.contains( touch ) )
    {
      return false;
    }
    if ( dontStartButton2.contains( touch ) )
    {
      return false;
    }
    if ( dontStartButton3.contains( touch ) )
    {
      return false;
    }
    if ( restartButton.contains( touch ) )
    {
      notifyObservers( EventType.GAME_RESET );
      return false;
    }
    return true;
  }
}
