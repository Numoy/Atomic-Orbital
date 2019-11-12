package de.numpy.orbital.game.entitiy.components.orbit;

import de.numpy.orbital.game.entitiy.components.LogicComponent;

public class OrbitLogicComponent implements LogicComponent
{
  private int orbit;
  private static int orbitCount = 0;
  
  public OrbitLogicComponent()
  {
    orbit = orbitCount;
    orbitCount++;
  }
  
  @Override
  public boolean update ( double dTime )
  {
    return false;
  }
}
