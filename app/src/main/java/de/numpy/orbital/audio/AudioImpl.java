package de.numpy.orbital.audio;

/**
 * Created by Marvin on 14.04.2018.
 */

public class AudioImpl implements Audio
{
  private final int MAX_PENDING = 10;
  private AudioPlayer player;
  private Sound[] pending;
  private MusicState musicState = MusicState.NOTHING;

  private int head = 0;
  private int tail = 0;

  AudioImpl ( AudioPlayer player )
  {
    this.player = player;
    pending = new Sound[ MAX_PENDING ];
  }

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
    assert !isQueueFull();

    int duplicate = findDuplicates( sound );
    if ( duplicate != -1 )
    {
      replaceSound( duplicate, sound );
    }
    else
    {
      appendSound( sound );
    }
  }

  @Override
  public void startMusic ()
  {
    musicState = MusicState.TURN_ON;
  }

  @Override
  public void stopMusio ()
  {
    musicState = MusicState.TURN_OFF;
  }

  private void appendSound ( Sound sound )
  {
    pending[ tail ] = sound;
    tail = nextPos( tail );
  }

  private void replaceSound ( int i, Sound sound )
  {
    pending[ i ].volume = Math.max( pending[ i ].volume, sound.volume );
  }

  private boolean isQueueFull ()
  {
    return nextPos( tail ) != head;
  }

  private int nextPos ( int pos )
  {
    return ( pos + 1 ) % MAX_PENDING;
  }

  private int findDuplicates ( Sound sound )
  {
    for ( int i = head; i != tail; i = nextPos( i ) )
    {
      if ( pending[ i ].id == sound.id )
      {
        return i;
      }
    }
    return -1;
  }

  void update ()
  {
    updateMusic();
    updateSounds();
  }

  private void updateMusic ()
  {
    switch ( musicState )
    {
      case TURN_ON:
        player.startMusic();
        musicState = MusicState.NOTHING;
        break;
      case TURN_OFF:
        player.pauseMusic();
        musicState = MusicState.NOTHING;
        break;
    }
  }

  private void updateSounds ()
  {
    if ( head == tail )
    {
      return;
    }
    player.playSound( pending[ head ] );
    head = nextPos( head );
  }

  void dispose ()
  {
    player.dispose();
  }
}
