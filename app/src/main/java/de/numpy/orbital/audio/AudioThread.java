package de.numpy.orbital.audio;

import de.numpy.orbital.orbital4.v1.utility.Disposeable;
import de.numpy.orbital.locator.Locator;
import de.numpy.orbital.orbital4.v1.utility.ThreadBase;
import de.numpy.orbital.util.BaseThread;

/**
 * Created by Marvin on 14.04.2018.
 */

public class AudioThread extends BaseThread
{
  private AudioImpl audio;

  public AudioThread ( AudioPlayer player )
  {
    audio = new AudioImpl( player );
    Locator.provide( audio );
  }
  
  @Override
  protected void doStuff ()
  {
    audio.update();
  }
  
}
