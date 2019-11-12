package de.numpy.orbital.util;

import de.numpy.orbital.game.event.EventType;

public interface Observer
{
  public void onNotify( Observable source, EventType type );
}
