package de.numpy.orbital.util;

/**
 * Created by Marvin on 05.05.2018.
 */

public class RingBuffer<T>
{
  private final int SIZE;
  private T[] buffer;
  
  private int head = 0;
  private int tail = 0;
  
  public RingBuffer( T[] buffer )
  {
    SIZE = buffer.length;
    this.buffer = buffer;
  }
  
  public void add( T o )
  {
    if ( isQueueFull() )
    {
      return;
    }
    buffer[ tail ] = o;
    tail = nextPos( tail );
  }
  
  public T read()
  {
    if ( isEmpty() )
    {
      return null;
    }
    
    T tmp = buffer[head];
    head = nextPos( head );
    return tmp;
  }
  
  public boolean isEmpty()
  {
    return head == tail;
  }
  
  private boolean isQueueFull ()
  {
    return nextPos( tail ) == head;
  }
  private int nextPos ( int pos )
  {
    return ( pos + 1 ) % SIZE;
  }
  
}
