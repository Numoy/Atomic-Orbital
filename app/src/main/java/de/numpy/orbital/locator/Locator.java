package de.numpy.orbital.locator;

import de.numpy.orbital.android.AndroidInput;
import de.numpy.orbital.constants.Settings;
import de.numpy.orbital.audio.Audio;
import de.numpy.orbital.constants.Statistics;
import de.numpy.orbital.gameservices.GameServiceClient;
import de.numpy.orbital.graphic.BitmapLoader;
import de.numpy.orbital.locator.nullobjects.NullAudio;
import de.numpy.orbital.locator.nullobjects.NullBitmapLoader;
import de.numpy.orbital.locator.nullobjects.NullGameServiceClient;
import de.numpy.orbital.locator.nullobjects.NullSettings;
import de.numpy.orbital.locator.nullobjects.NullStatistics;

/**
 * a service provider
 * Created by Marvin on 14.04.2018.
 */

public class Locator
{
  private static Audio audio;
  private static Audio nullAudio;
  
  private static Settings settings;
  private static Settings nullSettings;
  
  private static Statistics statistics;
  private static Statistics nullStatistics;
  
  private static BitmapLoader bitmapLoader;
  private static BitmapLoader nullBitmapLoader;
  
  private static AndroidInput input;

  private static GameServiceClient gameServiceClient;
  private static GameServiceClient nullGameServiceClient;
  
  static
  {
    nullAudio = new NullAudio();
    nullSettings = new NullSettings();
    nullStatistics = new NullStatistics();
    nullBitmapLoader = new NullBitmapLoader();
    nullGameServiceClient = new NullGameServiceClient();
    
    audio = nullAudio;
    settings = nullSettings;
    statistics = nullStatistics;
    bitmapLoader = nullBitmapLoader;
    gameServiceClient = nullGameServiceClient;
  }
  
  public static void provide ( Audio newAudio )
  {
    audio = newAudio != null ? newAudio : nullAudio;
  }
  
  public static void provide ( Settings newSettings )
  {
    settings = newSettings != null ? newSettings : nullSettings;
  }
  
  public static void provide ( Statistics newStatistics )
  {
    statistics = newStatistics != null ? newStatistics : nullStatistics;
  }
  
  public static void provide ( BitmapLoader newBitmapLoader )
  {
    bitmapLoader = newBitmapLoader != null ? newBitmapLoader : nullBitmapLoader;
  }

  public static void provide( GameServiceClient newGameServiceClient)
  {
    gameServiceClient = newGameServiceClient != null ? newGameServiceClient : nullGameServiceClient;
  }
  
  public static void provide ( AndroidInput newInput )
  {
    input = newInput;
  }
  
  public static Audio getAudio ()
  {
    return audio;
  }
  
  public static Settings getSettings ()
  {
    return settings;
  }
  
  public static Statistics getStatistics ()
  {
    return statistics;
  }
  
  public static BitmapLoader getBitmapLoader()
  {
    return bitmapLoader;
  }
  
  public static AndroidInput getInput()
  {
    return input;
  }

  public static GameServiceClient getGameServiceClient() { return gameServiceClient; }
}
