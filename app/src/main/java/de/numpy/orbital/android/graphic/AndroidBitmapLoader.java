package de.numpy.orbital.android.graphic;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import de.numpy.orbital.orbital4.R;
import de.numpy.orbital.graphic.BitmapLoader;
import de.numpy.orbital.graphic.BitmapType;

public class AndroidBitmapLoader implements BitmapLoader
{
  private Context context;
  private Bitmap[] entityBitmaps;
  //TODO Loaded Skins
  
  public AndroidBitmapLoader( Context context )
  {
    this.context = context;
    entityBitmaps = new Bitmap[5];
    init();
  }
  
  private void init() //TODO Skin
  {
    entityBitmaps[BitmapType.ATOM.ordinal()] = BitmapFactory.decodeResource( context.getResources(), R.drawable.std_atom );
    entityBitmaps[BitmapType.PHOTON.ordinal()] = BitmapFactory.decodeResource( context.getResources(), R.drawable.std_photon );
    entityBitmaps[BitmapType.ENERGY.ordinal()] = BitmapFactory.decodeResource( context.getResources(), R.drawable.std_atom );
    entityBitmaps[BitmapType.PLAYER.ordinal()] = BitmapFactory.decodeResource( context.getResources(), R.drawable.std_atom );
    entityBitmaps[BitmapType.ORBIT.ordinal()] = BitmapFactory.decodeResource( context.getResources(), R.drawable.std_atom );
  }
  
  @Override
  public Bitmap loadBitmap ( BitmapType type )
  {
    return  entityBitmaps[type.ordinal()];
  }
  
  @Override
  public Bitmap loadBitmap ( int id )
  {
    return BitmapFactory.decodeResource( context.getResources(), id );
  }
}
