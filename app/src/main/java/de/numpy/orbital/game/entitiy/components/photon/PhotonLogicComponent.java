package de.numpy.orbital.game.entitiy.components.photon;

import java.util.Observable;

import de.numpy.orbital.constants.Constants;
import de.numpy.orbital.game.entitiy.Entity;
import de.numpy.orbital.game.entitiy.components.LogicComponent;
import de.numpy.orbital.game.entitiy.components.PositionComponent;
import de.numpy.orbital.game.entitiy.components.basic.SizeComponent;
import de.numpy.orbital.game.entitiy.components.photon.types.PhotonType;

/**
 * Created by Marvin on 05.05.2018.
 */

public class PhotonLogicComponent extends Observable implements LogicComponent
{
  private float timer;
  private PhotonType type;
  
  private SizeComponent size;
  private PositionComponent pos;
  
  
  public PhotonLogicComponent( Entity photon, PhotonType type )
  {
    timer = Constants.PHOTON_INTERVALL;
    this.type = type;
    size = photon.getSizeComponent();
    pos = photon.getPositionComponent();
    type.init( pos );
  }
  
  
  @Override
  public boolean update ( double dTime )
  {
    if ( timer > 0 )
    {
      updateSpawnPhase( dTime );
    }
    if ( timer <= 0 )
    {
      updatePhysics( dTime );
    }
    
    //Delete if too far out
    return pos.getPos().length() > 200;
  }
  
  private void updateSpawnPhase ( double dTime )
  {
    timer -= dTime;
    size.scale( calcScale() );
  }
  
  private void updatePhysics ( double dTime )
  {
    type.update( dTime );
  }
  
  private float calcScale()
  {
    if ( timer > 0 )
      return 1 - timer / Constants.PHOTON_INTERVALL;
    return 1;
  }
}
