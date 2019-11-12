package de.numpy.orbital.gameservices.achievements;

import de.numpy.orbital.gameservices.GameServiceIdMapper;

/**
 * Created by Marvin on 28.05.2018.
 */

public class Achievement
{
    private String achievementId;
    private String title;
    private String description;
    private GameServiceIdMapper<String> achievementMapper;
    private float percCompleted;

    public String getAchievementId() {
        return achievementId;
    }


    public boolean isAchievementId(String achievementId) {
        return (achievementMapper == null ? achievementId.equals(achievementId) :
                achievementId.equals(achievementMapper.mapToGameServiceId(achievementId)));
    }

    public void setAchievementId(String achievementId)
    {
        this.achievementId = achievementId;
    }

    public String getTitle()
    {
        return title;
    }

    public void setTitle(String title)
    {
        this.title = title;
    }

    public String getDescription()
    {
        return description;
    }

    public void setDescription(String description)
    {
        this.description = description;
    }

    public GameServiceIdMapper<String> getAchievementMapper()
    {
        return achievementMapper;
    }

    public void setAchievementMapper(GameServiceIdMapper<String> achievementMapper)
    {
        this.achievementMapper = achievementMapper;
    }

    public float getPercCompleted()
    {
        return percCompleted;
    }

    public void setPercCompleted(float percCompleted)
    {
        this.percCompleted = percCompleted;
    }
}
