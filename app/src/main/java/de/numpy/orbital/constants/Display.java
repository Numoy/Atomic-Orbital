package de.numpy.orbital.constants;

import android.content.res.Resources;
import android.util.DisplayMetrics;

/**
 * Created by Marvin on 12.04.2018.
 */

public class Display
{
  public static final int WIDTH;
  public static final int HEIGHT;
  
  static
  {
    DisplayMetrics dm = Resources.getSystem().getDisplayMetrics();
    WIDTH = dm.widthPixels;
    HEIGHT = dm.heightPixels;
  }
}
