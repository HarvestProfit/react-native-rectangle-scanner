package com.documentscanner.views;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.hardware.Camera;
import android.hardware.Camera.PictureCallback;
import android.hardware.Camera.Size;
import android.media.AudioManager;
import android.media.MediaActionSound;
import android.os.Build;
import android.os.Environment;
import android.os.HandlerThread;
import android.os.Message;
import android.util.AttributeSet;
import android.util.Log;
import android.view.Display;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.FrameLayout;

import com.documentscanner.ImageProcessor;
import com.documentscanner.R;
import com.documentscanner.helpers.CustomOpenCVLoader;
import com.documentscanner.helpers.OpenNoteMessage;
import com.documentscanner.helpers.PreviewFrame;
import com.documentscanner.helpers.ScannedDocument;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;

import org.opencv.android.BaseLoaderCallback;
import org.opencv.android.JavaCameraView;
import org.opencv.android.LoaderCallbackInterface;
import org.opencv.android.OpenCVLoader;
import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.imgcodecs.Imgcodecs;
import org.opencv.imgproc.Imgproc;

import java.util.List;
import java.util.UUID;

import java.io.File;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static com.documentscanner.helpers.Utils.addImageToGallery;

public class RectangleDetectionController extends CameraDeviceController {
    private HandlerThread mImageThread;
    private ImageProcessor mImageProcessor;
    private int numberOfRectangles = 15;
    private boolean imageProcessorBusy = true;
    private int filterId = 1;

    public void setImageProcessorBusy(boolean isBusy) {
      this.imageProcessorBusy = isBusy;
    }

    public int getFilterId() {
      return this.filterId;
    }

    /**
     Sets the currently active filter
     */
    public void setFilterId(int filterId) {
      this.filterId = filterId;
    }

    //================================================================================
    // Setup
    //================================================================================

    public RectangleDetectionController(Context context, Integer numCam, Activity activity, FrameLayout frameLayout) {
        super(context, numCam, activity, frameLayout);
        initializeImageProcessor(context);
    }

    /**
    Sets up the image processor.  It uses OpenCV so it needs to load that first
    */
    private void initializeImageProcessor(Context context) {
        mActivity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        Display display = mActivity.getWindowManager().getDefaultDisplay();
        android.graphics.Point size = new android.graphics.Point();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            display.getRealSize(size);
        }

        BaseLoaderCallback mLoaderCallback = new BaseLoaderCallback(context) {
            @Override
            public void onManagerConnected(int status) {
                if (status == LoaderCallbackInterface.SUCCESS) {
                    Log.d(TAG, "SUCCESS init OpenCV: " + status);
                } else {
                    Log.d(TAG, "ERROR init OpenCV: " + status);
                    super.onManagerConnected(status);
                }
            }
        };

        if (!OpenCVLoader.initDebug()) {
            CustomOpenCVLoader.initAsync(OpenCVLoader.OPENCV_VERSION_3_1_0, context, mLoaderCallback);
        } else {
            mLoaderCallback.onManagerConnected(LoaderCallbackInterface.SUCCESS);
        }

        if (mImageThread == null) {
            mImageThread = new HandlerThread("Worker Thread");
            mImageThread.start();
        }

        if (mImageProcessor == null) {
            mImageProcessor = new ImageProcessor(mImageThread.getLooper(), this, mContext);
        }
        this.setImageProcessorBusy(false);
    }

    //================================================================================
    // Image Detection
    //================================================================================

    /**
     Runs each frame the image is being pushed to the preview layer
     */
    @Override
    public void processOutput(Mat image) {
      detectRectangleFromImageLater(image);
    }

    /**
     Looks for a rectangle in the given image async
     */
    private void detectRectangleFromImageLater(Mat image) {
      if (!imageProcessorBusy) {
          setImageProcessorBusy(true);
          Message msg = mImageProcessor.obtainMessage();
          msg.obj = new OpenNoteMessage("previewFrame", image);
          mImageProcessor.sendMessageDelayed(msg, 100);
      }
    }

    /**
     Called after a frame is processed and a rectangle was found
     */
    public void rectangleWasDetected(WritableMap detection) {}

    //================================================================================
    // Capture Image
    //================================================================================

    /**
    After an image is captured, this fuction is called and handles cropping the image
    */
    @Override
    public void handleCapturedImage(Mat capturedImage) {
      setImageProcessorBusy(true);
      Message msg = mImageProcessor.obtainMessage();
      msg.obj = new OpenNoteMessage("pictureTaken", capturedImage);
      mImageProcessor.sendMessageAtFrontOfQueue(msg);
    }

    /**
     After an image is captured and cropped, this method is called
     */
    public void onProcessedCapturedImage(ScannedDocument scannedDocument) {

    }
}
