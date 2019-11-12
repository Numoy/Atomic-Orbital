package de.numpy.orbital.game.entitiy.components.basic;

import de.numpy.orbital.game.entitiy.components.basic.hitbox.HitboxComponent;

public interface NullCollisionComponent<T extends HitboxComponent>
{
    boolean checkCollision(T hitboxComponent);
}
