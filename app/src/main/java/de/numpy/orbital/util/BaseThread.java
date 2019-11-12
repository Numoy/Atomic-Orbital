package de.numpy.orbital.util;

import android.util.Log;

/**
 * Created by Marvin on 27.05.2018.
 */

public abstract class BaseThread implements Runnable
{
  private Object pauseLock; // Den Sinn hab ich noch nicht verstanden
  private boolean done;
  private boolean paused;
  
  public BaseThread()
  {
    pauseLock = new Object();
    paused = false;
    done = false;
  }
  
  @Override
  public void run ()
  {
    while ( !done )
    {
      doStuff();
      synchronized ( pauseLock )
      {
        while ( paused )
        {
          try
          {
            pauseLock.wait();
          }
          catch ( InterruptedException ex )
          {
            Log.i("THREAD", "Besser nochmal Googeln :P");
          }
        }
      }
    }
  }
  
  public void onPause()
  {
    synchronized ( pauseLock )
    {
      paused = true;
    }
  }
  
  public void onResume()
  {
    synchronized ( pauseLock )
    {
      paused = false;
      pauseLock.notifyAll();
    }
  }
  
  public void onStop()
  {
    onResume();
    done = true;
  }
  
  public void onStart()
  {
    done = false;
  }
  
  protected abstract void doStuff();
}
