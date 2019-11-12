package de.numpy.orbital.game.entitiy;

import de.numpy.orbital.util.RingBuffer;

/**
 * A queue to pass to the entities if they need to be able to create other entities
 * Created by Marvin on 05.05.2018.
 */

public class EntityQueue
{
  private RingBuffer<Entity> queue;
  
  public EntityQueue ( int bufferSize )
  {
    queue = new RingBuffer<>( new Entity[bufferSize] );
  }
  
  public void add( Entity e )
  {
    queue.add( e );
  }
  
  public Entity nextEntity()
  {
    return queue.read();
  }
  
  public boolean isEmpty()
  {
    return queue.isEmpty();
  }
}
