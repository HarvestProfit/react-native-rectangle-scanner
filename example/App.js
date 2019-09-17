import React, { useRef, useState } from "react"
import { StyleSheet, Text, TouchableOpacity, Image } from "react-native"
import PDFScanner from "@woonivers/react-native-document-scanner"

export default function App() {
  const pdfScannerElement = useRef(null)
  const [data, setData] = useState({})

  function handleOnPressRetry() {
    setData({})
  }
  function handleOnPress() {
    pdfScannerElement.current.capture()
  }
  if (data.croppedImage) {
    console.log("data", data)
    return (
      <React.Fragment>
        <Image source={{ uri: data.croppedImage }} style={styles.preview} />
        <TouchableOpacity onPress={handleOnPressRetry} style={styles.button}>
          <Text style={styles.buttonText}>Retry</Text>
        </TouchableOpacity>
      </React.Fragment>
    )
  }
  return (
    <React.Fragment>
      <PDFScanner
        ref={pdfScannerElement}
        style={styles.scanner}
        onPictureTaken={setData}
        overlayColor="rgba(255,130,0, 0.7)"
        enableTorch={false}
        brightness={0.3}
        saturation={1}
        contrast={1.1}
        quality={0.5}
        detectionCountBeforeCapture={5}
        detectionRefreshRateInMS={50}
        onPermissionsDenied={() => console.log("Permissions Denied")}
      />
      <TouchableOpacity onPress={handleOnPress} style={styles.button}>
        <Text style={styles.buttonText}>Take picture</Text>
      </TouchableOpacity>
    </React.Fragment>
  )
}

const styles = StyleSheet.create({
  scanner: {
    flex: 1,
    width: "100%",
  },
  button: {
    alignSelf: "center",
    position: "absolute",
    bottom: 32,
  },
  buttonText: {
    backgroundColor: "rgba(245, 252, 255, 0.7)",
    fontSize: 32,
  },
  preview: {
    flex: 1,
    width: "100%",
    resizeMode: "cover",
  },
})
