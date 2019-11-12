package de.numpy.orbital.android.googleplayservices;

import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.games.Games;
import com.google.android.gms.games.GamesActivityResultCodes;
import com.google.android.gms.games.achievement.AchievementBuffer;
import com.google.android.gms.games.achievement.Achievements;
import com.google.android.gms.games.leaderboard.LeaderboardScore;
import com.google.android.gms.games.leaderboard.LeaderboardScoreBuffer;
import com.google.android.gms.games.leaderboard.LeaderboardVariant;
import com.google.android.gms.games.leaderboard.Leaderboards;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;

import java.util.ArrayList;
import java.util.List;

import de.numpy.orbital.gameservices.achievements.Achievement;
import de.numpy.orbital.gameservices.GameServiceClient;
import de.numpy.orbital.gameservices.GameServiceException;
import de.numpy.orbital.gameservices.GameServiceIdMapper;
import de.numpy.orbital.gameservices.GameServiceListener;
import de.numpy.orbital.gameservices.leaderboard.LeaderBoardEntry;
import de.numpy.orbital.gameservices.achievements.LoadAchievementsResponseListener;
import de.numpy.orbital.gameservices.leaderboard.LeaderBoardEntriesResponseListener;
import de.numpy.orbital.util.math.MathUtils;

/**
 * Created by Marvin on 28.05.2018.
 */

public class GooglePlayGamesClient implements GoogleApiClient.ConnectionCallbacks, GoogleApiClient.OnConnectionFailedListener,
        GameServiceClient
{
    public static final int RC_GPGS_SIGNIN = 9001;
    public static final int RC_LEADERBOARD = 9002;
    public static final int RC_ACHIEVEMENTS = 9003;

    public static final String GAMESERVICE_ID = GameServiceClient.GS_GOOGLEPLAYGAMES_ID;
    protected static final int MAX_CONNECTFAIL_RETRIES = 4;
    protected Activity context;
    protected GameServiceListener gameListener;
    protected GoogleApiClient googleApiClient;
    protected int firstConnectAttempt;
    protected boolean isConnectionPending;
    protected GameServiceIdMapper<String> gpgsLeaderboardIdMapper;
    protected GameServiceIdMapper<String> gpgsAchievementIdMapper;
    protected boolean forceRefresh;
    private boolean resolvingConnectionFailure = false;
    private boolean autoStartSignInflow = true;
    private boolean signInClicked = false;

    public GooglePlayGamesClient setGooglePlayGamesServicesLeaderboardIdMapper(GameServiceIdMapper<String> gpgsLeaderboardIdMapper)
    {
        this.gpgsLeaderboardIdMapper = gpgsLeaderboardIdMapper;
        return this;
    }

    public GooglePlayGamesClient setGooglePlayGamesServicesAchievementIdMapper(GameServiceIdMapper<String> gpgsAchievementIdMapper)
    {
        this.gpgsAchievementIdMapper = gpgsAchievementIdMapper;
        return this;
    }

    public void setFetchForceRefresh(boolean forceRefresh)
    {
        this.forceRefresh = forceRefresh;
    }

    /**
     * Initializes the GoogleApiClient.
     * add onActivityResult method there with call to onGooglePlayGamesServicesActivityResult.
     */
    public GooglePlayGamesClient initialize(Activity context)
    {

        if (googleApiClient != null)
            throw new IllegalStateException("Already initialized.");

        this.context = context;
        // retry some times when connect fails (needed when game state sync is enabled)
        firstConnectAttempt = MAX_CONNECTFAIL_RETRIES;

        GoogleApiClient.Builder builder = new GoogleApiClient.Builder(this.context)
                .addConnectionCallbacks(this)
                .addOnConnectionFailedListener(this)
                .addApi(Games.API).addScope(Games.SCOPE_GAMES);


        googleApiClient = builder.build();

        return this;
    }

    /**
     * Call from onActivityResult()
     */
    public boolean onGooglePlayGamesActivityResult(int requestCode, int resultCode, Intent data)
    {
        if (requestCode == RC_GPGS_SIGNIN)
        {
            signInResult(resultCode, data);
            return true;

        } else if (resultCode == GamesActivityResultCodes.RESULT_RECONNECT_REQUIRED &&
                (requestCode == RC_LEADERBOARD || requestCode == RC_ACHIEVEMENTS))
        {
            disconnect(false);
            return true;
        }
        return false;
    }

    @Override
    public String getGameServiceId()
    {
        return GAMESERVICE_ID;
    }

    @Override
    public boolean resumeSession()
    {
        return connect(true);
    }

    @Override
    public boolean logIn()
    {
        return connect(false);
    }

    public boolean connect(boolean autoStart)
    {
        if (googleApiClient == null)
        {
            Log.e(GAMESERVICE_ID, "Call initialize first.");
            throw new IllegalStateException();
        }

        if (isSessionActive())
        {
            return true;
        }

        Log.i(GAMESERVICE_ID, "Trying to connect with autostart " + autoStart);
        autoStartSignInflow = autoStart;
        signInClicked = !autoStart;
        isConnectionPending = true;
        googleApiClient.connect();

        return true;
    }

    @Override
    public void logOut()
    {
        this.disconnect(false);
    }

    @Override
    public void pauseSession()
    {
        this.disconnect(true);
    }

    public void disconnect(boolean autoEnd)
    {

        if (isSessionActive())
        {
            Log.i(GAMESERVICE_ID, "Disconnecting  " + autoEnd);
            if (!autoEnd)
            {
                tryToSignOut();
            }
            googleApiClient.disconnect();
            if (gameListener != null)
            {
                gameListener.gameServiceOnSessionInactive();
            }
        }
    }

    private void tryToSignOut()
    {
        try
        {
            GoogleSignInClient signInClient = GoogleSignIn.getClient(context,
                    GoogleSignInOptions.DEFAULT_GAMES_SIGN_IN);
            signInClient.signOut().addOnCompleteListener(context,
                    new OnCompleteListener<Void>()
                    {
                        @Override
                        public void onComplete(@NonNull Task<Void> task)
                        {
                            // at this point, the user is signed out.
                        }
                    });
        } catch (Throwable t)
        {
            Log.e(GAMESERVICE_ID, "Some error occured while logging out");
        }
    }

    @Override
    public void onConnected(@Nullable Bundle bundle)
    {
        Log.i(GAMESERVICE_ID, "Successfully signed in with player id " + getPlayerDisplayName());
        firstConnectAttempt = MAX_CONNECTFAIL_RETRIES;
        isConnectionPending = false;
        if (gameListener != null)
        {
            gameListener.gameServiceOnSessionActive();
        }
    }

    @Override
    public String getPlayerDisplayName()
    {
        if (isSessionActive())
            return Games.Players.getCurrentPlayer(googleApiClient)
                    .getDisplayName();
        else
            return null;
    }

    @Override
    public boolean isSessionActive()
    {
        return googleApiClient != null && googleApiClient.isConnected();
    }

    @Override
    public boolean isConnectionPending()
    {
        return isConnectionPending;
    }

    @Override
    public void onConnectionSuspended(int i)
    {
        Log.i(GAMESERVICE_ID, "Connection suspended, trying to reconnect");
        // Attempt to reconnect
        isConnectionPending = true;
        googleApiClient.connect();
    }

    @Override
    public void onConnectionFailed(@NonNull ConnectionResult connectionResult)
    {
        if (resolvingConnectionFailure)
        {
            // already resolving
            return;
        }
        Log.i(GAMESERVICE_ID, "onConnectFailed: " + connectionResult.getErrorCode());

        boolean isPendingBefore = isConnectionPending;

        if (signInClicked)
        {
            autoStartSignInflow = false;
            signInClicked = false;
            resolvingConnectionFailure = true;

            // Attempt to resolve the connection failure using GooglePlayServicesUtility.
            // The R.string.signin_other_error value should reference a generic
            // error string in your strings.xml file, such as "There was
            // an issue with sign-in, please try again later."
            if (!GooglePlayServicesUtility.resolveConnectionFailure(context,
                    googleApiClient, connectionResult,
                    RC_GPGS_SIGNIN, "Unable to sign in."))
            {
                resolvingConnectionFailure = false;
                isConnectionPending = false;
            }
        }
        // Error code 4 is thrown sometimes on first attempt when game state feature is enabled.
        // Just retry some times solves the problem.
        else if (firstConnectAttempt > 0 && connectionResult.getErrorCode() == 4)
        {
            firstConnectAttempt -= 1;
            Log.i(GAMESERVICE_ID, "Retrying to connect...");

            AsyncTask<Void, Void, Void> task = new AsyncTask<Void, Void, Void>()
            {
                @Nullable
                @Override
                protected Void doInBackground(Void... params)
                {
                    try
                    {
                        // wait some time before next try
                        Thread.sleep(200);
                        if (!googleApiClient.isConnected())
                            googleApiClient.connect();
                    } catch (InterruptedException e)
                    {
                        //eat
                    }
                    return null;
                }
            };

            task.execute();

        } else
            isConnectionPending = false;

        // inform listener that connection attempt failed
        if (gameListener != null && isPendingBefore && !isConnectionPending)
            gameListener.gameServiceOnSessionInactive();
    }

    public void signInResult(int resultCode, Intent data)
    {
        signInClicked = false;
        resolvingConnectionFailure = false;
        if (resultCode == Activity.RESULT_OK)
        {
            isConnectionPending = true;
            googleApiClient.connect();
        } else
        {
            Log.i(GAMESERVICE_ID, "SignInResult - Unable to sign in: " + resultCode);

            boolean isPendingBefore = isConnectionPending;
            isConnectionPending = false;

            // inform listener that connection attempt failed
            if (gameListener != null && isPendingBefore)
            {
                gameListener.gameServiceOnSessionInactive();
            }

            // Bring up an error dialog to alert the user that sign-in
            // failed. The R.string.signin_failure should reference an error
            // string in your strings.xml file that tells the user they
            // could not be signed in, such as "Unable to sign in."

            String errorMsg;
            switch (resultCode)
            {
                case GamesActivityResultCodes.RESULT_APP_MISCONFIGURED:
                    errorMsg = "The application is incorrectly configured. Check that the package name and signing " +
                            "certificate match the client ID created in Developer Console. Also, if the application " +
                            "is not yet published, check that the account you are trying to sign in with is listed as" +
                            " a tester account. See logs for more information.";
                    break;
                case GamesActivityResultCodes.RESULT_SIGN_IN_FAILED:
                    errorMsg = "Failed to sign in. Please check your network connection and try again.";
                    break;
                default:
                    errorMsg = null;
            }

            if (errorMsg != null && gameListener != null)
            {
                gameListener.gameServiceShowErrorToUser(GameServiceListener.GameServiceErrorType.errorLoginFailed,
                        "Google Play Games: " + errorMsg, null);
            }

        }
    }

    @Override
    public void showLeaderboards(String leaderBoardId) throws GameServiceException
    {
        if (isSessionActive())
        {
            if (gpgsLeaderboardIdMapper != null)
                leaderBoardId = gpgsLeaderboardIdMapper.mapToGameServiceId(leaderBoardId);

            Games.getLeaderboardsClient(context, GoogleSignIn.getLastSignedInAccount(context))
                    .getLeaderboardIntent(leaderBoardId)
                    .addOnSuccessListener(new OnSuccessListener<Intent>()
                    {
                        @Override
                        public void onSuccess(Intent intent)
                        {
                            context.startActivityForResult(intent, RC_LEADERBOARD);
                        }
                    });
        } else
            throw new GameServiceException.NoSessionException();
    }

    @Override
    public void showAchievements() throws GameServiceException
    {
        if (isSessionActive())
        {
            Games.getAchievementsClient(context, GoogleSignIn.getLastSignedInAccount(context))
                    .getAchievementsIntent()
                    .addOnSuccessListener(new OnSuccessListener<Intent>()
                    {
                        @Override
                        public void onSuccess(Intent intent)
                        {
                            context.startActivityForResult(intent, RC_ACHIEVEMENTS);
                        }
                    });
        } else
        {
            throw new GameServiceException.NoSessionException();
        }
    }

    @Override
    public boolean loadAchievements(final LoadAchievementsResponseListener callback)
    {
        if (!isSessionActive())
            return false;

        AsyncTask<Void, Void, Boolean> task = new AsyncTask<Void, Void, Boolean>()
        {
            @Override
            protected Boolean doInBackground(Void... params)
            {
                return fetchAchievementsSync(callback);
            }
        };

        task.execute();

        return true;

    }

    @Override
    public boolean submitToLeaderboard(String leaderboardId, long score)
    {
        if (gpgsLeaderboardIdMapper != null)
        {
            leaderboardId = gpgsLeaderboardIdMapper.mapToGameServiceId(leaderboardId);
        }

        if (leaderboardId != null && isSessionActive())
        {
            Games.getLeaderboardsClient(context, GoogleSignIn.getLastSignedInAccount(context))
                    .submitScore(leaderboardId, score);
            return true;
        } else
            return false;
    }

    public boolean fetchAchievementsSync(LoadAchievementsResponseListener callback)
    {
        if (!isSessionActive())
        {
            return false;
        }

        Achievements.LoadAchievementsResult achievementsResult = Games.Achievements.load(
                googleApiClient, forceRefresh).await();

        if (!achievementsResult.getStatus().isSuccess())
        {
            Log.i(GAMESERVICE_ID, "Failed to fetch achievements:" +
                    achievementsResult.getStatus().getStatusMessage());
            callback.onLoadAchievementsResponse(null);
            return false;
        }

        AchievementBuffer achievements = achievementsResult.getAchievements();

        List<Achievement> gpgsAchs = new ArrayList<Achievement>(achievements.getCount());

        for (com.google.android.gms.games.achievement.Achievement ach : achievements)
        {
            Achievement gpgsAchievement = new Achievement();

            gpgsAchievement.setAchievementId( ach.getAchievementId() );
            gpgsAchievement.setAchievementMapper( gpgsAchievementIdMapper );
            gpgsAchievement.setDescription( ach.getDescription() );
            gpgsAchievement.setTitle( ach.getName() );

            if (ach.getState() == com.google.android.gms.games.achievement.Achievement.STATE_UNLOCKED)
                gpgsAchievement.setPercCompleted( 1f );
            else if (ach.getType() == com.google.android.gms.games.achievement.Achievement.TYPE_INCREMENTAL)
                gpgsAchievement.setPercCompleted( (float) ach.getCurrentSteps() / ach.getTotalSteps() );

            gpgsAchs.add(gpgsAchievement);
        }

        achievements.release();

        callback.onLoadAchievementsResponse(gpgsAchs);

        return true;
    }

    @Override
    public boolean loadLeaderboardEntries(final String leaderBoardId, final int limit,
                                          final boolean relatedToPlayer,
                                          final LeaderBoardEntriesResponseListener callback)
    {
        if (!isSessionActive())
        {
            return false;
        }

        AsyncTask<Void, Void, Boolean> task = new AsyncTask<Void, Void, Boolean>()
        {
            @Override
            protected Boolean doInBackground(Void... params)
            {
                return fetchLeaderboardEntriesSync(leaderBoardId, limit, relatedToPlayer, callback);
            }
        };

        task.execute();

        return true;
    }

    private boolean fetchLeaderboardEntriesSync(String leaderBoardId, int limit, boolean relatedToPlayer,
                                                LeaderBoardEntriesResponseListener callback)
    {
        if (!isSessionActive())
        {
            return false;
        }

        if (gpgsLeaderboardIdMapper != null)
        {
            leaderBoardId = gpgsLeaderboardIdMapper.mapToGameServiceId(leaderBoardId);
        }

        Leaderboards.LoadScoresResult scoresResult =
                (relatedToPlayer ?
                        Games.Leaderboards.loadTopScores(googleApiClient, leaderBoardId,
                                LeaderboardVariant.TIME_SPAN_ALL_TIME, LeaderboardVariant.COLLECTION_PUBLIC,
                                MathUtils.clamp(limit, 1, 25), forceRefresh).await()
                        :
                        Games.Leaderboards.loadPlayerCenteredScores(googleApiClient, leaderBoardId,
                                LeaderboardVariant.TIME_SPAN_ALL_TIME, LeaderboardVariant.COLLECTION_PUBLIC,
                                MathUtils.clamp(limit, 1, 25), forceRefresh).await());

        if (!scoresResult.getStatus().isSuccess())
        {
            Log.i(GAMESERVICE_ID, "Failed to fetch leaderboard entries:" +
                    scoresResult.getStatus().getStatusMessage());
            callback.onLeaderBoardResponse(null);
            return false;
        }

        LeaderboardScoreBuffer scores = scoresResult.getScores();

        List<LeaderBoardEntry> gpgsLbEs = new ArrayList<>(scores.getCount());
        String playerDisplayName = getPlayerDisplayName();

        for (LeaderboardScore score : scores)
        {
            LeaderBoardEntry gpgsLbE = new LeaderBoardEntry();

            gpgsLbE.setUserDisplayName( score.getScoreHolderDisplayName() );
            gpgsLbE.setCurrentPlayer( gpgsLbE.getUserDisplayName().equalsIgnoreCase(playerDisplayName) );
            gpgsLbE.setFormattedValue( score.getDisplayScore() );
            gpgsLbE.setScoreRank( score.getDisplayRank() );
            gpgsLbE.setUserId( score.getScoreHolder().getPlayerId() );
            gpgsLbE.setSortValue( score.getRawScore() );
            gpgsLbE.setScoreTag( score.getScoreTag() );

            gpgsLbEs.add(gpgsLbE);
        }

        scores.release();

        callback.onLeaderBoardResponse(gpgsLbEs);

        return true;
    }

    @Override
    public boolean unlockAchievement(String achievementId)
    {
        if (gpgsAchievementIdMapper != null)
        {
            achievementId = gpgsAchievementIdMapper.mapToGameServiceId(achievementId);
        }

        if (achievementId != null && isSessionActive())
        {
            Games.getAchievementsClient(context, GoogleSignIn.getLastSignedInAccount(context))
                    .unlock(achievementId);
            return true;
        } else
        {
            return false;
        }
    }

    @Override
    public boolean incrementAchievement(String achievementId, int incNum, float completionPercentage)
    {
        if (gpgsAchievementIdMapper != null)
        {
            achievementId = gpgsAchievementIdMapper.mapToGameServiceId(achievementId);
        }

        if (achievementId != null && isSessionActive())
        {
            Games.getAchievementsClient(context, GoogleSignIn.getLastSignedInAccount(context))
                    .increment(achievementId, incNum);
            return true;
        }
        else
        {
            return false;
        }
    }

    @Override
    public void setListener(GameServiceListener gameListener)
    {
        this.gameListener = gameListener;
    }

}
