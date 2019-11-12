package de.numpy.orbital.android.settings;

import android.content.Context;
import android.content.SharedPreferences;

import de.numpy.orbital.orbital4.R;

/**
 * Created by Marvin on 15.04.2018.
 */

public class SharedPreferencesBase
{
  protected Context context;

  protected SharedPreferencesBase ( Context context )
  {
    this.context = context;
  }

  protected void savePref ( int prefValue, String prefName, String fileName )
  {
    SharedPreferences preferences = context.getSharedPreferences( fileName, Context.MODE_PRIVATE );
    SharedPreferences.Editor editor = preferences.edit();

    editor.putInt( prefName, prefValue );
    editor.commit();
  }

  protected void savePref ( boolean prefValue, String prefName, String fileName )
  {
    SharedPreferences preferences = context.getSharedPreferences( fileName, Context.MODE_PRIVATE );
    SharedPreferences.Editor editor = preferences.edit();

    editor.putBoolean( prefName, prefValue );
    editor.commit();
  }

  protected int getIntPref ( String prefName, String fileName )
  {
    SharedPreferences preferences = context.getSharedPreferences( fileName, Context.MODE_PRIVATE );
    return preferences.getInt( prefName, 0 );
  }

  protected boolean getBooleanPref ( String prefName, String fileName )
  {
    SharedPreferences preferences = context.getSharedPreferences( fileName, Context.MODE_PRIVATE );
    return preferences.getBoolean( prefName, true );
  }

}
