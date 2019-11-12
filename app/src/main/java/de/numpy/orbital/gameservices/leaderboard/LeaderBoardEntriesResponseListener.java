package de.numpy.orbital.gameservices.leaderboard;

import java.util.List;

/**
 * Created by Marvin on 28.05.2018.
 */
public interface LeaderBoardEntriesResponseListener
{
    void onLeaderBoardResponse(List<LeaderBoardEntry> leaderBoard);
}
