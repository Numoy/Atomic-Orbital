package de.numpy.orbital.audio;

/**
 * Data-Structure for Sounds
 * <p>
 * Created by Marvin on 14.04.2018.
 */

public class Sound
{
  public int id;
  public float volume;

  public Sound ( int id, float volume )
  {
    this.id = id;
    this.volume = volume;
  }

  public Sound ( int id )
  {
    this( id, 1f );
  }

  public Sound ()
  {
    this( 0, 0 );
  }
}
