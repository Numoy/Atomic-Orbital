package de.numpy.orbital.game.menu.layer;

import java.util.ArrayList;
import java.util.List;

import de.numpy.orbital.game.event.EventType;
import de.numpy.orbital.game.menu.components.MenuComponent;
import de.numpy.orbital.graphic.Graphic;
import de.numpy.orbital.util.Observable;
import de.numpy.orbital.util.Observer;
import de.numpy.orbital.util.Vector2D;

public abstract class MenuLayer implements Observable
{
  protected List<MenuComponent> components;
  private List<Observer> observers;
  protected MenuLayer nextLayer;
  
  public MenuLayer()
  {
    components = new ArrayList<>();
    observers = new ArrayList<>();
  }
  
  public boolean handleInput( Vector2D touch )
  {
    if ( nextLayer != null && nextLayer.handleInput( touch ) )
    {
      nextLayer = null;
      return false;
    }
    return handleComponentInput( touch );
  }
  
  protected abstract boolean handleComponentInput( Vector2D touch );
  
  public void render( Graphic graphic )
  {
    for ( MenuComponent c : components )
    {
      c.render( graphic );
    }
    if ( nextLayer != null )
    {
      nextLayer.render( graphic );
    }
  }
  
  public void handleAnimation( double dt )
  {
    for ( MenuComponent c : components )
    {
      c.handleAnimation( dt );
    }
    if ( nextLayer != null )
    {
      nextLayer.handleAnimation( dt );
    }
  }
  
  @Override
  public void addObserver ( Observer observer )
  {
    observers.add( observer );
  }
  
  @Override
  public void clearObservers ()
  {
    observers.clear();
  }
  
  @Override
  public void notifyObservers ( EventType type )
  {
    for( Observer o : observers )
      o.onNotify( this, type );
  }
}
