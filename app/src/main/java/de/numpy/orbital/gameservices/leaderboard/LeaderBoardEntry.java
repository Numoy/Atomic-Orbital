package de.numpy.orbital.gameservices.leaderboard;

/**
 * Created by Marvin on 28.05.2018.
 */
public class LeaderBoardEntry
{
    private String formattedValue;
    private long sortValue;
    private String scoreTag;
    private String userDisplayName;
    private String userId;
    private String scoreRank;
    private boolean currentPlayer;

    public String getFormattedValue() {
        return formattedValue;
    }

    public long getSortValue() {
        return sortValue;
    }

    public String getScoreTag() {
        return scoreTag;
    }

    public String getUserDisplayName() {
        return userDisplayName;
    }

    public String getUserId() {
        if (userId != null)
            return userId;
        else
            return "";
    }

    public String getScoreRank() {
        return scoreRank;
    }

    public String getAvatarUrl() {
        return null;
    }

    public boolean isCurrentPlayer() {
        return currentPlayer;
    }

    public void setFormattedValue(String formattedValue)
    {
        this.formattedValue = formattedValue;
    }

    public void setSortValue(long sortValue)
    {
        this.sortValue = sortValue;
    }

    public void setScoreTag(String scoreTag)
    {
        this.scoreTag = scoreTag;
    }

    public void setUserDisplayName(String userDisplayName)
    {
        this.userDisplayName = userDisplayName;
    }

    public void setUserId(String userId)
    {
        this.userId = userId;
    }

    public void setScoreRank(String scoreRank)
    {
        this.scoreRank = scoreRank;
    }

    public void setCurrentPlayer(boolean currentPlayer)
    {
        this.currentPlayer = currentPlayer;
    }
}
