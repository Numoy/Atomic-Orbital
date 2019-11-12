package de.numpy.orbital.game;

import android.util.Log;

import de.numpy.orbital.graphic.Graphic;
import de.numpy.orbital.util.BaseThread;

/**
 * Thread for the Game logic and render
 *
 * Created by Marvin on 15.04.2018.
 */

public class GameThread extends BaseThread
{
  private Graphic graphic;
  private Game game;
  
  private long lastUpdate;
  
  private static final long NS_PER_FRAME = 1000000000 / 48;
  private static final double S_PER_FRAME = 1.0 / 48;
  
  public GameThread ( Graphic graphic )
  {
    this.graphic = graphic;
    game = new Game();
  }
  
  @Override
  public void run ()
  {
    lastUpdate = System.nanoTime();
    super.run();
  }
  
  protected void doStuff()
  {
    long now = System.nanoTime();
    if ( now - lastUpdate > NS_PER_FRAME )
    {
      update( S_PER_FRAME );
      render();
      lastUpdate = now;
    }
  }
  
  @Override
  public void onPause ()
  {
    super.onPause();
    game.pauseGame();
  }
  
  private void update ( double dTime )
  {
    game.update( dTime );
  }
  
  private void render ()
  {
    graphic.start();
    game.render( graphic );
    graphic.end();
  }
  
}
