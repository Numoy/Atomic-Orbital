package de.numpy.orbital.gameservices;

/**
 * Created by Marvin on 28.05.2018.
 */

/**
 * implementations: all calls are made on UI main render thread
 * when using this wrapper
 */

public class GameServiceListenerThread implements GameServiceListener {

    GameServiceListener serviceListener;

    public GameServiceListenerThread(GameServiceListener listener) {
        serviceListener = listener;
    }

    @Override
    public void gameServiceOnSessionActive() {
        new Runnable() {
            @Override
            public void run() {
                serviceListener.gameServiceOnSessionActive();
            }
        };
    }

    @Override
    public void gameServiceOnSessionInactive() {
        new Runnable() {
            @Override
            public void run() {
                serviceListener.gameServiceOnSessionInactive();
            }
        };
    }

    @Override
    public void gameServiceShowErrorToUser(final GameServiceErrorType errorTypet, final String msg, final Throwable t) {
       new Runnable() {
            @Override
            public void run() {
                serviceListener.gameServiceShowErrorToUser(errorTypet, msg, t);
            }
        };
    }
}