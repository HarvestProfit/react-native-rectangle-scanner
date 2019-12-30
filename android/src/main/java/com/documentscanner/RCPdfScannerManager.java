package com.documentscanner;

import android.app.Activity;

import com.documentscanner.views.MainView;
import com.documentscanner.views.OpenNoteCameraView;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;

import javax.annotation.Nullable;

/**
 * Created by Andre on 29/11/2017.
 */

public class RCPdfScannerManager extends ViewGroupManager<MainView> {

    private static final String REACT_CLASS = "RCPdfScanner";
    private MainView view = null;

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    protected MainView createViewInstance(final ThemedReactContext reactContext) {
        // OpenNoteCameraView view = new OpenNoteCameraView(reactContext, -1,
        // reactContext.getCurrentActivity());
        MainView.createInstance(reactContext, (Activity) reactContext.getBaseContext());

        view = MainView.getInstance();

        // Add Events
        view.setOnDeviceSetupListener(new OpenNoteCameraView.OnDeviceSetupListener() {
            @Override
            public void onDeviceSetup(WritableMap data) {
                dispatchEvent(reactContext, "onDeviceSetup", data);
            }
        });

        view.setOnPictureProcessedListener(new OpenNoteCameraView.OnPictureProcessedListener() {
            @Override
            public void onPictureProcessed(WritableMap data) {
                dispatchEvent(reactContext, "onPictureProcessed", data);
            }
        });

        view.setOnPictureTakenListener(new OpenNoteCameraView.OnPictureTakenListener() {
            @Override
            public void onPictureTaken(WritableMap data) {
                dispatchEvent(reactContext, "onPictureTaken", data);
            }
        });

        view.setOnRectangleDetectedListener(new OpenNoteCameraView.OnRectangleDetectedListener() {
            @Override
            public void onRectangleDetected(WritableMap data) {
                dispatchEvent(reactContext, "onRectangleDetected", data);
            }
        });

        view.setOnTorchChangedListener(new OpenNoteCameraView.OnTorchChangedListener() {
            @Override
            public void onTorchChanged(WritableMap data) {
                dispatchEvent(reactContext, "onTorchChanged", data);
            }
        });

        return view;
    }

    private void dispatchEvent(ReactContext reactContext, String eventName, @Nullable WritableMap params) {
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName, params);
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

            "onRectangleDetected", MapBuilder.of("registrationName", "onRectangleDetected"),

            "onTorchChanged", MapBuilder.of("registrationName", "onTorchChanged"),
        );
    }
}
