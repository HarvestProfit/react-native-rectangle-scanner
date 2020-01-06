package com.rectanglescanner.views;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.hardware.Camera;
import android.hardware.Camera.PictureCallback;
import android.media.AudioManager;
import android.media.MediaActionSound;
import android.os.Build;
import android.util.AttributeSet;
import android.util.Log;
import android.view.Display;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.content.res.Configuration;
import android.widget.FrameLayout;

import com.rectanglescanner.R;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;

import org.opencv.android.JavaCameraView;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.Size;
import org.opencv.imgproc.Imgproc;

import java.util.List;


/**
  Created by Jake on Jan 6, 2020.

  Handles Generic camera device setup and capture
*/
public class CameraDeviceController extends JavaCameraView implements PictureCallback {
    public static final String TAG = "CameraDeviceController";
    protected Context mContext;
    private SurfaceView mSurfaceView;
    private SurfaceHolder mSurfaceHolder;
    protected final boolean mBugRotate = false;
    protected boolean mFocused;
    protected boolean safeToTakePicture;
    protected Activity mActivity;
    private PictureCallback pCallback;
    protected Boolean enableTorch = false;
    public int lastDetectedRotation = Surface.ROTATION_0;
    protected View mView = null;


    protected boolean cameraIsSetup = false;
    protected boolean isStopped = true;
    private WritableMap deviceConfiguration = new WritableNativeMap();
    private int captureDevice = -1;
    private boolean imageProcessorBusy = true;

    private static CameraDeviceController mThis;

    public CameraDeviceController(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public CameraDeviceController(Context context, Integer numCam, Activity activity, FrameLayout frameLayout) {
        super(context, numCam);
        this.mContext = context;
        this.mActivity = activity;
        pCallback = this;
        mView = frameLayout;

        context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
    }

    //================================================================================
    // Setters
    //================================================================================

    public boolean isFocused() {
        return this.mFocused;
    }

    public void setCapturedQuality(double quality) {
      // TODO: Do something with this
    }

    /**
     Toggles the flash on the camera device
     */
    public void setEnableTorch(boolean enableTorch) {
        this.enableTorch = enableTorch;

        if (mCamera != null) {
            Camera.Parameters p = mCamera.getParameters();
            p.setFlashMode(enableTorch ? Camera.Parameters.FLASH_MODE_TORCH : Camera.Parameters.FLASH_MODE_OFF);
            mCamera.setParameters(p);

        }

        torchWasChanged(enableTorch);
    }
    protected void torchWasChanged(boolean torchEnabled) {}


    /**
     Cleans up the camera view
     */
    public void cleanupCamera() {
      if (mCamera != null) {
          mCamera.stopPreview();
          mCamera.setPreviewCallback(null);
          mCamera.release();
          mCamera = null;
          this.cameraIsSetup = false;
      }
    }

    /**
    Stops and restarts the camera
    */
    private void refreshCamera() {
      stopCamera();
      startCamera();
    }

    /**
     Starts the capture session
     */
    public void startCamera() {
      if (this.isStopped) {
        try {
            if (!this.cameraIsSetup) {
                setupCameraView();
            }
            mCamera.setPreviewDisplay(mSurfaceHolder);
            mCamera.startPreview();
            mCamera.setPreviewCallback(this);
            this.isStopped = false;
        } catch (Exception e) {
            Log.d(TAG, "Error starting preview: " + e);
        }
      }
    }

    /**
     Stops the capture session
     */
    public void stopCamera() {
      if (!this.isStopped) {
        try {
          if (mCamera != null) {
            mCamera.stopPreview();
          }
          this.isStopped = true;
        }
        catch (Exception e) {
            Log.d(TAG, "Error stopping preview: " + e);
        }
      }
    }

    /**
     Sets the device configuration flash setting
     */
    public void setDeviceConfigurationFlashAvailable(boolean isAvailable) {
      this.deviceConfiguration.putBoolean("flashIsAvailable", isAvailable);
    }

    /**
     Sets the device configuration permission setting
     */
    public void setDeviceConfigurationPermissionToUseCamera(boolean granted){
      this.deviceConfiguration.putBoolean("permissionToUseCamera", granted);
    }

    /**
     Sets the device configuration camera availablility
     */
    public void setDeviceConfigurationHasCamera(boolean isAvailable){
      this.deviceConfiguration.putBoolean("hasCamera", isAvailable);
    }

    /**
     Sets the inital device configuration
     */
    public void resetDeviceConfiguration()
    {
      this.deviceConfiguration = new WritableNativeMap();
      setDeviceConfigurationFlashAvailable(false);
      setDeviceConfigurationPermissionToUseCamera(false);
      setDeviceConfigurationHasCamera(false);
    }

    /**
     Called after the camera and session are set up. This lets you check if a
     camera is found and permission is granted to use it.
     */
    public void commitDeviceConfiguration() {
      deviceWasSetup(this.deviceConfiguration);
    }
    protected void deviceWasSetup(WritableMap config) {}

    //================================================================================
    // Getters
    //================================================================================

    private int getCameraDevice() {
        int cameraId = -1;
        // Search for the back facing camera
        // get the number of cameras
        int numberOfCameras = Camera.getNumberOfCameras();
        // for every camera check
        for (int i = 0; i < numberOfCameras; i++) {
            Camera.CameraInfo info = new Camera.CameraInfo();
            Camera.getCameraInfo(i, info);
            if (info.facing == Camera.CameraInfo.CAMERA_FACING_BACK) {
                cameraId = i;
                break;
            }
            cameraId = i;
        }
        return cameraId;
    }

    private Camera.Size getMaxPreviewResolution() {
        int maxWidth = 0;
        Camera.Size curRes = null;

        mCamera.lock();

        for (Camera.Size r : getResolutionList()) {
            if (r.width > maxWidth) {
                Log.d(TAG, "supported preview resolution: " + r.width + "x" + r.height);
                maxWidth = r.width;
                curRes = r;
            }
        }

        return curRes;
    }

    private Camera.Size getMaxPictureResolution(float previewRatio) {
        int maxPixels = 0;
        int ratioMaxPixels = 0;
        Camera.Size currentMaxRes = null;
        Camera.Size ratioCurrentMaxRes = null;
        for (Camera.Size r : getPictureResolutionList()) {
            float pictureRatio = (float) r.width / r.height;
            Log.d(TAG, "supported picture resolution: " + r.width + "x" + r.height + " ratio: " + pictureRatio);
            int resolutionPixels = r.width * r.height;

            if (resolutionPixels > ratioMaxPixels && pictureRatio == previewRatio) {
                ratioMaxPixels = resolutionPixels;
                ratioCurrentMaxRes = r;
            }

            if (resolutionPixels > maxPixels) {
                maxPixels = resolutionPixels;
                currentMaxRes = r;
            }
        }

        if (ratioCurrentMaxRes != null) {

            Log.d(TAG, "Max supported picture resolution with preview aspect ratio: " + ratioCurrentMaxRes.width + "x"
                    + ratioCurrentMaxRes.height);
            return ratioCurrentMaxRes;

        }

        return currentMaxRes;
    }

    //================================================================================
    // Setup
    //================================================================================


    /**
     Creates a session for the camera device and outputs it to a preview view.
     @note Called on view did load
     */
    public void setupCameraView()
    {
      resetDeviceConfiguration();
      if (mSurfaceView == null) {
        mSurfaceView = mView.findViewById(R.id.surfaceView);
        mSurfaceHolder = this.getHolder();
        mSurfaceHolder.addCallback(this);
        mSurfaceHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
      }
      setupCamera();
      commitDeviceConfiguration();
      // [self listenForOrientationChanges];
      this.cameraIsSetup = true;
    }



    /*!
     Sets up the hardware and capture session asking for permission to use the camera if needed.
     */
    public void setupCamera() {
      if (!setupCaptureDevice()) {
        return;
      }

      Camera.Parameters param;
      param = mCamera.getParameters();

      PackageManager pm = mActivity.getPackageManager();

      if (pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)) {
        param.setFlashMode(Camera.Parameters.FLASH_MODE_OFF);
      }

      if (param.getSupportedFocusModes().contains(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE)) {
        param.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE);
      } else if (param.getSupportedFocusModes().contains(Camera.Parameters.FOCUS_MODE_AUTO)) {
        param.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
      }

      mCamera.setDisplayOrientation(getScreenRotationOnPhone());

      try {
          mCamera.setAutoFocusMoveCallback(new Camera.AutoFocusMoveCallback() {
              @Override
              public void onAutoFocusMoving(boolean start, Camera camera) {
                  mFocused = !start;
                  Log.d(TAG, "focusMoving: " + mFocused);
              }
          });
      } catch (Exception e) {
          Log.d(TAG, "failed setting AutoFocusMoveCallback");
      }

      // some devices doesn't call the AutoFocusMoveCallback - fake the
      // focus to true at the start
      mFocused = true;

      Camera.Size pSize = getMaxPreviewResolution();
      param.setPreviewSize(pSize.width, pSize.height);
      param.setWhiteBalance(Camera.Parameters.WHITE_BALANCE_AUTO);
      float previewRatio = (float) pSize.width / pSize.height;

      Display display = mActivity.getWindowManager().getDefaultDisplay();
      android.graphics.Point size = new android.graphics.Point();
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
          display.getRealSize(size);
      }

      int displayWidth = Math.min(size.y, size.x);
      int displayHeight = Math.max(size.y, size.x);

      float displayRatio = (float) displayHeight / displayWidth;

      int previewHeight;

      if (displayRatio > previewRatio) {
          ViewGroup.LayoutParams surfaceParams = mSurfaceView.getLayoutParams();
          previewHeight = (int) ((float) size.y / displayRatio * previewRatio);
          surfaceParams.height = previewHeight;
          mSurfaceView.setLayoutParams(surfaceParams);
      }

      Camera.Size maxRes = getMaxPictureResolution(previewRatio);
      if (maxRes != null) {
          param.setPictureSize(maxRes.width, maxRes.height);
          Log.d(TAG, "max supported picture resolution: " + maxRes.width + "x" + maxRes.height);
      }

      try {
          mCamera.setParameters(param);
          setDeviceConfigurationPermissionToUseCamera(true);
          safeToTakePicture = true;
      } catch (Exception e) {
          Log.d(TAG, "failed to initialize the camera settings");
      }
    }


    /*!
     Finds a physical camera, configures it, and sets the captureDevice property to it
     @return boolean if the camera was found and opened correctly
     */
    public boolean setupCaptureDevice() {
      this.captureDevice = getCameraDevice();

      try {
          int cameraId = getCameraDevice();
          mCamera = Camera.open(cameraId);
      } catch (RuntimeException e) {
          System.err.println(e);
          return false;
      }
      setDeviceConfigurationHasCamera(true);

      PackageManager pm = mActivity.getPackageManager();
      if (pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)) {
        setDeviceConfigurationFlashAvailable(true);
      }
      return true;
    }

    //================================================================================
    // Capture Image
    //================================================================================


    public void captureImageLater() {
      PackageManager pm = mActivity.getPackageManager();
      if (safeToTakePicture) {

          safeToTakePicture = false;

          try {
              if (pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_AUTOFOCUS)) {
                  mCamera.autoFocus(new Camera.AutoFocusCallback() {
                      @Override
                      public void onAutoFocus(boolean success, Camera camera) {
                          if (success) {
                              takePicture();
                          } else {
                              onPictureFailed();
                          }
                      }
                  });
              } else {
                  takePicture();
              }
          } catch (Exception e) {
              onPictureFailed();
          }
      }
    }

    private void takePicture() {
        mCamera.takePicture(null, null, pCallback);
        makeShutterSound();
    }

    private void onPictureFailed() {
        mCamera.cancelAutoFocus();
        safeToTakePicture = true;
    }

    /*!
     Responds to the capture image call. It will apply a few filters and call handleCapturedImage which can be overrided for more processing
     */
    @Override
    public void onPictureTaken(byte[] data, Camera camera) {
        setEnableTorch(false);
        Camera.Size pictureSize = camera.getParameters().getPictureSize();

        Mat mat = new Mat(new Size(pictureSize.width, pictureSize.height), CvType.CV_8U);
        mat.put(0, 0, data);
        camera.cancelAutoFocus();
        safeToTakePicture = true;
        handleCapturedImage(mat);
    }
    public void handleCapturedImage(Mat capturedImage) {}


    public int getScreenRotationOnPhone() {
      final Display display = ((WindowManager) mContext
            .getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay();

      this.lastDetectedRotation = display.getRotation();
      switch (this.lastDetectedRotation) {
          case Surface.ROTATION_0:
              return 90;

          case Surface.ROTATION_90:
              return 0;

          case Surface.ROTATION_180:
              return 270;

          case Surface.ROTATION_270:
              return 180;
      }
      return 90;
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        mCamera.setDisplayOrientation(getScreenRotationOnPhone());
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        cleanupCamera();
    }

    /*!
     Processes the image output from the capture session.
     */
    @Override
    public void onPreviewFrame(byte[] data, Camera camera) {
      try {
        mSurfaceView.setVisibility(SurfaceView.VISIBLE);
        Camera.Size pictureSize = camera.getParameters().getPreviewSize();
        Mat yuv = new Mat(new Size(pictureSize.width, pictureSize.height * 1.5), CvType.CV_8UC1);
        yuv.put(0, 0, data);

        Mat mat = new Mat(new Size(pictureSize.width, pictureSize.height), CvType.CV_8UC4);
        Imgproc.cvtColor(yuv, mat, Imgproc.COLOR_YUV2RGBA_NV21, 4);

        yuv.release();

        processOutput(mat);
      } catch(Exception e) {
        Log.d(TAG, "Error processing preview frame: " + e);
      }
    }

    public void processOutput(Mat image) {}

    private void makeShutterSound() {
        AudioManager audio = (AudioManager) mActivity.getSystemService(Context.AUDIO_SERVICE);
        switch (audio.getRingerMode()) {
            case AudioManager.RINGER_MODE_NORMAL:
                MediaActionSound sound = new MediaActionSound();
                sound.play(MediaActionSound.SHUTTER_CLICK);
                break;
            case AudioManager.RINGER_MODE_SILENT:
            case AudioManager.RINGER_MODE_VIBRATE:
                break;
        }
    }

    private List<Camera.Size> getResolutionList() {
        return mCamera.getParameters().getSupportedPreviewSizes();
    }

    private List<Camera.Size> getPictureResolutionList() {
        return mCamera.getParameters().getSupportedPictureSizes();
    }

}
