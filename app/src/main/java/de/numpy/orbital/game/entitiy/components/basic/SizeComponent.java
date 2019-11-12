package de.numpy.orbital.game.entitiy.components.basic;

/**
 * Created by Marvin on 05.05.2018.
 */

public class SizeComponent
{
  private float width;
  private float height;
  private float scale;
  
  public SizeComponent ( float width, float height )
  {
    this.width = width;
    this.height = height;
    scale = 1;
  }
  
  public void setSize ( float width, float height )
  {
    this.width = width;
    this.height = height;
  }
  
  /**
   * Scale the size, preserves the original size, can be easily undone
   * @param fac
   */
  public void scale( float fac )
  {
    scale = fac;
  }
  
  /**
   * Applies the current scale factor and resets it to 1, can't be easily undone
   */
  public void applyScale()
  {
    width *= scale;
    height *= scale;
    scale = 1;
  }
  
  public float getWidth ()
  {
    return width * scale;
  }
  
  public float getHeight ()
  {
    return height * scale;
  }
  
  public float getScale()
  {
    return scale;
  }
}