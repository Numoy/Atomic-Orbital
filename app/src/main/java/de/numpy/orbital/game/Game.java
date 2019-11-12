package de.numpy.orbital.game;

import android.util.Log;
import android.util.SparseArray;

import java.util.ArrayList;
import java.util.List;

import de.numpy.orbital.game.entitiy.Entity;
import de.numpy.orbital.game.entitiy.EntityFactory;
import de.numpy.orbital.game.entitiy.EntityQueue;
import de.numpy.orbital.game.entitiy.components.basic.CollisionComponent;
import de.numpy.orbital.game.entitiy.components.basic.hitbox.HitboxComponent;
import de.numpy.orbital.game.event.EventType;
import de.numpy.orbital.game.menu.Menu;
import de.numpy.orbital.graphic.Graphic;
import de.numpy.orbital.util.Observable;
import de.numpy.orbital.util.Observer;
import de.numpy.orbital.util.Score;

/**
 * Created by Marvin on 15.04.2018.
 */

public class Game implements Observer
{
    private SparseArray<Entity> entities;
    private Menu menu;
    private Score score;
    private EntityQueue queue;
    private List<Integer> deleteQueue;

    Game()
    {
        menu = new Menu();
        menu.observeAll(this);
        queue = new EntityQueue(16);
        score = new Score();
        deleteQueue = new ArrayList<>();
        initEntities();
    }

    private void initEntities()
    {
        entities = new SparseArray<>();
        addEntity(EntityFactory.createAtom());
        addEntity(EntityFactory.createPhotonSpawner(queue, score));
        addEntity(EntityFactory.createPlayer());
    }

    private void addEntity(Entity e)
    {
        entities.put(e.getId(), e);
    }

    public void update(double dTime)
    {
        handleInput();
        handleLogic(dTime);
        handleCollision();
        deleteEntities();
        addNewEntities();
    }

    private void deleteEntities()
    {
        for (Integer i : deleteQueue)
        {
            entities.remove(i);
        }
        deleteQueue.clear();
    }

    private void addNewEntities()
    {
        while (!queue.isEmpty())
        {
            addEntity(queue.nextEntity());
        }
    }

    void render(Graphic graphic)
    {
        for (int i = 0; i < entities.size(); i++)
        {
            entities.valueAt(i).render(graphic);
        }
        menu.render(graphic);
    }

    private void handleInput()
    {
        if (menu.isActive())
            return;
        for (int i = 0; i < entities.size(); i++)
            entities.valueAt(i).handleInput();
    }

    private void handleLogic(double dTime)
    {
        for (int i = 0; i < entities.size(); i++)
        {
            Entity e = entities.valueAt(i);
            if (!menu.isActive())
                updateEntityLogic(dTime, e);
            e.handleAnimation(dTime);
        }
        menu.handleAnimation(dTime);
    }

    //TODO: Besser machen
    private void handleCollision()
    {
        for (int i = 0; i < entities.size(); i++)
        {
            for (int j = 0; j < entities.size(); j++)
            {
                if (i != j)
                {
                    CollisionComponent collisionComponent = entities.valueAt(i).getCollisionComponent();
                    HitboxComponent hitbox = entities.valueAt(j).getHitboxComponent();
                    if (collisionComponent != null && hitbox != null)
                    {
                        if (collisionComponent.checkCollision(hitbox))
                        {
                            //Fire Hit Event

                            Log.i("GAME", "Collision");
                        }
                    }
                }
            }
        }
    }

    private void updateEntityLogic(double dTime, Entity e)
    {
        e.handleLogic(dTime);
        e.handleHitbox(dTime);
        if (e.isDelete())
            deleteQueue.add(e.getId());
    }

    public void pauseGame()
    {
        menu.openMenu();
    }

    public void resetGame()
    {
        score.reset();
        initEntities();
    }

    @Override
    public void onNotify(Observable source, EventType type)
    {
        if (type == EventType.GAME_RESET)
            resetGame();
    }
}
