package de.numpy.orbital.game.entitiy.components.basic.hitbox;

import de.numpy.orbital.constants.Constants;
import de.numpy.orbital.game.entitiy.components.PositionComponent;
import de.numpy.orbital.game.entitiy.components.basic.SizeComponent;
import de.numpy.orbital.graphic.Graphic;
import de.numpy.orbital.util.math.Rectangle;

public class RectHitboxComponent implements HitboxComponent
{
    public Rectangle rectangle;

    protected SizeComponent sizeComponent;
    protected PositionComponent positionComponent;

    public RectHitboxComponent(SizeComponent sizeComponent,PositionComponent positionComponent)
    {
        this.sizeComponent = sizeComponent;
        this.positionComponent = positionComponent;

        rectangle = new Rectangle(positionComponent.getX(), positionComponent.getY(), sizeComponent.getWidth(), sizeComponent.getHeight());
    }

    @Override
    public boolean update(double dTime)
    {
        rectangle.setPosition(positionComponent.getX(), positionComponent.getY());
        return false;
    }
}
