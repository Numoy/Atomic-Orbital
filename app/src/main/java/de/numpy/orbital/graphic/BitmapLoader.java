package de.numpy.orbital.graphic;

import android.graphics.Bitmap;

/**
 * Created by Marvin on 05.05.2018.
 */

public interface BitmapLoader
{
  public Bitmap loadBitmap( BitmapType type );
  
  public Bitmap loadBitmap( int id );
}
