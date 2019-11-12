package de.numpy.orbital.constants;

/**
 * Created by Marvin on 15.04.2018.
 */

public interface Statistics
{
  public void setHighscore ( int score );

  public int getHighscore ();

  public void setHardcoreHiscore ( int score );

  public int getHardcoreHighscore ();

  public void setGamesPlayed ( int count );

  public int getGamesPlayed ();

  public void setTotalPoints ( int points );

  public int getTotalPoints ();
}
