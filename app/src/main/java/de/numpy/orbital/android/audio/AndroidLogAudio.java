package de.numpy.orbital.android.audio;

import android.content.Context;
import android.util.Log;

import de.numpy.orbital.audio.AudioPlayer;
import de.numpy.orbital.audio.Sound;

/**
 * Created by Marvin on 15.04.2018.
 */

public class AndroidLogAudio implements AudioPlayer
{
  AndroidAudio audio;

  public AndroidLogAudio ( Context context )
  {
    audio = new AndroidAudio( context );
    Log.i( "AUDIO", "initialised" );
  }

  @Override
  public void startMusic ()
  {
    Log.i( "AUDIO", "start music" );
    audio.startMusic();
  }

  @Override
  public void pauseMusic ()
  {
    Log.i( "AUDIO", "stop music" );
    audio.pauseMusic();
  }

  @Override
  public void playSound ( Sound sound )
  {
    Log.i( "AUDIO", "play sound: " + sound.id );
    audio.playSound( sound );
  }

  @Override
  public void dispose ()
  {
    Log.i( "AUDIO", "dispose" );
    audio.dispose();
  }
}
