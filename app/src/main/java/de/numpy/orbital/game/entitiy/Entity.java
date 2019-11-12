package de.numpy.orbital.game.entitiy;

import de.numpy.orbital.game.entitiy.components.GraphicComponent;
import de.numpy.orbital.game.entitiy.components.InputComponent;
import de.numpy.orbital.game.entitiy.components.PositionComponent;
import de.numpy.orbital.game.entitiy.components.basic.CollisionComponent;
import de.numpy.orbital.game.entitiy.components.basic.hitbox.HitboxComponent;
import de.numpy.orbital.game.entitiy.components.basic.NullComponent;
import de.numpy.orbital.game.entitiy.components.LogicComponent;
import de.numpy.orbital.game.entitiy.components.basic.SizeComponent;
import de.numpy.orbital.graphic.Graphic;

/**
 * Created by Marvin on 23.04.2018.
 */

public class Entity
{
  public static final NullComponent nullComponent = new NullComponent();
  
  private final int id;
  private EntityType type;
  private boolean delete = false;
  
  /** Components */
  private GraphicComponent graphicComponent = nullComponent;
  private InputComponent inputComponent = nullComponent;
  private LogicComponent logicComponent = nullComponent;
  private PositionComponent positionComponent;
  private SizeComponent sizeComponent;
  private CollisionComponent collisionComponent;
  private HitboxComponent hitboxComponent = nullComponent;
  
  public Entity( int id, EntityType type )
  {
    this.id = id;
    this.type = type;
  }
  
  public Entity( int id )
  {
    this( id, EntityType.MISC );
  }
  
  public void handleInput ()
  {
    inputComponent.handleInput();
  }
  
  public void handleLogic ( double dTime )
  {
    delete = logicComponent.update( dTime );
  }
  
  public void handleAnimation ( double dTime )
  {
  
  }

  public void handleHitbox(double dTime)
  {
    hitboxComponent.update(dTime);
  }
  
  public void render ( Graphic graphic )
  {
    graphicComponent.render( graphic );
  }
  
  public void setGraphicComponent ( GraphicComponent graphicComponent )
  {
    this.graphicComponent = graphicComponent;
  }
  
  public void setInputComponent ( InputComponent inputComponent )
  {
    this.inputComponent = inputComponent;
  }
  
  public void setLogicComponent ( LogicComponent logicComponent )
  {
    this.logicComponent = logicComponent;
  }
  
  public void setPositionComponent ( PositionComponent positionComponent )
  {
    this.positionComponent = positionComponent;
  }
  
  public void setSizeComponent ( SizeComponent sizeComponent )
  {
    this.sizeComponent = sizeComponent;
  }
  
  public static NullComponent getNullComponent ()
  {
    return nullComponent;
  }
  
  public int getId()
  {
    return id;
  }
  public GraphicComponent getGraphicComponent ()
  {
    return graphicComponent;
  }
  
  public InputComponent getInputComponent ()
  {
    return inputComponent;
  }
  
  public LogicComponent getLogicComponent ()
  {
    return logicComponent;
  }
  
  public PositionComponent getPositionComponent ()
  {
    return positionComponent;
  }
  
  public SizeComponent getSizeComponent ()
  {
    return sizeComponent;
  }

  public CollisionComponent getCollisionComponent()
  {
    return collisionComponent;
  }

  public void setCollisionComponent(CollisionComponent collisionComponent)
  {
    this.collisionComponent = collisionComponent;
  }

  public HitboxComponent getHitboxComponent()
  {
    return hitboxComponent;
  }

  public void setHitboxComponent(HitboxComponent hitboxComponent)
  {
    this.hitboxComponent = hitboxComponent;
  }

  public EntityType getType()
  {
    return type;
  }
  
  public boolean isDelete()
  {
    return delete;
  }
}
