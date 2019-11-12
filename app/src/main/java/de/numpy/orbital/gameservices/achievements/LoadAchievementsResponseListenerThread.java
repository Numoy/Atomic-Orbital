package de.numpy.orbital.gameservices.achievements;

/**
 * Created by Marvin on 28.05.2018.
 */

import java.util.List;

/**
 * wrapper if response calls are only needed on render thread
 */

public class LoadAchievementsResponseListenerThread implements LoadAchievementsResponseListener
{

    private LoadAchievementsResponseListener responseListener;

    public LoadAchievementsResponseListenerThread(LoadAchievementsResponseListener listener)
    {
        responseListener = listener;
    }

    @Override
    public void onLoadAchievementsResponse(final List<Achievement> achievements)
    {
        new Runnable()
        {
            @Override
            public void run()
            {
                responseListener.onLoadAchievementsResponse(achievements);
            }
        };
    }

}
