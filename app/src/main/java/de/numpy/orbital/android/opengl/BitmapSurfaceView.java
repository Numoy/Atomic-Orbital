package de.numpy.orbital.android.opengl;

import android.content.Context;
import android.opengl.GLSurfaceView;

public class BitmapSurfaceView extends GLSurfaceView
{

    public BitmapSurfaceView(Context context)
    {
        super(context);
        // Create an OpenGL ES 2.0 context
        setEGLContextClientVersion(1);

        setRenderer(new BitmapRenderer(context));
        setRenderMode(GLSurfaceView.RENDERMODE_WHEN_DIRTY);
    }

}
