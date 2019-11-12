package de.numpy.orbital.android.graphic;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

import de.numpy.orbital.graphic.GraphicInterface;

//Own opengl implementation
public class OpenGLView extends GLSurfaceView implements GraphicInterface, GLSurfaceView.Renderer {
    public OpenGLView(Context context) {
        super(context);
        setEGLContextClientVersion(2);
        setRenderer(this);
    }

    @Override
    public void drawBitmap(Bitmap bitmap, Matrix matrix) {
        //TODO:
    }

    @Override
    public void drawBitmap(Bitmap bitmap, Matrix matrix, int alpha) {
        //TODO:
    }

    @Override
    public void start() {
        //TODO:
    }

    @Override
    public void end() {
        //TODO:
    }

    @Override
    public void onSurfaceCreated(GL10 gl10, EGLConfig eglConfig) {
        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    }

    @Override
    public void onSurfaceChanged(GL10 gl10, int width, int height) {
        GLES20.glViewport(0, 0, width, height);
    }

    @Override
    public void onDrawFrame(GL10 gl10) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
    }
}
