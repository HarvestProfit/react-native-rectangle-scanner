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

class PdfScanner extends React.Component {
  static propTypes = {
    onPictureTaken: PropTypes.func,
    onPictureProcessed: PropTypes.func,
    capturedQuality: PropTypes.number,
    onDeviceSetup: PropTypes.func,
    onRectangleDetected: PropTypes.func,
    onTorchChanged: PropTypes.func,
  };

  static defaultProps = {
    onTorchChanged: null,
    onPictureTaken: null,
    onPictureProcessed: null,
    onDeviceSetup: null,
    onRectangleDetected: null,
    capturedQuality: 0.5,
  }

  constructor(props) {
    super(props);

    this.cameraDidRespond = false;

    this.setupTimeout = null;
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
    clearTimeout(this.setupTimeout);
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
    this.cameraDidRespond = true;
    clearTimeout(this.setupTimeout);
    if (!this.props.onDeviceSetup) return null;
    return this.props.onDeviceSetup(event.nativeEvent);
  }

  sendOnTorchChangedEvent = (event) => {
    if (!this.props.onTorchChanged) return null;
    return this.props.onTorchChanged(event.nativeEvent);
  }

  askForAndroidCameraForPermission = async (onComplete) => {
    try {
      const granted = await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.CAMERA,
        {
          title: '"Driver" Would Like to Access the Camera?',
          message: 'Allows you to scan scale tickets.',
          buttonNegative: "Don't Allow",
          buttonPositive: 'OK',
        },
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
    clearTimeout(this.setupTimeout);
  }

  start = () => {
    setTimeout(() => {
      CameraManager.start();
      this.setupTimeout = setTimeout(() => {
        if (!this.cameraDidRespond) {
          this.sendOnDeviceSetupEvent({
            nativeEvent: {
              hasCamera: false,
              permissionToUseCamera: false,
            },
          });
        }
      }, 5000);
    }, 10);
  }

  // eslint-disable-next-line
  capture() { CameraManager.capture(); }

  // eslint-disable-next-line
  refresh() { CameraManager.refresh(); }

  render() {
    return (
      <RNRectangleScanner
        {...this.props}
        onPictureTaken={this.sendOnPictureTakenEvent}
        onPictureProcessed={this.sendOnPictureProcessedEvent}
        onRectangleDetected={this.sendOnRectangleDetectedEvent}
        onDeviceSetup={this.sendOnDeviceSetupEvent}
        onTorchChanged={this.sendOnTorchChangedEvent}
        capturedQuality={this.getImageQuality()}
      />
    );
  }
}

export default PdfScanner;
