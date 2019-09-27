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

public class OpenNoteCameraView extends JavaCameraView implements PictureCallback {

    private static final String TAG = "JavaCameraView";
    private Context mContext;
    private SurfaceView mSurfaceView;
    private SurfaceHolder mSurfaceHolder;
    private HUDCanvasView mHud;
    private final boolean mBugRotate = false;
    private ImageProcessor mImageProcessor;
    private boolean mFocused;
    private boolean safeToTakePicture;
    private Activity mActivity;
    private boolean mFlashMode = false;
    private HandlerThread mImageThread;
    private View mWaitSpinner;
    private PictureCallback pCallback;

    private int numberOfRectangles = 15;
    private Boolean enableTorch = false;
    private String overlayColor = null;
    private Boolean saveOnDevice = false;
    private View blinkView = null;
    private View mView = null;
    private boolean manualCapture = false;

    private static OpenNoteCameraView mThis;

    private OnScannerListener listener = null;
    private OnProcessingListener processingListener = null;

    public interface OnScannerListener {
        void onPictureTaken(WritableMap path);
    }

    public interface OnProcessingListener {
        void onProcessingChange(WritableMap path);
    }

    public void setOnScannerListener(OnScannerListener listener) {
        this.listener = listener;
    }

    public void removeOnScannerListener() {
        this.listener = null;
    }

    public void setOnProcessingListener(OnProcessingListener processingListener) {
        this.processingListener = processingListener;
    }

    public void removeOnProcessingListener() {
        this.processingListener = null;
    }

    public OpenNoteCameraView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public OpenNoteCameraView(Context context, Integer numCam, Activity activity, FrameLayout frameLayout) {
        super(context, numCam);
        this.mContext = context;
        this.mActivity = activity;
        pCallback = this;
        mView = frameLayout;

        context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        initOpenCv(context);
    }

    public void setOverlayColor(String rgbaColor) {
        this.overlayColor = rgbaColor;
    }

    public void setSaveOnDevice(Boolean saveOnDevice) {
        this.saveOnDevice = saveOnDevice;
    }

    public void setDetectionCountBeforeCapture(int numberOfRectangles) {
        this.numberOfRectangles = numberOfRectangles;
    }

    public void setEnableTorch(boolean enableTorch) {
        this.enableTorch = enableTorch;

        if (mCamera != null) {
            Camera.Parameters p = mCamera.getParameters();
            p.setFlashMode(enableTorch ? Camera.Parameters.FLASH_MODE_TORCH : Camera.Parameters.FLASH_MODE_OFF);
            mCamera.setParameters(p);
        }
    }

    public void capture() {
        this.requestManualPicture();
    }

    public void setManualOnly(boolean manualOnly) {
        this.manualCapture = manualOnly;
    }

    public void setBrightness(double brightness) {
        if (mImageProcessor != null) {
            mImageProcessor.setBrightness(brightness);
        }
    }

    public void setContrast(double contrast) {
        if (mImageProcessor != null) {
            mImageProcessor.setContrast(contrast);
        }
    }

    private void initOpenCv(Context context) {

        mThis = this;

        mHud = mView.findViewById(R.id.hud);
        mWaitSpinner = mView.findViewById(R.id.wait_spinner);
        blinkView = mView.findViewById(R.id.blink_view);
        blinkView.setBackgroundColor(Color.WHITE);

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
                    enableCameraView();
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

    public HUDCanvasView getHUD() {
        return mHud;
    }

    private boolean imageProcessorBusy = true;

    public void setImageProcessorBusy(boolean imageProcessorBusy) {
        this.imageProcessorBusy = imageProcessorBusy;
    }

    public boolean isFocused() {
        return this.mFocused;
    }

    private void turnCameraOn() {
        mSurfaceView = mView.findViewById(R.id.surfaceView);
        mSurfaceHolder = this.getHolder();
        mSurfaceHolder.addCallback(this);
        mSurfaceHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
        mSurfaceView.setVisibility(SurfaceView.VISIBLE);
    }

    private void enableCameraView() {
        if (mSurfaceView == null) {
            turnCameraOn();
        }
    }

    private int findBestCamera() {
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

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        try {
            int cameraId = findBestCamera();
            mCamera = Camera.open(cameraId);
        } catch (RuntimeException e) {
            System.err.println(e);
            return;
        }

        Camera.Parameters param;
        param = mCamera.getParameters();

        Size pSize = getMaxPreviewResolution();
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

            mHud.getLayoutParams().height = previewHeight;
        }


        Size maxRes = getMaxPictureResolution(previewRatio);
        if (maxRes != null) {
            param.setPictureSize(maxRes.width, maxRes.height);
            Log.d(TAG, "max supported picture resolution: " + maxRes.width + "x" + maxRes.height);
        }

        PackageManager pm = mActivity.getPackageManager();

        if (pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_AUTOFOCUS)) {
            param.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
        } else {
            mFocused = true;
        }
        if (pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)) {
            param.setFlashMode(enableTorch ? Camera.Parameters.FLASH_MODE_TORCH : Camera.Parameters.FLASH_MODE_OFF);
        }
        param.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE);

        mCamera.setParameters(param);

        if (mBugRotate) {
            mCamera.setDisplayOrientation(270);
        } else {
            mCamera.setDisplayOrientation(90);
        }

        if (mImageProcessor != null) {
            mImageProcessor.setBugRotate(mBugRotate);
            mImageProcessor.setNumOfRectangles(numberOfRectangles);
        }

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

        safeToTakePicture = true;

    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        refreshCamera();
    }

    private void refreshCamera() {
        final boolean torchEnabled = this.enableTorch;

        try {
            mCamera.stopPreview();
        }

        catch (Exception e) {
            Log.d(TAG, "Error stopping preview: " + e);
        }

        try {
            mCamera.setPreviewDisplay(mSurfaceHolder);
            mThis.setEnableTorch(torchEnabled);
            mCamera.startPreview();
            mCamera.setPreviewCallback(this);
        } catch (Exception e) {
            Log.d(TAG, "Error starting preview: " + e);
        }
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        if (mCamera != null) {
            mCamera.stopPreview();
            mCamera.setPreviewCallback(null);
            mCamera.release();
            mCamera = null;
        }
    }

    @Override
    public void onPreviewFrame(byte[] data, Camera camera) {

        Camera.Size pictureSize = camera.getParameters().getPreviewSize();

        if (mFocused && !imageProcessorBusy) {
            setImageProcessorBusy(true);
            Mat yuv = new Mat(new org.opencv.core.Size(pictureSize.width, pictureSize.height * 1.5), CvType.CV_8UC1);
            yuv.put(0, 0, data);

            Mat mat = new Mat(new org.opencv.core.Size(pictureSize.width, pictureSize.height), CvType.CV_8UC4);
            Imgproc.cvtColor(yuv, mat, Imgproc.COLOR_YUV2RGBA_NV21, 4);

            yuv.release();

            if (!manualCapture) {
                sendImageProcessorMessage("previewFrame", new PreviewFrame(mat, true, false));
            }

        }

    }

    public void invalidateHUD() {
        mActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mHud.invalidate();
            }
        });
    }

    private void sendImageProcessorMessage(String messageText, Object obj) {
        Log.d(TAG, "sending message to ImageProcessor: " + messageText + " - " + obj.toString());
        Message msg = mImageProcessor.obtainMessage();
        msg.obj = new OpenNoteMessage(messageText, obj);
        mImageProcessor.sendMessage(msg);
    }

    private void blinkScreenAndShutterSound() {
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

    public void waitSpinnerVisible() {
        mActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mWaitSpinner.setVisibility(View.VISIBLE);
                WritableMap data = new WritableNativeMap();
                data.putBoolean("processing", true);
                mThis.processingListener.onProcessingChange(data);
            }
        });
    }

    public void waitSpinnerInvisible() {
        mActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                // blinkView.setVisibility(View.INVISIBLE);
                mWaitSpinner.setVisibility(View.INVISIBLE);
                WritableMap data = new WritableNativeMap();
                data.putBoolean("processing", false);
                mThis.processingListener.onProcessingChange(data);
            }
        });
    }

    private void blinkScreen() {
        mActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                blinkView.bringToFront();
                Animation animation = AnimationUtils.loadAnimation(mContext, R.anim.blink);
                blinkView.startAnimation(animation);
                blinkView.setVisibility(View.INVISIBLE);

            }
        });
    }

    private void requestManualPicture() {
        this.waitSpinnerVisible();
        this.requestPicture();
    }

    public void requestPicture() {
        PackageManager pm = mActivity.getPackageManager();
        if (safeToTakePicture) {

            safeToTakePicture = false;

            try {
                if (pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_AUTOFOCUS)) {
                    mCamera.autoFocus(new Camera.AutoFocusCallback() {
                        @Override
                        public void onAutoFocus(boolean success, Camera camera) {
                            Log.d(TAG, "onAutoFocusSuccess: " + success);
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
        blinkScreen();
        blinkScreenAndShutterSound();
    }

    private String saveToDirectory(Mat doc) {
        String fileName;
        String folderName = "documents";
        String folderDir = this.saveOnDevice ? Environment.getExternalStorageDirectory().toString() : this.mContext.getCacheDir().toString();
        File folder = new File( folderDir + "/" + folderName);
        if (!folder.exists()) {
            boolean result = folder.mkdirs();
            if (result) Log.d(TAG, "wrote: created folder " + folder.getPath());
            else Log.d(TAG, "Not possible to create folder"); // TODO: Manage this error better
        }
        fileName = folderDir + "/" + folderName + "/" + UUID.randomUUID()
                + ".jpg";

        Mat endDoc = new Mat(Double.valueOf(doc.size().width).intValue(), Double.valueOf(doc.size().height).intValue(),
                CvType.CV_8UC4);

        Core.flip(doc.t(), endDoc, 1);

        Imgcodecs.imwrite(fileName, endDoc);

        endDoc.release();

        return fileName;
    }

    public void saveDocument(ScannedDocument scannedDocument) {

        Mat doc = (scannedDocument.processed != null) ? scannedDocument.processed : scannedDocument.original;

        String fileName = this.saveToDirectory(doc);
        String initialFileName = this.saveToDirectory(scannedDocument.original);

        WritableMap data = new WritableNativeMap();

        if (this.listener != null) {
            data.putInt("height", scannedDocument.heightWithRatio);
            data.putInt("width", scannedDocument.widthWithRatio);
            data.putString("croppedImage", "file://" + fileName);
            data.putString("initialImage", "file://" + initialFileName);
            data.putMap("rectangleCoordinates", scannedDocument.previewPointsAsHash());

            this.listener.onPictureTaken(data);
        }


        Log.d(TAG, "wrote: " + fileName);


        if (this.saveOnDevice) {
            // TODO: Change name addImageToGallery to saveOnDevice
            addImageToGallery(fileName, mContext);
        }

        refreshCamera();

    }

    private List<Size> getResolutionList() {
        return mCamera.getParameters().getSupportedPreviewSizes();
    }

    private List<Size> getPictureResolutionList() {
        return mCamera.getParameters().getSupportedPictureSizes();
    }

    public void setFlash(boolean stateFlash) {
        /* */
        Camera.Parameters par = mCamera.getParameters();
        par.setFlashMode(stateFlash ? Camera.Parameters.FLASH_MODE_TORCH : Camera.Parameters.FLASH_MODE_OFF);
        mCamera.setParameters(par);
        Log.d(TAG, "flash: " + (stateFlash ? "on" : "off"));
        // */
    }

    @Override
    public void onPictureTaken(byte[] data, Camera camera) {

        Camera.Size pictureSize = camera.getParameters().getPictureSize();

        Mat mat = new Mat(new org.opencv.core.Size(pictureSize.width, pictureSize.height), CvType.CV_8U);
        mat.put(0, 0, data);

        setImageProcessorBusy(true);
        sendImageProcessorMessage("pictureTaken", mat);
        camera.cancelAutoFocus();
        safeToTakePicture = true;
        waitSpinnerInvisible();

    }

    private void onPictureFailed() {
        mCamera.cancelAutoFocus();
        safeToTakePicture = true;
        waitSpinnerInvisible();

    }

    public int parsedOverlayColor() {
        {
            Pattern c = Pattern.compile("rgba *\\( *([0-9]+), *([0-9]+), *([0-9]+), *([0-9]\\.?[0-9]?)*\\)");
            Matcher m = c.matcher(this.overlayColor);

            if (m.matches()) {
                return Color.argb((int) (255 * Float.valueOf(m.group(4))), Integer.valueOf(m.group(1)),
                        Integer.valueOf(m.group(2)), Integer.valueOf(m.group(3)));
            }

            return Color.argb(180, 66, 165, 245);

        }
    }
}