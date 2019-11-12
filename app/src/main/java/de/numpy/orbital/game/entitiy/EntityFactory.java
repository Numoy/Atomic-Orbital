package de.numpy.orbital.game.entitiy;

import android.util.Log;

import de.numpy.orbital.constants.Constants;
import de.numpy.orbital.game.entitiy.components.PositionComponent;
import de.numpy.orbital.game.entitiy.components.basic.BasicGraphicComponent;
import de.numpy.orbital.game.entitiy.components.basic.CollisionComponent;
import de.numpy.orbital.game.entitiy.components.basic.SizeComponent;
import de.numpy.orbital.game.entitiy.components.basic.VelocityComponent;
import de.numpy.orbital.game.entitiy.components.basic.hitbox.CircleHitboxComponent;
import de.numpy.orbital.game.entitiy.components.photon.PhotonLogicComponent;
import de.numpy.orbital.game.entitiy.components.photon.PhotonSpawnerLogicComponent;
import de.numpy.orbital.game.entitiy.components.photon.types.PhotonType;
import de.numpy.orbital.game.entitiy.components.player.PlayerLogicComponent;
import de.numpy.orbital.graphic.BitmapType;
import de.numpy.orbital.util.Score;
import de.numpy.orbital.util.Vector2DPolar;
import de.numpy.orbital.util.math.MathUtils;

/**
 * Factory for the different Entity Objects
 *
 * Created by Marvin on 23.04.2018.
 */

public class EntityFactory
{
  private static int id = 1;

  private static synchronized int getNextId()
  {
    return id++;
  }

  public static Entity createAtom ()
  {
    Entity atom = new Entity( getNextId(), EntityType.ATOM );
    SizeComponent size = new SizeComponent( Constants.ATOM_SIZE, Constants.ATOM_SIZE );
    PositionComponent position = new PositionComponent();
    size.setSize( Constants.ATOM_SIZE, Constants.ATOM_SIZE );
    atom.setGraphicComponent( new BasicGraphicComponent( position, size, BitmapType.ATOM ) );
    atom.setSizeComponent( size );
    atom.setPositionComponent( position );
    log( atom );
    return atom;
  }

  public static Entity createEnergy()
  {
    Entity energy = new Entity( getNextId(), EntityType.ENERGY );
    log( energy );
    return energy;
  }

  public static Entity createPhotonSpawner( EntityQueue queue, Score score )
  {
    Entity photonSpawner = new Entity( getNextId() );
    photonSpawner.setLogicComponent( new PhotonSpawnerLogicComponent( queue, score ) );
    log( photonSpawner );
    return photonSpawner;
  }

  public static Entity createPlayer()
  {
    Entity player = new Entity(getNextId(), EntityType.PLAYER );

    SizeComponent size = new SizeComponent(Constants.PLAYER_SIZE,Constants.PLAYER_SIZE);
    PositionComponent position = new PositionComponent();
    Vector2DPolar pos = new Vector2DPolar();
    pos.r = Constants.ATOM_SIZE  * 1.5f;
    pos.phi = MathUtils.PI;
    position.setPosition(pos);

    player.setGraphicComponent(new BasicGraphicComponent(position,size,BitmapType.PLAYER));
    player.setSizeComponent(size);
    player.setPositionComponent(position);

    CircleHitboxComponent hitbox = new CircleHitboxComponent( size, position );
    player.setCollisionComponent(new CollisionComponent(hitbox));
    player.setHitboxComponent(hitbox);

    player.setLogicComponent(new PlayerLogicComponent(player));

    log( player );

    return player;
  }

  public static Entity createPhoton( float startPos, PhotonType photonType )
  {
    Entity photon = new Entity( getNextId(), EntityType.PHOTON );
    SizeComponent size = new SizeComponent( Constants.PHOTON_SIZE, Constants.PHOTON_SIZE );
    size.scale( 0 );
    PositionComponent position = new PositionComponent();
    Vector2DPolar pos = new Vector2DPolar();
    pos.r = Constants.ATOM_SIZE / 2;
    pos.phi = startPos;
    position.setPosition( pos );

    photon.setGraphicComponent( new BasicGraphicComponent( position, size, BitmapType.PHOTON) );
    photon.setSizeComponent( size );
    photon.setPositionComponent( position );

    photon.setLogicComponent( new PhotonLogicComponent( photon, photonType ) );
    photon.setHitboxComponent(new CircleHitboxComponent( size, position ));

    log( photon );
    return photon;
  }

  public static void log( Entity e )
  {
    Log.i("Entity", "Created Entity:" + e.getId() + " of Type:" + e.getType() );
  }
}
