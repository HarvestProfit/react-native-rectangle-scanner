package com.rectanglescanner.views;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.os.HandlerThread;
import android.os.Message;
import android.util.Log;
import android.view.Display;
import android.view.WindowManager;
import android.widget.FrameLayout;

import com.rectanglescanner.R;
import com.rectanglescanner.helpers.ImageProcessor;
import com.rectanglescanner.helpers.CustomOpenCVLoader;
import com.rectanglescanner.helpers.ImageProcessorMessage;
import com.rectanglescanner.helpers.CapturedImage;
import com.facebook.react.bridge.WritableMap;

import org.opencv.android.BaseLoaderCallback;
import org.opencv.android.LoaderCallbackInterface;
import org.opencv.android.OpenCVLoader;
import org.opencv.core.Mat;

/**
  Created by Jake on Jan 6, 2020.

  Takes the output from the camera device controller and attempts to detect
  rectangles from the output. On capture, it will also crop the image.
*/
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
          msg.obj = new ImageProcessorMessage("previewFrame", image);
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
      msg.obj = new ImageProcessorMessage("pictureTaken", capturedImage);
      mImageProcessor.sendMessageAtFrontOfQueue(msg);
    }

    /**
     After an image is captured and cropped, this method is called
     */
    public void onProcessedCapturedImage(CapturedImage scannedDocument) {

    }
}
