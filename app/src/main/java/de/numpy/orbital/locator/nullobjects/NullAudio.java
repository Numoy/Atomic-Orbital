package de.numpy.orbital.locator.nullobjects;

import de.numpy.orbital.audio.Audio;
import de.numpy.orbital.audio.Sound;

/**
 * Null-Object for the Null-Object Pattern
 * Created by Marvin on 14.04.2018.
 */

public class NullAudio implements Audio
{
  
  @Override
  public void muteAll ()
  {
  
  }
  
  @Override
  public void unmuteAll ()
  {
  
  }
  
  @Override
  public void playSound ( Sound sound )
  {
  
  }
  
  @Override
  public void startMusic ()
  {
  
  }
  
  @Override
  public void stopMusio ()
  {
  
  }
}
