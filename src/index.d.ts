
declare module 'react-native-rectangle-scanner' {
  import { ComponentClass } from 'react';
  import { ViewProps, Animated } from 'react-native';

  export interface PictureCallbackProps {
    croppedImage: string,
    initialImage: string,
  }

  export interface DeviceSetupCallbackProps {
    hasCamera: boolean,
    permissionToUseCamera: boolean,
    flashIsAvailable: boolean,
    previewHeightPercent: number,
    previewWidthPercent: number,
  }

  export interface Coordinate {
    x: number,
    y: number,
  }

  export interface DetectedRectangle {
    bottomLeft: Coordinate,
    bottomRight: Coordinate,
    topLeft: Coordinate,
    topRight: Coordinate,
    dimensions: {
      height: number,
      width: number,
    }
  }

  export interface TorchCallbackProps {
    enabled: boolean
  }

  export interface Filter {
    id: number,
    name: string
  }

  export interface AndroidPermissionObject {
    title: string,
    message: string,
    buttonNegative: string,
    buttonPositive: string,
  }

  export interface ScannerComponentProps extends ViewProps {
    onPictureTaken?: (args: PictureCallbackProps) => void,
    onPictureProcessed?: (args: PictureCallbackProps) => void,
    onDeviceSetup?: (args: DeviceSetupCallbackProps) => void,
    onRectangleDetected?: (args: { detectedRectangle: DetectedRectangle }) => void,
    onTorchChanged?: (args: TorchCallbackProps) => void,
    onErrorProcessingImage?: (args: PictureCallbackProps) => void,
    filterId?: number,
    enableTorch?: boolean,
    capturedQuality?: number,
    styles?: object,
    androidPermission?: AndroidPermissionObject | boolean,
  }

  export interface RectangleOverlayComponentProps extends ViewProps {
    detectedRectangle?: DetectedRectangle,
    previewRatio?: { height: number, width: number },
    backgroundColor?: string,
    borderColor?: string,
    borderWidth?: number,
    detectedBackgroundColor?: string,
    detectedBorderColor?: string,
    detectedBorderWidth?: number,
    rectangleDifferenceAllowance?: number,
    detectionCountBeforeCapture?: number,
    detectionCountBeforeUIChange?: number,
    allowDetection?: boolean,
    onDetectedCapture?: () => void,
  }

  export interface FlashAnimationComponentProps extends ViewProps {
    overlayFlashOpacity: Animated.Value,
  }

  const Scanner: ComponentClass<ScannerComponentProps>;

  export const RectangleOverlay: ComponentClass<RectangleOverlayComponentProps>;
  export const FlashAnimation: ComponentClass<FlashAnimationComponentProps>;
  export const Filters: {
    PHOTO_FILTER: Filter,
    GREYSCALE_FILTER: Filter,
    COLOR_FILTER: Filter,
    BLACK_AND_WHITE_FILTER: Filter,
    RECOMMENDED_PLATFORM_FILTERS: Filter[],
    PLATFORM_DEFAULT_FILTER_ID: number,
  }

  export default Scanner;
}
