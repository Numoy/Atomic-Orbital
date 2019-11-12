package de.numpy.orbital.locator.nullobjects;

import de.numpy.orbital.constants.Statistics;

/**
 * Null-Object for the Null-Object Pattern
 * Created by Marvin on 15.04.2018.
 */

public class NullStatistics implements Statistics
{
  
  @Override
  public void setHighscore ( int score )
  {
  
  }
  
  @Override
  public int getHighscore ()
  {
    return 0;
  }
  
  @Override
  public void setHardcoreHiscore ( int score )
  {
  
  }
  
  @Override
  public int getHardcoreHighscore ()
  {
    return 0;
  }
  
  @Override
  public void setGamesPlayed ( int count )
  {
  
  }
  
  @Override
  public int getGamesPlayed ()
  {
    return 0;
  }
  
  @Override
  public void setTotalPoints ( int points )
  {
  
  }
  
  @Override
  public int getTotalPoints ()
  {
    return 0;
  }
}
