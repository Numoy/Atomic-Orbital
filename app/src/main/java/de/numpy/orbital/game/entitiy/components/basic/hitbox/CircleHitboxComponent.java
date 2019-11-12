package de.numpy.orbital.game.entitiy.components.basic.hitbox;

import de.numpy.orbital.game.entitiy.components.PositionComponent;
import de.numpy.orbital.game.entitiy.components.basic.SizeComponent;
import de.numpy.orbital.util.math.Circle;

public class CircleHitboxComponent implements HitboxComponent
{
    public Circle circle;

    protected SizeComponent sizeComponent;
    protected PositionComponent positionComponent;

    public CircleHitboxComponent(SizeComponent sizeComponent,PositionComponent positionComponent)
    {
        this.sizeComponent = sizeComponent;
        this.positionComponent = positionComponent;

        circle = new Circle(positionComponent.getX(), positionComponent.getY(), sizeComponent.getWidth());
    }

    @Override
    public boolean update(double dTime)
    {
        circle.setPosition(positionComponent.getX(), positionComponent.getY());
        return false;
    }
}
