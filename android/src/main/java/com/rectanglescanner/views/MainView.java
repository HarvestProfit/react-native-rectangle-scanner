package com.rectanglescanner.views;

import android.app.Activity;
import android.content.Context;
import android.view.LayoutInflater;
import android.widget.FrameLayout;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.uimanager.events.RCTEventEmitter;

import com.rectanglescanner.R;

public class MainView extends FrameLayout {
    private RNRectangleScannerView view;

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
        FrameLayout frameLayout = (FrameLayout) lf.inflate(R.layout.activity_rectangle_scanner, null);

        view = new RNRectangleScannerView(context, -1, activity, frameLayout);
        view.setParent(this);
        addViewInLayout(view, 0, new FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addViewInLayout(frameLayout, 1, view.getLayoutParams());
    }

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        for (int i = 0; i < getChildCount(); i++) {
            getChildAt(i).layout(l, t, r, b);
        }
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

    public void startCamera() {
        view.startCamera();
    }

    public void stopCamera() {
        view.stopCamera();
    }

    public void cleanupCamera() {
        view.cleanupCamera();
    }

    public void capture() {
        view.capture();
    }

    public void focusCamera() {
      view.focusCamera();
    }

    public void deviceWasSetup(WritableMap config) {
      final ReactContext context = (ReactContext) getContext();
      context.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onDeviceSetup", config);
    }

    public void torchWasChanged(boolean torchEnabled) {
      WritableMap map = new WritableNativeMap();
      map.putBoolean("enabled", torchEnabled);
      final ReactContext context = (ReactContext) getContext();
      context.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onTorchChanged", map);
    }

    public void rectangleWasDetected(WritableMap detection) {
      final ReactContext context = (ReactContext) getContext();
      context.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onRectangleDetected", detection);
    }

    public void pictureWasTaken(WritableMap pictureDetails) {
      final ReactContext context = (ReactContext) getContext();
      context.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onPictureTaken", pictureDetails);
    }

    public void pictureWasProcessed(WritableMap pictureDetails) {
      final ReactContext context = (ReactContext) getContext();
      context.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onPictureProcessed", pictureDetails);
    }

    public void pictureDidFailToProcess(WritableMap errorDetails) {
      final ReactContext context = (ReactContext) getContext();
      context.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onErrorProcessingImage", errorDetails);
    }
}
