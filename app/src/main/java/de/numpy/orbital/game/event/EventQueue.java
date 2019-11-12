package de.numpy.orbital.game.event;

import de.numpy.orbital.util.RingBuffer;

public class EventQueue
{
  private RingBuffer<GameEvent> buffer;
  
  public EventQueue()
  {
    buffer = new RingBuffer<>( new GameEvent[16] );
  }
}
