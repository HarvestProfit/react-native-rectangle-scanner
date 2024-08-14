import React, { useState } from 'react';
import { Button, Text } from 'react-native';
import DocumentScanner from './DocumentScanner';
import useIsMultiTasking from '../useIsMultiTasking';
import { StatusBar } from 'expo-status-bar';

const ScanDocument = () => {

  const [scannerIsOn, setScannerIsOn] = useState(false);
  const [scannedImage, setScannedImage] = useState();

  const onScannedImage = ({ croppedImage }) => {
    console.log('scanned an image!');
    setScannedImage(croppedImage);
  }


  const isMultiTasking = useIsMultiTasking();

  if (isMultiTasking) return <Text>Not allowed while multi tasking</Text>;

  if (!scannerIsOn) {
    if (!scannedImage) {
      return <Button title="Tap to scan" onPress={() => setScannerIsOn(true)} />;
    } else {
      return <Text>Captured an image!</Text>
    }
  }


  return (
    <>
      <StatusBar animated={true} backgroundColor="black" barStyle="light-content" />
      <DocumentScanner
        closeScanner={() => setScannerIsOn(false)}
        onScannedImage={onScannedImage}
      />
    </>
  )
}

export default ScanDocument;