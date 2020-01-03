package com.documentscanner;

import com.documentscanner.views.MainView;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

/**
 * Created by andre on 28/11/2017.
 */

public class RCPdfScannerModule extends ReactContextBaseJavaModule{

    public RCPdfScannerModule(ReactApplicationContext reactContext){
        super(reactContext);
    }

    @Override
    public String getName() {
        return "RCPdfScannerManager";
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
}
