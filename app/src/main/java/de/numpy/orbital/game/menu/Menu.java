package de.numpy.orbital.game.menu;

import android.util.Log;
import android.view.MotionEvent;

import de.numpy.orbital.constants.InputListener;
import de.numpy.orbital.game.menu.layer.BaseLayer;
import de.numpy.orbital.game.menu.layer.MenuLayer;
import de.numpy.orbital.game.menu.layer.UiLayer;
import de.numpy.orbital.graphic.Graphic;
import de.numpy.orbital.locator.Locator;
import de.numpy.orbital.util.Observer;
import de.numpy.orbital.util.Vector2D;

/**
 * Created by Marvin on 15.04.2018.
 */

public class Menu implements InputListener
{
  /** true: Menü aktiv, false: GameUi aktiv */
  private boolean active;
  
  private BaseLayer baseLayer;
  private UiLayer uiLayer;
  
  public Menu()
  {
    baseLayer = new BaseLayer();
    uiLayer = new UiLayer();
    
    active = true;
    
    Locator.getInput().addListener( this );
  }
  
  private void handleInput ( Vector2D touch )
  {
    if ( active && baseLayer.handleInput( touch ) )
    {
      active = false;
      return;
    }
    if ( !active && uiLayer.handleInput( touch ) )
    {
      active = true;
    }
  }
  
  public void handleAnimation( double dTime )
  {
    if ( active )
      baseLayer.handleAnimation( dTime );
    else
      uiLayer.handleAnimation( dTime );
  }
  
  public void render ( Graphic graphic )
  {
    if ( active )
      baseLayer.render( graphic );
    else
      uiLayer.render( graphic );
  }
  
  public boolean isActive()
  {
    return active;
  }
  
  @Override
  public void onTouch ( MotionEvent event )
  {
    Vector2D touch = new Vector2D( event.getX(), event.getY() );
    handleInput( touch );
  }
  
  public void openMenu()
  {
    active = true;
  }
  
  public void observeAll( Observer o )
  {
    baseLayer.addObserver( o );
  }
}
