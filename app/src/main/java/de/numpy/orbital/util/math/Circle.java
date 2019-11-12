package de.numpy.orbital.util.math;

import de.numpy.orbital.util.Vector2D;

public class Circle
{
    public float x;
    public float y;
    public float radius;

    public Circle (float x, float y, float radius) {
        this(new Vector2D(x,y), radius);
    }

    public Circle (Vector2D position, float radius)
    {
        this.x = position.x;
        this.y = position.y;
        this.radius = radius;
    }

    public Circle (Circle circle)
    {
        this.x = circle.x;
        this.y = circle.y;
        this.radius = circle.radius;
    }

    public boolean contains (float x, float y) {
       return this.contains(new Vector2D( x,y ));
    }

    public boolean contains (Vector2D point)
    {
        float dx = x - point.x;
        float dy = y - point.y;
        return dx * dx + dy * dy <= radius * radius;
    }

    public boolean contains (Circle c)
    {
        final float radiusDiff = radius - c.radius;
        if (radiusDiff < 0f) return false; // Can't contain bigger circle
        final float dx = x - c.x;
        final float dy = y - c.y;
        final float dst = dx * dx + dy * dy;
        final float radiusSum = radius + c.radius;
        return (!(radiusDiff * radiusDiff < dst) && (dst < radiusSum * radiusSum));
    }

    public boolean intersects(Circle c)
    {
        float dx = x - c.x;
        float dy = y - c.y;
        float distance = dx * dx + dy * dy;
        float radiusSum = radius + c.radius;
        return distance < radiusSum * radiusSum;
    }

    public float circumference () {
        return this.radius * MathUtils.PI2;
    }

    public float area () {
        return this.radius * this.radius * MathUtils.PI;
    }

    public void setPosition(float x, float y)
    {
        this.x = x;
        this.y = y;
    }
    public float getX()
    {
        return x;
    }

    public void setX(float x)
    {
        this.x = x;
    }

    public float getY()
    {
        return y;
    }

    public void setY(float y)
    {
        this.y = y;
    }

    public float getRadius()
    {
        return radius;
    }

    public void setRadius(float radius)
    {
        this.radius = radius;
    }
}
