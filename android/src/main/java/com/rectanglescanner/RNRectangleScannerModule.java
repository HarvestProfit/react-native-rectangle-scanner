package com.rectanglescanner;

import com.rectanglescanner.views.MainView;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

/**
 * Created by Jake on Jan 6, 2020.
 */

public class RNRectangleScannerModule extends ReactContextBaseJavaModule{

    public RNRectangleScannerModule(ReactApplicationContext reactContext){
        super(reactContext);
    }

    @Override
    public String getName() {
        return "RNRectangleScannerManager";
    }

    @ReactMethod
    public void start(){
        MainView view = MainView.getInstance();
        view.startCamera();
    }

    @ReactMethod
    public void stop(){
        MainView view = MainView.getInstance();
        view.stopCamera();
    }

    @ReactMethod
    public void cleanup(){
        MainView view = MainView.getInstance();
        view.cleanupCamera();
    }

    @ReactMethod
    public void refresh(){
        MainView view = MainView.getInstance();
        view.stopCamera();
        view.startCamera();
    }

    @ReactMethod
    public void capture(){
        MainView view = MainView.getInstance();
        view.capture();
    }

    @ReactMethod
    public void focus() {
        MainView view = MainView.getInstance();
        view.focusCamera();
    }
}
