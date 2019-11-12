package de.numpy.orbital.game.entitiy.components.basic;

import de.numpy.orbital.game.entitiy.Entity;
import de.numpy.orbital.game.entitiy.components.basic.hitbox.CircleHitboxComponent;
import de.numpy.orbital.game.entitiy.components.basic.hitbox.HitboxComponent;
import de.numpy.orbital.game.entitiy.components.basic.hitbox.RectHitboxComponent;
import de.numpy.orbital.util.Intersector;

import static de.numpy.orbital.util.Intersector.intersects;

public class CollisionComponent implements NullCollisionComponent
{
    private HitboxComponent hitbox;

    public CollisionComponent(HitboxComponent hitbox)
    {
        this.hitbox = hitbox;
    }

    //TODO: Nicht hinschauen - Evil Shit
    public boolean checkCollision(HitboxComponent otherHitboxComponent)
    {
        if (hitbox instanceof CircleHitboxComponent)
        {
            if (otherHitboxComponent instanceof CircleHitboxComponent)
            {
                return intersects(((CircleHitboxComponent) hitbox).circle,((CircleHitboxComponent) otherHitboxComponent).circle);
            }
            else if(otherHitboxComponent instanceof RectHitboxComponent)
            {
                return intersects(((CircleHitboxComponent) hitbox).circle, ((RectHitboxComponent) otherHitboxComponent).rectangle);
            }
        }
        if (hitbox instanceof RectHitboxComponent)
        {
            if (otherHitboxComponent instanceof RectHitboxComponent)
            {
                return intersects(((RectHitboxComponent) hitbox).rectangle, ((RectHitboxComponent) otherHitboxComponent).rectangle);
            }
            else if(otherHitboxComponent instanceof CircleHitboxComponent)
            {
                return intersects(((CircleHitboxComponent) otherHitboxComponent).circle, ((RectHitboxComponent) hitbox).rectangle);
            }
        }
        return false;
    }

    public HitboxComponent getHitboxComponent()
    {
        return hitbox;
    }

    public void setHitboxComponent(HitboxComponent hitbox)
    {
        this.hitbox = hitbox;
    }
}
