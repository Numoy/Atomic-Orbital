package de.numpy.orbital.android.settings;

import android.content.Context;

import de.numpy.orbital.orbital4.R;
import de.numpy.orbital.constants.Settings;

/**
 * Created by Marvin on 15.04.2018.
 */

public class AndroidSettings extends SharedPreferencesBase implements Settings
{
  private static final String FILENAME = "settings";
  
  public AndroidSettings ( Context context )
  {
    super( context );
  }
  
  @Override
  public void setAudioMuted ( boolean muted )
  {
    savePref( muted, context.getString( R.string.mute ), FILENAME );
  }
  
  @Override
  public boolean isAudioMuted ()
  {
    return getBooleanPref( context.getString( R.string.mute ), FILENAME );
  }
  
  @Override
  public void setGgsActive ( boolean active )
  {
    savePref( active, context.getString( R.string.want_google_game ), FILENAME );
  }
  
  @Override
  public boolean isGgsActive ()
  {
    return getBooleanPref( context.getString( R.string.want_google_game ), FILENAME );
  }
}
