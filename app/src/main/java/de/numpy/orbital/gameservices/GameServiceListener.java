package de.numpy.orbital.gameservices;

/**
 * Created by Marvin on 28.05.2018.
 */
public interface GameServiceListener
{
    public void gameServiceOnSessionActive();

    public void gameServiceOnSessionInactive();

    public void gameServiceShowErrorToUser(GameServiceErrorType errorType, String msg, Throwable t);

    public enum GameServiceErrorType
    {
        errorLoginFailed,
        errorUnknown,
        errorServiceUnreachable,
        errorLogoutFailed
    }
}
