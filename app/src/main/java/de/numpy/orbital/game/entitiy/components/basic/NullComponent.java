package de.numpy.orbital.game.entitiy.components.basic;

import de.numpy.orbital.game.entitiy.components.GraphicComponent;
import de.numpy.orbital.game.entitiy.components.InputComponent;
import de.numpy.orbital.game.entitiy.components.LogicComponent;
import de.numpy.orbital.game.entitiy.components.basic.hitbox.HitboxComponent;
import de.numpy.orbital.graphic.Graphic;

/**
 * Created by Marvin on 23.04.2018.
 */

public class NullComponent implements GraphicComponent, InputComponent, LogicComponent, HitboxComponent, NullCollisionComponent
{
  @Override
  public void handleInput ()
  {
  
  }
  
  @Override
  public boolean update ( double dTime )
  {
    return false;
  }
  
  @Override
  public void render ( Graphic graphic )
  {
  
  }

  @Override
  public boolean checkCollision(HitboxComponent hitboxComponent)
  {
    return false;
  }
}
