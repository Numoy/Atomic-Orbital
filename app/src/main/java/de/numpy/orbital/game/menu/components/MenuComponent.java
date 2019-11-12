package de.numpy.orbital.game.menu.components;

import de.numpy.orbital.graphic.Graphic;

public interface MenuComponent
{
  void render( Graphic graphic );
  
  void handleAnimation( double dt );
}
