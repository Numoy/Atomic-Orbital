package de.numpy.orbital.audio;

/**
 * Created by Marvin on 14.04.2018.
 */

public interface AudioPlayer
{
  public void startMusic ();

  public void pauseMusic ();

  public void playSound ( Sound sound );

  public void dispose ();
}
