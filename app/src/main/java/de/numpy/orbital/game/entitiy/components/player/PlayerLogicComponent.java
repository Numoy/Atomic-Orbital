package de.numpy.orbital.game.entitiy.components.player;

import de.numpy.orbital.constants.Display;
import de.numpy.orbital.game.entitiy.Entity;
import de.numpy.orbital.game.entitiy.components.LogicComponent;
import de.numpy.orbital.game.entitiy.components.PositionComponent;
import de.numpy.orbital.game.entitiy.components.basic.SizeComponent;
import de.numpy.orbital.util.Vector2D;

public class PlayerLogicComponent implements LogicComponent
{
    private static final float MIN_RADIUS = Display.WIDTH * 1 / 5;
    private static final float MAX_RADIUS = Display.WIDTH * 0.8f;
    private Vector2D vel;

    private SizeComponent size;
    private PositionComponent pos;

    public PlayerLogicComponent(Entity player)
    {
        size = player.getSizeComponent();
        pos = player.getPositionComponent();
        vel = new Vector2D();
    }


    @Override
    public boolean update(double dTime)
    {
        vel.rotate( pos.getPos().direction() );
        pos.setVelocity( vel );
        pos.applyVelocity( dTime );
        return false;
    }

}
