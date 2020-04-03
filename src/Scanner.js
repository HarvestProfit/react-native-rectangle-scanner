import { PropTypes } from 'prop-types';
import React from 'react';
import {
  NativeModules,
  Platform,
  requireNativeComponent,
  PermissionsAndroid,
} from 'react-native';

const RNRectangleScanner = requireNativeComponent('RNRectangleScanner');
const CameraManager = NativeModules.RNRectangleScannerManager || {};

class Scanner extends React.Component {
  static propTypes = {
    onPictureTaken: PropTypes.func,
    onPictureProcessed: PropTypes.func,
    capturedQuality: PropTypes.number,
    onDeviceSetup: PropTypes.func,
    onRectangleDetected: PropTypes.func,
    onTorchChanged: PropTypes.func,
    onErrorProcessingImage: PropTypes.func,
    androidPermission: PropTypes.oneOfType([PropTypes.bool, PropTypes.shape({
      title: PropTypes.string,
      message: PropTypes.string,
      buttonNegative: PropTypes.string,
      buttonPositive: PropTypes.string,
    })]),
  };

  static defaultProps = {
    onTorchChanged: null,
    onPictureTaken: null,
    onPictureProcessed: null,
    onDeviceSetup: null,
    onRectangleDetected: null,
    onErrorProcessingImage: null,
    capturedQuality: 0.5,
    androidPermission: {
      title: 'Permission to Access the Camera?',
      message: 'Allows you to scan documents',
      buttonNegative: "Don't Allow",
      buttonPositive: 'OK',
    },
  }

  constructor(props) {
    super(props);
  }

  componentDidMount() {
    if (Platform.OS === 'android') {
      this.askForAndroidCameraForPermission(this.start);
    } else {
      this.start();
    }
  }

  componentWillUnmount() {
    if (CameraManager.cleanup) CameraManager.cleanup();
  }

  getImageQuality() {
    if (!this.props.capturedQuality) return 0.8;
    if (this.props.capturedQuality > 1) return 1;
    if (this.props.capturedQuality < 0.1) return 0.1;
    return this.props.capturedQuality;
  }

  sendOnPictureTakenEvent = (event) => {
    if (!this.props.onPictureTaken) return null;
    return this.props.onPictureTaken(event.nativeEvent);
  }

  sendOnPictureProcessedEvent = (event) => {
    if (!this.props.onPictureProcessed) return null;
    return this.props.onPictureProcessed(event.nativeEvent);
  }

  sendOnErrorProcessingImage = (event) => {
    if (!this.props.onErrorProcessingImage) return null;
    return this.props.onErrorProcessingImage(event.nativeEvent);
  }

  sendOnRectangleDetectedEvent = (event) => {
    if (!this.props.onRectangleDetected) return null;
    let detectionPayload = event.nativeEvent;
    if (detectionPayload && detectionPayload.detectedRectangle === 0) {
      detectionPayload = {
        ...detectionPayload,
        detectedRectangle: false,
      };
    }
    return this.props.onRectangleDetected(detectionPayload);
  }

  sendOnDeviceSetupEvent = (event) => {
    if (!this.props.onDeviceSetup) return null;
    return this.props.onDeviceSetup(event.nativeEvent);
  }

  sendOnTorchChangedEvent = (event) => {
    if (!this.props.onTorchChanged) return null;
    return this.props.onTorchChanged(event.nativeEvent);
  }

  askForAndroidCameraForPermission = async (onComplete) => {
    if (!this.props.androidPermission) {
      if (onComplete) onComplete();
      return;
    }

    try {
      const granted = await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.CAMERA,
        this.props.androidPermission,
      );

      if (granted === PermissionsAndroid.RESULTS.GRANTED) {
        if (onComplete) onComplete();
      } else {
        this.sendOnDeviceSetupEvent({
          nativeEvent: { permissionToUseCamera: false, hasCamera: true },
        });
      }
    } catch (err) {
      this.sendOnDeviceSetupEvent({
        nativeEvent: {
          permissionToUseCamera: false, hasCamera: false,
        },
      });
    }
  }

  start = () => {
    setTimeout(() => {
      CameraManager.start();
    }, 10);
  }

  // eslint-disable-next-line
  capture() { CameraManager.capture(); }

  // eslint-disable-next-line
  refresh() { CameraManager.refresh(); }

  // eslint-disable-next-line
  focus() { CameraManager.focus(); }

  render() {
    return (
      <RNRectangleScanner
        {...this.props}
        onPictureTaken={this.sendOnPictureTakenEvent}
        onPictureProcessed={this.sendOnPictureProcessedEvent}
        onErrorProcessingImage={this.sendOnErrorProcessingImage}
        onRectangleDetected={this.sendOnRectangleDetectedEvent}
        onDeviceSetup={this.sendOnDeviceSetupEvent}
        onTorchChanged={this.sendOnTorchChangedEvent}
        capturedQuality={this.getImageQuality()}
      />
    );
  }
}

export default Scanner;
