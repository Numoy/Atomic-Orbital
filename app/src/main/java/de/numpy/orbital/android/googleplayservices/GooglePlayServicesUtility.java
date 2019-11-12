package de.numpy.orbital.android.googleplayservices;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.IntentSender;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.common.api.GoogleApiClient;

/**
 * Created by Marvin on 28.05.2018.
 */

public class GooglePlayServicesUtility
{

    public static void showAlert(Activity activity, String message)
    {
        (new AlertDialog.Builder(activity)).setMessage(message)
                .setNeutralButton(android.R.string.ok, null).create().show();
    }

    public static boolean resolveConnectionFailure(Activity activity,
                                                   GoogleApiClient client, ConnectionResult result, int requestCode,
                                                   String fallbackErrorMessage)
    {

        if (result.hasResolution())
        {
            try
            {
                result.startResolutionForResult(activity, requestCode);
                return true;
            } catch (IntentSender.SendIntentException e)
            {
                // The intent was canceled before it was sent.  Return to the default
                // state and attempt to connect to get an updated ConnectionResult.
                client.connect();
                return false;
            }
        } else
        {
            // not resolvable... so show an error message
            int errorCode = result.getErrorCode();
            Dialog dialog = GooglePlayServicesUtil.getErrorDialog(errorCode,
                    activity, requestCode);
            if (dialog != null)
            {
                dialog.show();
            } else
            {
                // no built-in dialog: show the fallback error message
                showAlert(activity, fallbackErrorMessage);
            }
            return false;
        }
    }

    public static Dialog makeSimpleDialog(Activity activity, String text)
    {
        return (new AlertDialog.Builder(activity)).setMessage(text)
                .setNeutralButton(android.R.string.ok, null).create();
    }

    public static Dialog makeSimpleDialog(Activity activity, String title, String text)
    {
        return (new AlertDialog.Builder(activity))
                .setTitle(title)
                .setMessage(text)
                .setNeutralButton(android.R.string.ok, null)
                .create();
    }
}