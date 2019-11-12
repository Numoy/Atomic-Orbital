package de.numpy.orbital.locator.nullobjects;

import de.numpy.orbital.constants.Settings;

/**
 * Null-Object for the Null-Object Pattern
 * Created by Marvin on 15.04.2018.
 */

public class NullSettings implements Settings
{
  
  @Override
  public void setAudioMuted ( boolean muted )
  {
  
  }
  
  @Override
  public boolean isAudioMuted ()
  {
    return false;
  }
  
  @Override
  public void setGgsActive ( boolean active )
  {
  
  }
  
  @Override
  public boolean isGgsActive ()
  {
    return false;
  }
}
