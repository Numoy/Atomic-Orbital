package de.numpy.orbital.gameservices;

import de.numpy.orbital.gameservices.achievements.LoadAchievementsResponseListener;
import de.numpy.orbital.gameservices.leaderboard.LeaderBoardEntriesResponseListener;

/**
 * Created by Marvin on 28.05.2018.
 */

public interface GameServiceClient
{
    String GS_GOOGLEPLAYGAMES_ID = "GPGS";

    String getGameServiceId();

    /**
     * Listener für Callbacks des game service clients
     */
    void setListener(GameServiceListener gsListener);

    boolean resumeSession();

    boolean logIn();

    void pauseSession();

    void logOut();

    String getPlayerDisplayName();

    boolean isSessionActive();

    boolean isConnectionPending();

    void showLeaderboards(String leaderBoardId) throws GameServiceException;

    void showAchievements() throws GameServiceException;

    boolean loadAchievements(final LoadAchievementsResponseListener callback);

    boolean submitToLeaderboard(String leaderboardId, long score);

    boolean loadLeaderboardEntries(String leaderBoardId, int limit, boolean relatedToPlayer,
                                   LeaderBoardEntriesResponseListener callback);

    boolean unlockAchievement(String achievementId);

    boolean incrementAchievement(String achievementId, int incNum, float completionPercentage);

}

