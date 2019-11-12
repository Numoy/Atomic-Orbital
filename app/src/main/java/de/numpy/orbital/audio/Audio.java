package de.numpy.orbital.audio;

/**
 * Created by Marvin on 14.04.2018.
 */

public interface Audio
{
  public void muteAll ();

  public void unmuteAll ();

  public void playSound ( Sound sound );

  public void startMusic ();

  public void stopMusio ();
}
