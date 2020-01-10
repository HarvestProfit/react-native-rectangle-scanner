package com.rectanglescanner.views;

import android.app.Activity;
import android.content.Context;
import android.util.Log;
import android.widget.FrameLayout;

import com.rectanglescanner.R;
import com.rectanglescanner.helpers.CapturedImage;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;

import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.MatOfInt;
import org.opencv.imgcodecs.Imgcodecs;

import java.util.UUID;
import java.io.File;
import java.util.ArrayList;

/**
  Created by Jake on Jan 6, 2020.

  Wraps up the camera and rectangle detection code into a simple interface.
  Allows you to call start, stop, cleanup, and capture. Also is responsible
  for deterining how to cache the output images.
*/
public class RNRectangleScannerView extends RectangleDetectionController {
    private String cacheFolderName = "RNRectangleScanner";
    private double capturedQuality = 0.5;

    //================================================================================
    // Setup
    //================================================================================

    public RNRectangleScannerView(Context context, Integer numCam, Activity activity, FrameLayout frameLayout) {
        super(context, numCam, activity, frameLayout);
    }

    private MainView parentView = null;

    public void setParent(MainView view) {
      this.parentView = view;
    }

    /**
    Sets the jpeg quality of the output image
    */
    public void setCapturedQuality(double quality) {
      this.capturedQuality = quality;
    }

    /**
    Call to capture an image
    */
    public void capture() {
      captureImageLater();
    }

    /**
     Called after a picture was captured
     */
    private void pictureWasTaken(WritableMap pictureDetails) {
      Log.d(TAG, "picture taken");
      this.parentView.pictureWasTaken(pictureDetails);
    }

    /**
     Called after a picture was captured and finished processing
     */
    private void pictureWasProcessed(WritableMap pictureDetails) {
      Log.d(TAG, "picture processed");
      this.parentView.pictureWasProcessed(pictureDetails);
    }

    /**
    Called if the picture faiiled to be captured
    */
    private void pictureDidFailToProcess(WritableMap errorDetails) {
      Log.d(TAG, "picture failed to process");
      this.parentView.pictureDidFailToProcess(errorDetails);
    }

    /**
     Called after the torch/flash state was changed
     */
    @Override
    protected void torchWasChanged(boolean torchEnabled) {
      Log.d(TAG, "torch changed");
      this.parentView.torchWasChanged(torchEnabled);
    }

    /**
     Called after the camera and session are set up. This lets you check if a
     camera is found and permission is granted to use it.
     */
    @Override
    protected void deviceWasSetup(WritableMap config) {
      Log.d(TAG, "device setup");
      this.parentView.deviceWasSetup(config);
    }


    /**
     Called after a frame is processed and a rectangle was found
     */
    @Override
    public void rectangleWasDetected(WritableMap detection) {
      this.parentView.rectangleWasDetected(detection);
    }


    /**
     After an image is captured and cropped, this method is called
     */
    @Override
    public void onProcessedCapturedImage(CapturedImage capturedImage) {
      WritableMap pictureWasTakenConfig = new WritableNativeMap();
      WritableMap pictureWasProcessedConfig = new WritableNativeMap();
      String croppedImageFileName = null;
      String originalImageFileName = null;
      boolean hasCroppedImage = (capturedImage.processed != null);
      try {
        originalImageFileName = generateStoredFileName("O");
        if (hasCroppedImage) {
          croppedImageFileName = generateStoredFileName("C");
        } else {
          croppedImageFileName = originalImageFileName;
        }
      } catch(Exception e) {
        WritableMap folderError = new WritableNativeMap();
        folderError.putString("message", "Failed to create the cache directory");
        pictureDidFailToProcess(folderError);
        return;
      }

      pictureWasTakenConfig.putString("croppedImage", "file://" + croppedImageFileName);
      pictureWasTakenConfig.putString("initialImage", "file://" + originalImageFileName);
      pictureWasProcessedConfig.putString("croppedImage", "file://" + croppedImageFileName);
      pictureWasProcessedConfig.putString("initialImage", "file://" + originalImageFileName);
      pictureWasTaken(pictureWasTakenConfig);

      if (hasCroppedImage && !this.saveToDirectory(capturedImage.processed, croppedImageFileName)) {
        WritableMap fileError = new WritableNativeMap();
        fileError.putString("message", "Failed to write cropped image to cache");
        fileError.putString("filePath", croppedImageFileName);
        pictureDidFailToProcess(fileError);
        return;
      }
      if (!this.saveToDirectory(capturedImage.original, originalImageFileName)) {
        WritableMap fileError = new WritableNativeMap();
        fileError.putString("message", "Failed to write original image to cache");
        fileError.putString("filePath", originalImageFileName);
        pictureDidFailToProcess(fileError);
        return;
      }

      pictureWasProcessed(pictureWasProcessedConfig);
      capturedImage.release();
      Log.d(TAG, "Captured Images");
    }

    private String generateStoredFileName(String name) throws Exception {
      String folderDir = this.mContext.getCacheDir().toString();
      File folder = new File( folderDir + "/" + this.cacheFolderName);
      if (!folder.exists()) {
          boolean result = folder.mkdirs();
          if (result) {
            Log.d(TAG, "wrote: created folder " + folder.getPath());
          } else {
            Log.d(TAG, "Not possible to create folder");
            throw new Exception("Failed to create the cache directory");
          }
      }
      return folderDir + "/" + this.cacheFolderName + "/" + name + UUID.randomUUID() + ".png";
    }

    /**
    Saves a file to a folder
    */
    private boolean saveToDirectory(Mat doc, String fileName) {
        Mat endDoc = new Mat(doc.size(), CvType.CV_8UC4);
        doc.copyTo(endDoc);
        Core.flip(doc.t(), endDoc, 1);
        ArrayList<Integer> parameters = new ArrayList();
        parameters.add(Imgcodecs.CV_IMWRITE_JPEG_QUALITY);
        parameters.add((int)(this.capturedQuality * 100));
        MatOfInt par = new MatOfInt();
        par.fromList(parameters);
        boolean success = Imgcodecs.imwrite(fileName, endDoc, par);

        endDoc.release();

        return success;
    }

}
