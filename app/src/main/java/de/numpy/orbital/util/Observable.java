package de.numpy.orbital.util;

import de.numpy.orbital.game.event.EventType;

public interface Observable
{
  void addObserver( Observer observer );
  void clearObservers();
  void notifyObservers( EventType type ); //TODO abstract class um Zugriff zu beschränken?
}
