package de.numpy.orbital.gameservices;

/**
 * Created by Marvin on 28.05.2018.
 */
/**
 * Mapping for external Achievement ID's to use internal ID's
 */

public interface
GameServiceIdMapper<A> {
    A mapToGameServiceId(String internalId);
}