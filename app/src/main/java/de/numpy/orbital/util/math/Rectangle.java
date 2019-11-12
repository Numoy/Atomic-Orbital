package de.numpy.orbital.util.math;

import de.numpy.orbital.util.Vector2D;

public class Rectangle
{
    public float x;
    public float y;
    public float height;
    public float width;

    public Rectangle(float x, float y, float width, float height)
    {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }

    public Rectangle(Rectangle rect)
    {
        this.x = rect.x;
        this.y = rect.y;
        this.width = rect.width;
        this.height = rect.height;
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

    public float getHeight()
    {
        return height;
    }

    public void setHeight(float height)
    {
        this.height = height;
    }

    public float getWidth()
    {
        return width;
    }

    public void setWidth(float width)
    {
        this.width = width;
    }

    public Vector2D getPosition()
    {
        return new Vector2D(x,y);
    }

    public boolean contains (float x, float y) {
        return this.x <= x && this.x + this.width >= x && this.y <= y && this.y + this.height >= y;
    }

    public boolean contains (Vector2D point) {
        return this.contains(point.x, point.y);
    }

    public boolean contains (Circle circle) {
        return (circle.getX() - circle.getRadius() >= x) && (circle.getX() + circle.getRadius() <= x + width)
                && (circle.getY() - circle.getRadius() >= y) && (circle.getY() + circle.getRadius() <= y + height);
    }

    public boolean contains (Rectangle rectangle) {
        float xMin = rectangle.x;
        float xMax = xMin + rectangle.width;

        float yMin = rectangle.y;
        float yMax = yMin + rectangle.height;

        return ((xMin > x && xMin < x + width) && (xMax > x && xMax < x + width))
                && ((yMin > y && yMin < y + height) && (yMax > y && yMax < y + height));
    }

    public boolean intersects(Rectangle r) {
        return x < r.x + r.width && x + width > r.x && y < r.y + r.height && y + height > r.y;
    }

    public float getAspectRatio () {
        return (height == 0) ? Float.NaN : width / height;
    }

    public float area () {
        return this.width * this.height;
    }
}
