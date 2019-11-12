package de.numpy.orbital.locator.nullobjects;
        
        import android.graphics.Bitmap;
        
        import de.numpy.orbital.graphic.BitmapLoader;
        import de.numpy.orbital.graphic.BitmapType;

/**
 * Null-Object for the Null-Object Pattern
 * Created by Marvin on 05.05.2018.
 */

public class NullBitmapLoader implements BitmapLoader
{
  @Override
  public Bitmap loadBitmap ( BitmapType type )
  {
    return null;
  }
  
  @Override
  public Bitmap loadBitmap ( int id )
  {
    return null;
  }
}
