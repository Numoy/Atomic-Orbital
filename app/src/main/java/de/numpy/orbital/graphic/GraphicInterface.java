package de.numpy.orbital.graphic;

import android.graphics.Bitmap;
import android.graphics.Matrix;

/**
 * Created by Marvin on 22.04.2018.
 */

public interface GraphicInterface
{
  public void drawBitmap ( Bitmap bitmap, Matrix matrix  );
  
  public void drawBitmap ( Bitmap bitmap, Matrix matrix, int alpha );
  
  public void start ();
  
  public void end ();
}
