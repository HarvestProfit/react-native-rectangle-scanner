import React from 'react'
import { DeviceEventEmitter, NativeModules, Platform, requireNativeComponent } from 'react-native'

const RNPdfScanner = requireNativeComponent('RNPdfScanner')
const CameraManager = NativeModules.RNPdfScannerManager || {}

interface PdfScannerProps {
  onPictureTaken: (event: any) => void;
  onRectangleDetect: (event: any) => void;
  onProcessing: () => void;
  quality: number;
  overlayColor: number | string;
  enableTorch: boolean;
  useFrontCam: boolean;
  saturation: number;
  brightness: number;
  contrast: number;
  detectionCountBeforeCapture: number;
  detectionRefreshRateInMS: number;
  documentAnimation: boolean;
  noGrayScale: boolean;
  manualOnly: boolean;
}

class PdfScanner extends React.Component<PdfScannerProps> {
  sendOnPictureTakenEvent (event: any) {
    return this.props.onPictureTaken(event.nativeEvent)
  }

  sendOnRectangleDetectEvent (event: any) {
    if (!this.props.onRectangleDetect) return null
    return this.props.onRectangleDetect(event.nativeEvent)
  }

  getImageQuality () {
    if (!this.props.quality) return 0.8
    if (this.props.quality > 1) return 1
    if (this.props.quality < 0.1) return 0.1
    return this.props.quality
  }

  componentWillMount () {
    if (Platform.OS === 'android') {
      const { onPictureTaken, onProcessing } = this.props
      DeviceEventEmitter.addListener('onPictureTaken', onPictureTaken)
      DeviceEventEmitter.addListener('onProcessingChange', onProcessing)
    }
  }

  componentWillUnmount () {
    if (Platform.OS === 'android') {
      const { onPictureTaken, onProcessing } = this.props
      DeviceEventEmitter.removeListener('onPictureTaken', onPictureTaken)
      DeviceEventEmitter.removeListener('onProcessingChange', onProcessing)
    }
  }

  capture () {
    CameraManager.capture()
  }

  render () {
    return (
      <RNPdfScanner
        {...this.props}
        onPictureTaken={this.sendOnPictureTakenEvent.bind(this)}
        onRectangleDetect={this.sendOnRectangleDetectEvent.bind(this)}
        useFrontCam={this.props.useFrontCam || false}
        brightness={this.props.brightness || 0}
        saturation={this.props.saturation || 1}
        contrast={this.props.contrast || 1}
        quality={this.getImageQuality()}
        detectionCountBeforeCapture={this.props.detectionCountBeforeCapture || 5}
        detectionRefreshRateInMS={this.props.detectionRefreshRateInMS || 50}
      />
    )
  }
}

export default PdfScanner
