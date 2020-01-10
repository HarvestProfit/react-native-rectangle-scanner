package com.rectanglescanner;

import android.app.Activity;
import com.rectanglescanner.views.MainView;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;


import javax.annotation.Nullable;
import java.util.Map;

/**
 * Created by Jake on Jan 6, 2020.
 */
public class RNRectangleScannerManager extends ViewGroupManager<MainView> {

    private static final String REACT_CLASS = "RNRectangleScanner";
    private MainView view = null;

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    protected MainView createViewInstance(final ThemedReactContext reactContext) {
        MainView.createInstance(reactContext, (Activity) reactContext.getBaseContext());
        view = MainView.getInstance();
        return view;
    }

    // MARK: Props
    @ReactProp(name = "enableTorch", defaultBoolean = false)
    public void setEnableTorch(MainView view, Boolean enable) {
        view.setEnableTorch(enable);
    }

    @ReactProp(name = "capturedQuality", defaultDouble = 0.5)
    public void setCapturedQuality(MainView view, double quality) {
        view.setCapturedQuality(quality);
    }

    @ReactProp(name = "filterId", defaultInt = 1)
    public void setFilterId(MainView view, int filterId) {
        view.setFilterId(filterId);
    }

    // Life cycle Events
    @Override
    public @Nullable Map getExportedCustomDirectEventTypeConstants() {
        return MapBuilder.of(
            "onDeviceSetup", MapBuilder.of("registrationName", "onDeviceSetup"),

            "onPictureTaken", MapBuilder.of("registrationName", "onPictureTaken"),

            "onPictureProcessed", MapBuilder.of("registrationName", "onPictureProcessed"),

            "onErrorProcessingImage", MapBuilder.of("registrationName", "onErrorProcessingImage"),

            "onRectangleDetected", MapBuilder.of("registrationName", "onRectangleDetected"),

            "onTorchChanged", MapBuilder.of("registrationName", "onTorchChanged")
        );
    }
}
