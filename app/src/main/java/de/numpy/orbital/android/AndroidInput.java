package de.numpy.orbital.android;

import android.view.MotionEvent;
import android.view.View;

import java.util.ArrayList;
import java.util.List;

import de.numpy.orbital.constants.InputListener;

public class AndroidInput implements View.OnTouchListener
{
  private boolean touchDown;
  
  private List<InputListener> listeners;
  
  public AndroidInput()
  {
    listeners = new ArrayList<>();
  }
  
  @Override
  public boolean onTouch ( View view, MotionEvent motionEvent )
  {
    if ( motionEvent.getAction() == MotionEvent.ACTION_DOWN )
    {
      touchDown = true;
    }
    if ( motionEvent.getAction() == MotionEvent.ACTION_UP )
    {
      touchDown = false;
    }
  
    for ( InputListener listener : listeners )
    {
      listener.onTouch( motionEvent );
    }
    return false;
  }
  
  public void addListener( InputListener listener )
  {
    listeners.add( listener );
  }
}
