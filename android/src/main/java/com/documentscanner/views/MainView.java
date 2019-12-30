package com.documentscanner.views;

import android.app.Activity;
import android.content.Context;
import android.view.LayoutInflater;
import android.widget.FrameLayout;

import com.documentscanner.R;

/**
 * Created by andre on 09/01/2018.
 */

public class MainView extends FrameLayout {
    private OpenNoteCameraView view;

    public static MainView instance = null;

    public static MainView getInstance() {
        return instance;
    }

    public static void createInstance(Context context, Activity activity) {
        instance = new MainView(context, activity);
    }

    private MainView(Context context, Activity activity) {
        super(context);

        LayoutInflater lf = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        FrameLayout frameLayout = (FrameLayout) lf.inflate(R.layout.activity_open_note_scanner, null);

        view = new OpenNoteCameraView(context, -1, activity, frameLayout);
        addViewInLayout(view, 0, new FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addViewInLayout(frameLayout, 1, view.getLayoutParams());
    }

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        for (int i = 0; i < getChildCount(); i++) {
            getChildAt(i).layout(l, t, r, b);
        }
    }

    public void setDetectionCountBeforeCapture(int numberOfRectangles) {
        view.setDetectionCountBeforeCapture(numberOfRectangles);
    }

    public void setEnableTorch(boolean enable) {
        view.setEnableTorch(enable);
    }

    public void setCapturedQuality(double quality) {
        view.setCapturedQuality(quality);
    }

    public void setFilterId(int filterId) {
        view.setFilterId(filterId);
    }

    public void setOnScannerListener(OpenNoteCameraView.OnScannerListener listener) {
        view.setOnScannerListener(listener);
    }

    public void setOnProcessingListener(OpenNoteCameraView.OnProcessingListener listener) {
        view.setOnProcessingListener(listener);
    }

    public void setOverlayColor(String rgbaColor) {
        view.setOverlayColor(rgbaColor);
    }

    public void setSaveOnDevice(Boolean saveOnDevice) {
        view.setSaveOnDevice(saveOnDevice);
    }

    public void setBrightness(double brightness) {
        view.setBrightness(brightness);
    }

    public void setContrast(double contrast) {
        view.setContrast(contrast);
    }

    public void setManualOnly(boolean manualOnly) {
        view.setManualOnly(manualOnly);
    }

    public void capture() {
        view.capture();
    }


    private void deviceWasSetup(WritableMap config) {
      final ReactContext context = (ReactContext) getContext();
      context.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onDeviceSetup", config);
    }

    private void torchWasChanged(boolean torchEnabled) {
      WritableMap map = Arguments.createMap();
      map.putBoolean("enabled", torchEnabled);
      final ReactContext context = (ReactContext) getContext();
      context.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onTorchChanged", map);
    }

    private void rectangleWasDetected(WritableMap detection) {
      final ReactContext context = (ReactContext) getContext();
      context.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onRectangleDetected", detection);
    }

    private void pictureWasTaken(WritableMap pictureDetails) {
      final ReactContext context = (ReactContext) getContext();
      context.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onPictureTaken", pictureDetails);
    }

    private void pictureWasProcessed(WritableMap pictureDetails) {
      final ReactContext context = (ReactContext) getContext();
      context.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onPictureProcessed", pictureDetails);
    }
}
