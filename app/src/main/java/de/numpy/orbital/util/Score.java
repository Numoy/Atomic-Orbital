package de.numpy.orbital.util;

/**
 * Created by Marvin on 05.05.2018.
 */

public class Score
{
  private int score = 0;
  
  public void increase()
  {
    score++;
  }
  
  public int getScore()
  {
    return score;
  }
  
  public void reset()
  {
    score = 0;
  }
}
