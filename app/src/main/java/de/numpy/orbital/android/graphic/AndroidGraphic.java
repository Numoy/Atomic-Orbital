package de.numpy.orbital.android.graphic;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import de.numpy.orbital.constants.Constants;
import de.numpy.orbital.graphic.GraphicInterface;

/**
 * Created by Marvin on 22.04.2018.
 */

public class AndroidGraphic extends SurfaceView implements GraphicInterface
{
  private Canvas canvas;
  private SurfaceHolder holder;
  private Paint transparancy;

  boolean drawing = false;

  public AndroidGraphic ( Context context )
  {
    super( context );
    holder = getHolder();
    transparancy = new Paint();
  }

  @Override
  public void drawBitmap ( Bitmap bitmap, Matrix matrix, int alpha )
  {
    if ( drawing )
    {
      transparancy.setAlpha( alpha );
      canvas.drawBitmap( bitmap, matrix, transparancy );
    }
  }
  
  @Override
  public void drawBitmap ( Bitmap bitmap, Matrix matrix )
  {
    if ( drawing )
      canvas.drawBitmap( bitmap, matrix, null );
  }
  
  @Override
  public void start ()
  {
    if ( drawing )
    {
      return;
    }

    if ( holder.getSurface().isValid() )
    {
      canvas = holder.lockCanvas();
      drawing = true;
      canvas.drawColor( Constants.BACKGROUND_COLOR );
    }
  }

  @Override
  public void end ()
  {
    if ( !drawing )
    {
      return;
    }

    holder.unlockCanvasAndPost( canvas );
    canvas = null;
    drawing = false;
  }
}
