package de.numpy.orbital.gameservices.achievements;

/**
 * Created by Marvin on 28.05.2018.
 */

import java.util.List;

/**
 * Response listener for Achievements
 * Call with @{@link LoadAchievementsResponseListenerThread}
 */
public interface LoadAchievementsResponseListener
{
    void onLoadAchievementsResponse(List<Achievement> achievements);
}