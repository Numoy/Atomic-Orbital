package de.numpy.orbital.util;

import de.numpy.orbital.game.entitiy.components.basic.hitbox.CircleHitboxComponent;
import de.numpy.orbital.game.entitiy.components.basic.hitbox.HitboxComponent;
import de.numpy.orbital.game.entitiy.components.basic.hitbox.RectHitboxComponent;
import de.numpy.orbital.util.math.Circle;
import de.numpy.orbital.util.math.Rectangle;

public final class Intersector
{
    public static boolean intersects(Circle c1, Circle c2)
    {
        return c1.intersects(c2);
    }

    public static boolean intersects(Rectangle r1, Rectangle r2)
    {
        return r1.intersects(r2);
    }

    public static boolean intersects(Circle c, Rectangle r)
    {
        float closestX = c.x;
        float closestY = c.y;

        if (c.x < r.x)
        {
            closestX = r.x;
        } else if (c.x > r.x + r.width)
        {
            closestX = r.x + r.width;
        }

        if (c.y < r.y)
        {
            closestY = r.y;
        } else if (c.y > r.y + r.height)
        {
            closestY = r.y + r.height;
        }

        closestX = closestX - c.x;
        closestX *= closestX;
        closestY = closestY - c.y;
        closestY *= closestY;

        return closestX + closestY < c.radius * c.radius;
    }


}
