package de.numpy.orbital.game.entitiy.components.photon;

import java.util.Random;

import de.numpy.orbital.constants.Constants;
import de.numpy.orbital.game.entitiy.EntityQueue;
import de.numpy.orbital.game.entitiy.EntityFactory;
import de.numpy.orbital.game.entitiy.components.LogicComponent;
import de.numpy.orbital.game.entitiy.components.photon.types.PhotonType;
import de.numpy.orbital.game.entitiy.components.photon.types.SinusType;
import de.numpy.orbital.game.entitiy.components.photon.types.SpiralType;
import de.numpy.orbital.game.entitiy.components.photon.types.StraightType;
import de.numpy.orbital.util.Score;
import de.numpy.orbital.util.math.MathUtils;

/**
 * Created by Marvin on 05.05.2018.
 */

public class PhotonSpawnerLogicComponent implements LogicComponent
{
  private double spawntimer = 0;
  private EntityQueue queue;
  private Score score;
  private Random rnd;
  
  public PhotonSpawnerLogicComponent( EntityQueue queue, Score score )
  {
    this.queue = queue;
    this.score = score;
    rnd = new Random( System.nanoTime() );
  }
  
  
  @Override
  public boolean update ( double dTime )
  {
    spawntimer -= dTime;
    if ( spawntimer <= 0 )
    {
      spawnPhotons();
      spawntimer += Constants.PHOTON_INTERVALL;
    }
    
    return false;
  }
  
  private void spawnPhotons ()
  {
    int count = 1 + score.getScore() / 5;
    int groupCount = 1 + rnd.nextInt( Math.min( 4, count ) );
    int type = rnd.nextInt( 3 );
    int dir = rnd.nextBoolean() ? 1:-1;
    float startPos = MathUtils.PI2 * rnd.nextFloat();
  
    for ( int i = 1; i <= count; i++ )
    {
      queue.add( EntityFactory.createPhoton( startPos, createPhotonType( type, dir ) ) );
      startPos += 360 / groupCount;
      if ( i % groupCount == 0 )
      {
        startPos += 10;
      }
      startPos %= 360;
    }
  }
  
  private PhotonType createPhotonType( int type, int dir )
  {
    //return new SpiralType( dir );
    //return new StraightType();
    return new SinusType();
    /*
    switch ( type )
    {
      case 1:
        return new SpiralType( dir );
      case 2:
        return new SinusType();
      default:
        return new StraightType();
    }
    */
  }
}
