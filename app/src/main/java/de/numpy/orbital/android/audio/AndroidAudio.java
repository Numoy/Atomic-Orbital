package de.numpy.orbital.android.audio;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.MediaPlayer;
import android.media.SoundPool;

import java.util.HashMap;

import de.numpy.orbital.orbital4.R;
import de.numpy.orbital.audio.AudioPlayer;
import de.numpy.orbital.audio.Sound;

/**
 * Created by Marvin on 14.04.2018.
 */

public class AndroidAudio implements AudioPlayer
{
  private static final int MAX_STREAMS = 5;
  private static final float DEFAULT_VOLUME = 1f;

  private SoundPool sounds;
  private MediaPlayer music;

  private HashMap<Integer, Integer> loadedSoundEffects;

  private Context context;

  public AndroidAudio ( Context context )
  {
    this.context = context;
    sounds = createSoundPool();
    music = createMediaPlayer();
    loadedSoundEffects = new HashMap<>();
  }

  private MediaPlayer createMediaPlayer ()
  {
    MediaPlayer player = MediaPlayer.create( context, R.raw.bg_music );
    player.setLooping( true );
    player.setVolume( DEFAULT_VOLUME, DEFAULT_VOLUME );
    return player;
  }

  private SoundPool createSoundPool ()
  {
    SoundPool.Builder builder = new SoundPool.Builder();
    builder.setAudioAttributes( createAudioAttributes() );
    builder.setMaxStreams( MAX_STREAMS );
    return builder.build();
  }

  private AudioAttributes createAudioAttributes ()
  {
    AudioAttributes.Builder builder = new AudioAttributes.Builder();
    builder.setUsage( AudioAttributes.USAGE_GAME );
    builder.setContentType( AudioAttributes.CONTENT_TYPE_SONIFICATION );
    return builder.build();
  }


  @Override
  public void startMusic ()
  {
    music.start();
  }

  @Override
  public void pauseMusic ()
  {
    music.pause();
  }

  @Override
  public void playSound ( Sound sound )
  {
    int id = loadSound( sound );
    sounds.play( id, sound.volume, sound.volume, 0, 0, 1f );
  }

  @Override
  public void dispose ()
  {
    music.release();
    music = null;

    sounds.release();
    sounds = null;
  }

  private int loadSound ( Sound sound )
  {
    Integer key = Integer.valueOf( sound.id );
    if ( loadedSoundEffects.containsKey( key ) )
    {
      return loadedSoundEffects.get( key ).intValue();
    }
    Integer value = sounds.load( context, sound.id, 1 );
    loadedSoundEffects.put( key, value );
    return value.intValue();
  }

}
