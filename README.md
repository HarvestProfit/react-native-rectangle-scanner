![Demo gif](images/demo.gif)
# `react-native-rectangle-scanner`

![Supports Android and iOS](https://img.shields.io/badge/platforms-android%20|%20ios%20-lightgrey.svg) ![MIT License](https://img.shields.io/npm/l/@react-native-community/netinfo.svg)

Live photo rectangle detection library useful for scanning documents. On capture, it returns the URIs for the original and a cropped version of the image allowing you to use the images as you want. You can additionally apply filters to adjust the visibility of text on the image (similar to the iOS document scanner filters).

- Live detection
- Perspective correction and crop of the image
- Filters
- Flash
- Orientation Changes
- Camera permission and capabilities detection
- Fully customizable UI

## Getting started

Install the library using either yarn:

```sh
yarn add react-native-rectangle-scanner`
```

or npm:

```sh
npm install react-native-rectangle-scanner --save
```

This package can be ran on a simulator, android simulators work a bit better, iOS simulators will simply return `false` for `hasCamera` on device setup.

### iOS Only

CocoaPods on iOS needs this extra step:

```sh
cd ios && pod install && cd ..
```

### Android Only

If you do not have it already in your project, you must link openCV in your `settings.gradle` file

```java
include ':openCVLibrary310'
project(':openCVLibrary310').projectDir = new File(rootProject.projectDir,'../node_modules//react-native-rectangle-scanner/android/openCVLibrary310')
```

#### In android/app/src/main/AndroidManifest.xml

Add Camera permissions request:

```
<uses-permission android:name="android.permission.CAMERA" />
```

## Usage

This is the most barebones usage of this. It will show a fullscreen camera preview with no controls on it. Calling `this.camera.current.capture()` will trigger a capture and after the image has been captured and processed (cropped, filtered, stored/cached), it will trigger the `onPictureProcessed` callback.


```javascript
import React, { Component, useRef } from "react"
import { View, Image } from "react-native"

import Scanner from "react-native-rectangle-scanner"

class DocumentScanner extends Component {

  handleOnPictureProcessed = ({croppedImage, initialImage}) => {
    this.props.doSomethingWithCroppedImagePath(croppedImage);
    this.props.doSomethingWithOriginalImagePath(initialImage);
  }

  onCapture = () => {
    this.camera.current.capture();
  }

  render() {
    return (
      <Scanner
        onPictureProcessed={this.handleOnPictureProcessed}
        ref={this.camera}
        style={{flex: 1}}
      />
    );
  }
}
```

Full example in [example folder](https://github.com/Woonivers/react-native-document-scanner/tree/master/example).

## Properties

| Prop                        | Platform | Default |   Type    | Description                                                         |
| :-------------------------- | :------: | :-----: | :-------: | :------------------------------------------------------------------ |
| overlayColor                |   Both   | `none`  | `string`  | Color of the detected rectangle : rgba recommended                  |
| detectionCountBeforeCapture |   Both   |   `5`   | `integer` | Number of correct rectangle to detect before capture                |
| detectionRefreshRateInMS    |   iOS    |  `50`   | `integer` | Time between two rectangle detection attempt                        |
| enableTorch                 |   Both   | `false` |  `bool`   | Allows to active or deactivate flash during document detection      |
| useFrontCam                 |   iOS    | `false` |  `bool`   | Allows you to switch between front and back camera                  |
| brightness                  |   iOS    |   `0`   |  `float`  | Increase or decrease camera brightness. Normal as default.          |
| saturation                  |   iOS    |   `1`   |  `float`  | Increase or decrease camera saturation. Set `0` for black & white   |
| contrast                    |   iOS    |   `1`   |  `float`  | Increase or decrease camera contrast. Normal as default             |
| quality                     |   iOS    |  `0.8`  |  `float`  | Image compression. Reduces both image size and quality              |
| useBase64                   |   iOS    | `false` |  `bool`   | If base64 representation should be passed instead of image uri's    |
| saveInAppDocument           |   iOS    | `false` |  `bool`   | If should save in app document in case of not using base 64         |
| captureMultiple             |   iOS    | `false` |  `bool`   | Keeps the scanner on after a successful capture                     |
| saveOnDevice                | Android  | `false` |  `bool`   | Save the image in the device storage (**Need storage permissions**) |

## Manual capture

- First create a mutable ref object:

```javascript
const documentScannerElement = useRef(null)
```

- Pass a ref object to your component:

```javascript
<DocumentScanner ref={documentScannerElement} />
```

- Then call:

```javascript
documentScannerElement.current.capture()
```

## Each rectangle detection (iOS only) _-Non tested-_

| Props             | Params                                 | Type     | Description |
| ----------------- | -------------------------------------- | -------- | ----------- |
| onRectangleDetect | `{ stableCounter, lastDetectionType }` | `object` | See below   |

The returned object includes the following keys :

- `stableCounter`

Number of correctly formated rectangle found (this number triggers capture once it goes above `detectionCountBeforeCapture`)

- `lastDetectionType`

Enum (0, 1 or 2) corresponding to the type of rectangle found

0. Correctly formated rectangle
1. Wrong perspective, bad angle
1. Too far

## Returned image

| Prop           | Params |   Type   | Description                                                                                                                                                                         |
| :------------- | :----: | :------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| onPictureTaken | `data` | `object` | Returns the captured image in an object `{ croppedImage: ('URI or BASE64 string'), initialImage: 'URI or BASE64 string', rectangleCoordinates[only iOS]: 'object of coordinates' }` |

## Save in app document _-Non tested-_

If you want to use saveInAppDocument options, then don't forget to add those raws in .plist :

```xml
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

# Contributors

## Set up dev environment

[Medium article](https://medium.com/@charpeni/setting-up-an-example-app-for-your-react-native-library-d940c5cf31e4)
