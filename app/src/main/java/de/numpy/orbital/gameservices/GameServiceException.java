package de.numpy.orbital.gameservices;

/**
 * Created by Marvin on 28.05.2018.
 */

public class GameServiceException extends Throwable
{
    public static class NotSupportedException extends GameServiceException
    {

    }

    public static class NoSessionException extends GameServiceException
    {

    }

}