package de.numpy.orbital.android;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.util.Log;

import de.numpy.orbital.android.googleplayservices.GooglePlayGamesClient;
import de.numpy.orbital.android.audio.AndroidLogAudio;
import de.numpy.orbital.android.graphic.AndroidBitmapLoader;
import de.numpy.orbital.android.graphic.AndroidGraphic;
import de.numpy.orbital.android.settings.AndroidSettings;
import de.numpy.orbital.android.settings.AndroidStatistics;
import de.numpy.orbital.audio.AudioPlayer;
import de.numpy.orbital.audio.AudioThread;
import de.numpy.orbital.game.GameThread;
import de.numpy.orbital.graphic.Graphic;
import de.numpy.orbital.locator.Locator;

/**
 * Created by Marvin on 15.04.2018.
 */

public class MainActivity extends Activity
{
  GameThread game;
  Thread gameThread;

  AudioThread audio;
  Thread audioThread;

  GooglePlayGamesClient googlePlayGamesClient;

  @Override
  protected void onCreate ( @Nullable Bundle savedInstanceState )
  {
    super.onCreate( savedInstanceState );
    Log.i("Android", "onCreate" );
    initAudioThread();
    initGooglePlayGamesClient();
    initGameThread();
    initSharedPreferences();
  }
  
  @Override
  protected void onRestart ()
  {
    super.onRestart();
    Log.i("Android", "onCRestart" );
    game.onStart();
    audio.onStart();
  }
  
  @Override
  protected void onResume ()
  {
    super.onResume();
    Log.i("Android", "onResume" );
    game.onResume();
    audio.onResume();
    googlePlayGamesClient.resumeSession();
    
    if ( gameThread == null )
    {
      gameThread = new Thread( game );
      gameThread.start();
    }

    if ( audioThread == null )
    {
      audioThread = new Thread( audio );
      audioThread.start();
    }
  }

  @Override
  protected void onPause ()
  {
    Log.i("Android", "onPause" );
    game.onPause();
    audio.onPause();
    googlePlayGamesClient.pauseSession();
    super.onPause();
  }

  @Override
  protected void onStop ()
  {
    Log.i("Android", "onStop" );
    game.onStop();
    audio.onStop();
    try
    {
      gameThread.join( 10 );
      gameThread = null;
      audioThread.join(10 );
      audioThread = null;
    }
    catch ( InterruptedException ex )
    {
      // R.I.P.
      Log.i("Android", "Failed to join Thread");
    }
    super.onStop();
  }
  
  @Override
  protected void onStart ()
  {
    super.onStart();
    Log.i("Android", "onStart" );
  }
  
  @Override
  protected void onDestroy ()
  {
    Log.i("Android", "onDestroy" );
    super.onDestroy();
  }

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data)
  {
    googlePlayGamesClient.onGooglePlayGamesActivityResult(requestCode, resultCode, data);
    super.onActivityResult(requestCode, resultCode, data);
  }

  private void initAudioThread ()
  {
    //AudioPlayer player = new AndroidAudio( getApplicationContext() );
    AudioPlayer player = new AndroidLogAudio( getApplicationContext() );
    audio = new AudioThread( player );
  }

  private void initGameThread ()
  {
    AndroidGraphic graphicImpl = new AndroidGraphic( getApplicationContext() );
    Graphic graphic = new Graphic( graphicImpl );
    setContentView( graphicImpl );

    AndroidInput input = new AndroidInput();
    graphicImpl.setOnTouchListener( input );
    Locator.provide( input );
    
    Locator.provide( new AndroidBitmapLoader( getApplicationContext() ) );

    game = new GameThread( graphic );
  }

  private void initSharedPreferences ()
  {
    Locator.provide( new AndroidSettings( getApplicationContext() ) );
    Locator.provide( new AndroidStatistics( getApplicationContext() ) );
  }

  private void initGooglePlayGamesClient()
  {
    googlePlayGamesClient = new GooglePlayGamesClient();
    googlePlayGamesClient.initialize(this);
    googlePlayGamesClient.resumeSession();
    Locator.provide(googlePlayGamesClient);
  }

}
