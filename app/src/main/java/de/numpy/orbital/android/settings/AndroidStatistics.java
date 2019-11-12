package de.numpy.orbital.android.settings;

import android.content.Context;

import de.numpy.orbital.orbital4.R;
import de.numpy.orbital.constants.Statistics;

/**
 * Created by Marvin on 15.04.2018.
 */

public class AndroidStatistics extends SharedPreferencesBase implements Statistics
{
  private static final String FILENAME = "statistics";

  public AndroidStatistics ( Context context )
  {
    super( context );
  }

  @Override
  public void setHighscore ( int score )
  {
    savePref( score, context.getString( R.string.highscore ), FILENAME );
  }

  @Override
  public int getHighscore ()
  {
    return getIntPref( context.getString( R.string.highscore ), FILENAME );
  }

  @Override
  public void setHardcoreHiscore ( int score )
  {
    savePref( score, context.getString( R.string.hardcorehighscore ), FILENAME );
  }

  @Override
  public int getHardcoreHighscore ()
  {
    return getIntPref( context.getString( R.string.hardcorehighscore ), FILENAME );
  }

  @Override
  public void setGamesPlayed ( int count )
  {
    savePref( count, context.getString( R.string.games_played ), FILENAME );
  }

  @Override
  public int getGamesPlayed ()
  {
    return getIntPref( context.getString( R.string.games_played ), FILENAME );
  }

  @Override
  public void setTotalPoints ( int points )
  {
    savePref( points, context.getString( R.string.total_points ), FILENAME );
  }

  @Override
  public int getTotalPoints ()
  {
    return getIntPref( context.getString( R.string.total_points ), FILENAME );
  }
}
