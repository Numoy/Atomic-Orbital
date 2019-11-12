package de.numpy.orbital.locator.nullobjects;

/**
 * Created by Marvin on 28.05.2018.
 */

import android.util.Log;

import de.numpy.orbital.gameservices.GameServiceClient;
import de.numpy.orbital.gameservices.GameServiceException;
import de.numpy.orbital.gameservices.GameServiceListener;
import de.numpy.orbital.gameservices.achievements.LoadAchievementsResponseListener;
import de.numpy.orbital.gameservices.leaderboard.LeaderBoardEntriesResponseListener;

public class NullGameServiceClient implements GameServiceClient
{

    public static final String GAMESERVICE_ID = "GS_NULLOBJECT";

    protected GameServiceListener gsListener;

    protected boolean connected;

    @Override
    public String getGameServiceId() {
        return GAMESERVICE_ID;
    }

    @Override
    public void setListener(GameServiceListener gsListener) {
        this.gsListener = gsListener;
    }

    @Override
    public boolean resumeSession() {
        return connect(true);
    }

    @Override
    public boolean logIn() {
        return connect(false);
    }

    public boolean connect(boolean silent) {
        Log.i(GAMESERVICE_ID, "Connect called, silent: " + silent );

        if (connected)
            return true;

        connected = true;

        if (gsListener != null)
            gsListener.gameServiceOnSessionActive();

        return true;
    }

    @Override
    public void pauseSession() {
        Log.i(GAMESERVICE_ID, "Disconnect called.");
        connected = false;

        if (gsListener != null)
            gsListener.gameServiceOnSessionInactive();
    }

    @Override
    public void logOut() {
        Log.i(GAMESERVICE_ID, "Log off called.");

        pauseSession();
    }

    @Override
    public String getPlayerDisplayName() {
        Log.i(GAMESERVICE_ID, "No player name to return.");
        return null;
    }

    @Override
    public boolean isSessionActive() {
        return connected;
    }

    @Override
    public boolean isConnectionPending() {
        return false;
    }

    @Override
    public void showLeaderboards(String leaderBoardId) throws GameServiceException
    {
        Log.i(GAMESERVICE_ID, "Show leaderboards called: " + leaderBoardId);
        throw new GameServiceException.NotSupportedException();
    }

    @Override
    public void showAchievements() throws GameServiceException {
        Log.i(GAMESERVICE_ID, "Show achievements called.");
        throw new GameServiceException.NotSupportedException();
    }

    @Override
    public boolean loadAchievements(LoadAchievementsResponseListener callback) {
        return false;
    }

    @Override
    public boolean submitToLeaderboard(String leaderboardId, long score) {
        Log.i(GAMESERVICE_ID, "Submit to leaderboard " + leaderboardId + ", score " + score );

        return isSessionActive();
    }

    @Override
    public boolean loadLeaderboardEntries(String leaderBoardId, int limit, boolean relatedToPlayer,
                                          LeaderBoardEntriesResponseListener callback) {
        return false;
    }

    @Override
    public boolean unlockAchievement(String achievementId) {
        Log.i(GAMESERVICE_ID, "Unlock achievement " + achievementId);
        return isSessionActive();
    }

    @Override
    public boolean incrementAchievement(String achievementId, int incNum, float completionPercentage) {
        Log.i(GAMESERVICE_ID, "Increment achievement "+ achievementId
                + " by " + incNum + " (" + completionPercentage + "%)");
        return isSessionActive();
    }

}
