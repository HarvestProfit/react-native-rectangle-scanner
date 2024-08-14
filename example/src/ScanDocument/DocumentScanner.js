import React, { useRef, useState } from 'react';
import { Animated, ActivityIndicator, Dimensions, Text, TouchableOpacity, View } from 'react-native';
import Scanner, { Filters, FlashAnimation, RectangleOverlay } from 'react-native-rectangle-scanner';

import { styles } from './styles';
import CameraControls from './CameraControls';

const JPEGQuality = 0.7;

const DocumentScanner = ({ closeScanner, onScannedImage }) => {
  const [loadingCamera, setLoadingCamera] = useState(true);
  const [cameraError, setCameraError] = useState();
  const [cameraOn, setCameraOn] = useState(true);
  const [flashOn, setFlashOn] = useState(false);
  const [filterId, setFilterId] = useState(Filters.PLATFORM_DEFAULT_FILTER_ID);
  const [flashIsAvailable, setFlashIsAvailable] = useState(false);
  const [processingImage, setProcessingImage] = useState(false);
  const [previewSize, setPreviewSize] = useState({});
  const [detectedRectangle, setDetectedRectangle] = useState();
  // const flashScreenOnCaptureAnimation = useRef(new Animated.Value(0)).current;
  const cameraRef = useRef();

  const capture = () => {
    if (processingImage) return;
    setProcessingImage(true);
    cameraRef.current.capture();
    // FlashAnimation.triggerSnapAnimation(flashScreenOnCaptureAnimation);
  }

  const onPictureProcessed = (event) => {
    console.log('cropped, transformed, and added filters to captured image');
    onScannedImage(event);
    setProcessingImage(false);
  }

  const onDeviceSetup = (device) => {
    setLoadingCamera(false);
    setFlashIsAvailable(device.flashIsAvailable);
    if (!device.hasCamera) {
      setCameraError('Device does not have a camera');
      setCameraOn(false);
    } else if (!device.permissionToUseCamera) {
      setCameraError('App does not have permission to use the camera');
      setCameraOn(false);
    }

    const dimensions = Dimensions.get('window');
    setPreviewSize({
      height: `${device.previewHeightPercent * 100}%`,
      width: `${device.previewWidthPercent * 100}%`,
      marginTop: (1 - device.previewHeightPercent) * dimensions.height / 2,
      marginLeft: (1 - device.previewWidthPercent) * dimensions.width / 2,
    });
  }

  if (cameraOn) {
    return (
      <View style={{ position: 'relative', marginTop: previewSize.marginTop, marginLeft: previewSize.marginLeft, height: previewSize.height, width: previewSize.width }}>
        <Scanner
          onPictureTaken={() => console.log('picture captured...')}
          onPictureProcessed={onPictureProcessed}
          onErrorProcessingImage={(err) => console.error('Failed to capture scan', err?.message)}
          enableTorch={flashOn}
          filterId={filterId}
          ref={cameraRef}
          capturedQuality={JPEGQuality}
          onRectangleDetected={(value) => setDetectedRectangle(value.detectedRectangle)}
          onDeviceSetup={onDeviceSetup}
          onTorchChanged={({ enabled }) => setFlashOn(enabled)}
          style={styles.scanner}
        />

        {!processingImage && (
          <RectangleOverlay
            detectedRectangle={detectedRectangle}
            previewRatio={previewSize}
            backgroundColor="rgba(255,181,6, 0.2)"
            borderColor="rgb(255,181,6)"
            borderWidth={4}
            detectedBackgroundColor="rgba(255,181,6, 0.3)"
            detectedBorderWidth={6}
            detectedBorderColor="rgb(255,218,124)"
            onDetectedCapture={this.capture}
            allowDetection
          />
        )}

        {/* <FlashAnimation overlayFlashOpacity={flashScreenOnCaptureAnimation} /> */}

        {loadingCamera && (
          <View style={styles.overlay}>
            <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
              <ActivityIndicator color="white" />
              <Text style={styles.loadingCameraMessage}>Loading Camera</Text>
            </View>
          </View>
        )}

        {processingImage && (
          <View style={styles.overlay}>
            <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
              <View style={{ alignItems: 'center', justifyContent: 'center', height: 140, width: 200, borderRadius: 16, backgroundColor: 'rgba(220, 220, 220, 0.7)' }}>
                <ActivityIndicator color="#333333" size="large" />
                <Text style={{ color: '#333333', fontSize: 30, marginTop: 10 }}>Processing</Text>
              </View>
            </View>
          </View>
        )}

        <CameraControls
          closeScanner={closeScanner}
          capture={capture}
          isCapturing={processingImage}
          flashIsAvailable={flashIsAvailable}
          flashOn={flashOn}
          setFlashOn={setFlashOn}
          filterId={filterId}
          setFilterId={setFilterId}
        />
      </View>
    );
  }

  return (
    <View style={styles.cameraNotAvailableContainer}>
      <View style={styles.buttonBottomContainer}>
        <View style={styles.buttonGroup}>
          <TouchableOpacity style={styles.button} onPress={closeScanner}>
            <Text style={styles.buttonText}>Cancel</Text>
          </TouchableOpacity>
        </View>
      </View>
      <View style={styles.overlay}>
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
          <ActivityIndicator color="white" />
          <Text style={styles.loadingCameraMessage}>{cameraError ? cameraError : 'Loading Camera'}</Text>
        </View>
      </View>
    </View>
  );
}

export default DocumentScanner;