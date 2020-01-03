import { PropTypes } from 'prop-types'
import React, { PureComponent } from 'react'
import { ActivityIndicator, Animated, Dimensions, Platform, SafeAreaView, StatusBar, StyleSheet, Text, TouchableOpacity, View } from 'react-native'
import Icon from 'react-native-vector-icons/Ionicons'

import styleVariables from '../../styles/Variables'
import RectangleOverlay from './RectangleOverlay'
import Scanner from './Scanner'
import ScannerFilters, { COLOR_FILTER, IOS_PHOTO_FILTER } from './ScannerFilters'

const styles = StyleSheet.create({
  button: {
    alignItems: 'center',
    height: 70,
    justifyContent: 'center',
    width: 65
  },
  buttonActionGroup: {
    flex: 1,
    flexDirection: 'column',
    justifyContent: 'space-between'
  },
  buttonBottomContainer: {
    alignItems: 'flex-end',
    bottom: 40,
    flexDirection: 'row',
    justifyContent: 'space-between',
    left: 25,
    position: 'absolute',
    right: 25
  },
  buttonContainer: {
    alignItems: 'flex-end',
    bottom: 25,
    flexDirection: 'column',
    justifyContent: 'space-between',
    position: 'absolute',
    right: 25,
    top: 25
  },
  buttonGroup: {
    backgroundColor: '#00000080',
    borderRadius: 17
  },
  buttonIcon: {
    color: 'white',
    fontSize: 22,
    marginBottom: 3,
    textAlign: 'center'
  },
  buttonText: {
    color: 'white',
    fontSize: 13
  },
  buttonTopContainer: {
    alignItems: 'flex-start',
    flexDirection: 'row',
    justifyContent: 'space-between',
    left: 25,
    position: 'absolute',
    right: 25,
    top: 40
  },
  cameraButton: {
    backgroundColor: 'white',
    borderRadius: 50,
    flex: 1,
    margin: 3
  },
  cameraNotAvailableContainer: {
    alignItems: 'center',
    flex: 1,
    justifyContent: 'center',
    marginHorizontal: styleVariables.contentMargin
  },
  cameraNotAvailableText: {
    color: 'white',
    fontSize: 25,
    textAlign: 'center'
  },
  cameraOutline: {
    borderColor: 'white',
    borderRadius: 50,
    borderWidth: 3,
    height: 70,
    width: 70
  },
  container: {
    backgroundColor: 'black',
    flex: 1
  },
  flashControl: {
    alignItems: 'center',
    borderRadius: 30,
    height: 50,
    justifyContent: 'center',
    margin: 8,
    paddingTop: 7,
    width: 50
  },
  loadingCameraMessage: {
    color: 'white',
    fontSize: 18,
    marginTop: 10,
    textAlign: 'center'
  },
  loadingContainer: {
    alignItems: 'center', flex: 1, justifyContent: 'center'
  },
  overlay: {
    bottom: 0,
    flex: 1,
    left: 0,
    position: 'absolute',
    right: 0,
    top: 0
  },
  processingContainer: {
    alignItems: 'center',
    backgroundColor: 'rgba(220, 220, 220, 0.7)',
    borderRadius: 16,
    height: 140,
    justifyContent: 'center',
    width: 200
  },
  scanner: {
    flex: 1
  }
})

export default class DocumentScanner extends PureComponent {
  static propTypes = {
    cameraIsOn: PropTypes.bool,
    onLayout: PropTypes.func,
    onSkip: PropTypes.func,
    onCancel: PropTypes.func,
    onPictureTaken: PropTypes.func,
    onPictureProcessed: PropTypes.func,
    hideSkip: PropTypes.bool,
    initialFilterId: PropTypes.number,
    onFilterIdChange: PropTypes.func
  }

  static defaultProps = {
    cameraIsOn: undefined,
    onLayout: () => {},
    onSkip: () => {},
    onCancel: () => {},
    onPictureTaken: () => {},
    onPictureProcessed: () => {},
    onFilterIdChange: () => {},
    hideSkip: false,
    initialFilterId: Platform.OS === 'ios' ? IOS_PHOTO_FILTER.id : COLOR_FILTER.id
  }

  constructor (props) {
    super(props)
    this.state = {
      flashEnabled: false,
      showScannerView: false,
      didLoadInitialLayout: false,
      filterId: props.initialFilterId || Platform.OS === 'ios' ? IOS_PHOTO_FILTER.id : COLOR_FILTER.id,
      detectedRectangle: false,
      isMultiTasking: false,
      loadingCamera: true,
      processingImage: false,
      takingPicture: false,
      overlayFlashOpacity: new Animated.Value(0),
      device: {
        initialized: false,
        hasCamera: false,
        permissionToUseCamera: false,
        flashIsAvailable: false
      }
    }

    this.camera = React.createRef()
    this.imageProcessorTimeout = null
  }

  componentDidMount () {
    if (this.state.didLoadInitialLayout && !this.state.isMultiTasking) {
      this.turnOnCamera()
    }
  }

  componentDidUpdate () {
    if (this.state.didLoadInitialLayout) {
      if (this.state.isMultiTasking) return this.turnOffCamera(true)
      if (this.state.device.initialized) {
        if (!this.state.device.hasCamera) return this.turnOffCamera()
        if (!this.state.device.permissionToUseCamera) return this.turnOffCamera()
      }

      if (this.props.cameraIsOn === true && !this.state.showScannerView) {
        return this.turnOnCamera()
      }

      if (this.props.cameraIsOn === false && this.state.showScannerView) {
        return this.turnOffCamera(true)
      }

      if (this.props.cameraIsOn === undefined) {
        return this.turnOnCamera()
      }
    }
    return null
  }

  componentWillUnmount () {
    clearTimeout(this.imageProcessorTimeout)
  }

  onDeviceSetup = (deviceDetails) => {
    const { hasCamera, permissionToUseCamera, flashIsAvailable } = deviceDetails
    this.setState({
      loadingCamera: false,
      device: {
        initialized: true,
        hasCamera,
        permissionToUseCamera,
        flashIsAvailable
      }
    })
  }

  onFilterIdChange = (id) => {
    this.setState({ filterId: id })
    this.props.onFilterIdChange(id)
  }

  getCameraDisabledMessage () {
    if (this.state.isMultiTasking) {
      return 'Camera is not allowed in multi tasking mode.'
    }

    const { device } = this.state
    if (device.initialized) {
      if (!device.hasCamera) {
        return 'Could not find a camera on the device.'
      }
      if (!device.permissionToUseCamera) {
        return 'Permission to use camera has not been granted.'
      }
    }
    return 'Failed to set up the camera.'
  }

  capture = () => {
    if (this.state.takingPicture) return
    if (this.state.processingImage) return
    this.setState({ takingPicture: true, processingImage: true })
    this.camera.current.capture()
    this.triggerSnapAnimation()

    // If capture failed, allow for additional captures
    this.imageProcessorTimeout = setTimeout(() => {
      if (this.state.takingPicture) {
        this.setState({ takingPicture: false })
      }
    }, 100)
  }

  onPictureTaken = (event) => {
    this.setState({ takingPicture: false })
    this.props.onPictureTaken(event)
  }

  onPictureProcessed = (event) => {
    this.props.onPictureProcessed(event)
    this.setState({
      takingPicture: false,
      processingImage: false,
      showScannerView: this.props.cameraIsOn || false
    })
  }

  triggerSnapAnimation () {
    Animated.sequence([
      Animated.timing(this.state.overlayFlashOpacity, { toValue: 0.2, duration: 100 }),
      Animated.timing(this.state.overlayFlashOpacity, { toValue: 0, duration: 50 }),
      Animated.timing(this.state.overlayFlashOpacity, { toValue: 0.6, delay: 100, duration: 120 }),
      Animated.timing(this.state.overlayFlashOpacity, { toValue: 0, duration: 90 })
    ]).start()
  }

  turnOffCamera (shouldUninitializeCamera = false) {
    if (shouldUninitializeCamera && this.state.device.initialized) {
      this.setState(({ device }) => ({
        showScannerView: false,
        device: { ...device, initialized: false }
      }))
    } else if (this.state.showScannerView) {
      this.setState({ showScannerView: false })
    }
  }

  turnOnCamera () {
    if (!this.state.showScannerView) {
      this.setState({
        showScannerView: true,
        loadingCamera: true
      })
    }
  }

  renderFlashControl () {
    const { flashEnabled, device } = this.state
    if (!device.flashIsAvailable) return null
    return (
      <TouchableOpacity
        style={[styles.flashControl, { backgroundColor: flashEnabled ? '#FFFFFF80' : '#00000080' }]}
        activeOpacity={0.8}
        onPress={() => this.setState({ flashEnabled: !flashEnabled })}
      >
        <Icon name="ios-flashlight" style={[styles.buttonIcon, { fontSize: 28, color: flashEnabled ? '#333' : '#FFF' }]} />
      </TouchableOpacity>
    )
  }

  renderCameraControls () {
    const dimensions = Dimensions.get('window')
    const aspectRatio = dimensions.height / dimensions.width
    const isPhone = aspectRatio > 1.6
    const cameraIsDisabled = this.state.takingPicture || this.state.processingImage
    const disabledStyle = { opacity: cameraIsDisabled ? 0.8 : 1 }
    if (!isPhone) {
      if (dimensions.height < 500) {
        return (
          <View style={styles.buttonContainer}>
            <View style={[styles.buttonActionGroup, { flexDirection: 'row', alignItems: 'flex-end', marginBottom: 28 }]}>
              {this.renderFlashControl()}
              <ScannerFilters
                filterId={this.state.filterId}
                onFilterIdChange={this.onFilterIdChange}
              />
              {this.props.hideSkip ? null : (
                <View style={[styles.buttonGroup, { marginLeft: 8 }]}>
                  <TouchableOpacity
                    style={[styles.button, disabledStyle]}
                    onPress={cameraIsDisabled ? () => null : this.props.onSkip}
                    activeOpacity={0.8}
                  >
                    <Icon name="md-arrow-round-forward" size={40} color="white" style={styles.buttonIcon} />
                    <Text style={styles.buttonText}>Skip</Text>
                  </TouchableOpacity>
                </View>
              )}
            </View>
            <View style={[styles.cameraOutline, disabledStyle]}>
              <TouchableOpacity
                activeOpacity={0.8}
                style={styles.cameraButton}
                onPress={this.capture}
              />
            </View>
            <View style={[styles.buttonActionGroup, { marginTop: 28 }]}>
              <View style={styles.buttonGroup}>
                <TouchableOpacity
                  style={styles.button}
                  onPress={this.props.onCancel}
                  activeOpacity={0.8}
                >
                  <Icon name="ios-close-circle" size={40} style={styles.buttonIcon} />
                  <Text style={styles.buttonText}>Cancel</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        )
      }
      return (
        <View style={styles.buttonContainer}>
          <View style={[styles.buttonActionGroup, { justifyContent: 'flex-end', marginBottom: 20 }]}>
            {this.renderFlashControl()}
            <ScannerFilters
              filterId={this.state.filterId}
              onFilterIdChange={this.onFilterIdChange}
            />
          </View>
          <View style={[styles.cameraOutline, disabledStyle]}>
            <TouchableOpacity
              activeOpacity={0.8}
              style={styles.cameraButton}
              onPress={this.capture}
            />
          </View>
          <View style={[styles.buttonActionGroup, { marginTop: 28 }]}>
            <View style={styles.buttonGroup}>
              {this.props.hideSkip ? null : (
                <TouchableOpacity
                  style={[styles.button, disabledStyle]}
                  onPress={cameraIsDisabled ? () => null : this.props.onSkip}
                  activeOpacity={0.8}
                >
                  <Icon name="md-arrow-round-forward" size={40} color="white" style={styles.buttonIcon} />
                  <Text style={styles.buttonText}>Skip</Text>
                </TouchableOpacity>
              )}
            </View>
            <View style={styles.buttonGroup}>
              <TouchableOpacity
                style={styles.button}
                onPress={this.props.onCancel}
                activeOpacity={0.8}
              >
                <Icon name="ios-close-circle" size={40} style={styles.buttonIcon} />
                <Text style={styles.buttonText}>Cancel</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      )
    }

    return (
      <>
        <View style={styles.buttonBottomContainer}>
          <View style={styles.buttonGroup}>
            <TouchableOpacity
              style={styles.button}
              onPress={this.props.onCancel}
              activeOpacity={0.8}
            >
              <Icon name="ios-close-circle" size={40} style={styles.buttonIcon} />
              <Text style={styles.buttonText}>Cancel</Text>
            </TouchableOpacity>
          </View>
          <View style={[styles.cameraOutline, disabledStyle]}>
            <TouchableOpacity
              activeOpacity={0.8}
              style={styles.cameraButton}
              onPress={this.capture}
            />
          </View>
          <View>
            <View style={[styles.buttonActionGroup, { justifyContent: 'flex-end', marginBottom: this.props.hideSkip ? 0 : 16 }]}>
              <ScannerFilters
                filterId={this.state.filterId}
                onFilterIdChange={this.onFilterIdChange}
              />
              {this.renderFlashControl()}
            </View>
            <View style={styles.buttonGroup}>
              {this.props.hideSkip ? null : (
                <TouchableOpacity
                  style={[styles.button, disabledStyle]}
                  onPress={cameraIsDisabled ? () => null : this.props.onSkip}
                  activeOpacity={0.8}
                >
                  <Icon name="md-arrow-round-forward" size={40} color="white" style={styles.buttonIcon} />
                  <Text style={styles.buttonText}>Skip</Text>
                </TouchableOpacity>
              )}
            </View>
          </View>
        </View>
      </>
    )
  }

  renderCameraOverlay () {
    let loadingState = null
    if (this.state.loadingCamera) {
      loadingState = (
        <View style={styles.overlay}>
          <View style={styles.loadingContainer}>
            <ActivityIndicator color="white" />
            <Text style={styles.loadingCameraMessage}>Loading Camera</Text>
          </View>
        </View>
      )
    } else if (this.state.processingImage) {
      loadingState = (
        <View style={styles.overlay}>
          <View style={styles.loadingContainer}>
            <View style={styles.processingContainer}>
              <ActivityIndicator color="#333333" size="large" />
              <Text style={{ color: '#333333', fontSize: 30, marginTop: 10 }}>Processing</Text>
            </View>
          </View>
        </View>
      )
    }

    return (
      <>
        {loadingState}
        <SafeAreaView style={[styles.overlay]}>
          {this.renderCameraControls()}
        </SafeAreaView>
      </>
    )
  }

  renderCameraView () {
    if (this.state.showScannerView) {
      let rectangleOverlay = null
      if (!this.state.loadingCamera && !this.state.processingImage) {
        rectangleOverlay = (
          <RectangleOverlay
            detectedRectangle={this.state.detectedRectangle}
          />
        )
      }
      return (
        <>
          <Scanner
            onPictureTaken={this.onPictureTaken}
            onPictureProcessed={this.onPictureProcessed}
            enableTorch={this.state.flashEnabled}
            filterId={this.state.filterId}
            ref={this.camera}
            capturedQuality={0.6}
            onRectangleDetected={({ detectedRectangle }) => this.setState({ detectedRectangle })}
            onDeviceSetup={this.onDeviceSetup}
            onTorchChanged={({ enabled }) => this.setState({ flashEnabled: enabled })}
            style={styles.scanner}
          />
          {rectangleOverlay}
          <Animated.View style={{ ...styles.overlay, backgroundColor: 'white', opacity: this.state.overlayFlashOpacity }} />
          {this.renderCameraOverlay()}
        </>
      )
    }

    let message = null
    if (this.state.loadingCamera) {
      message = (
        <View style={styles.overlay}>
          <View style={styles.loadingContainer}>
            <ActivityIndicator color="white" />
            <Text style={styles.loadingCameraMessage}>Loading Camera</Text>
          </View>
        </View>
      )
    } else {
      message = (
        <Text style={styles.cameraNotAvailableText}>
          {this.getCameraDisabledMessage()}
        </Text>
      )
    }

    return (
      <View style={styles.cameraNotAvailableContainer}>
        {message}
        <View style={styles.buttonBottomContainer}>
          <View style={styles.buttonGroup}>
            <TouchableOpacity
              style={styles.button}
              onPress={this.props.onCancel}
              activeOpacity={0.8}
            >
              <Icon name="ios-close-circle" size={40} style={styles.buttonIcon} />
              <Text style={styles.buttonText}>Cancel</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.buttonGroup}>
            {this.props.hideSkip ? null : (
              <TouchableOpacity
                style={[styles.button, { marginTop: 8 }]}
                onPress={this.props.onSkip}
                activeOpacity={0.8}
              >
                <Icon name="md-arrow-round-forward" size={40} color="white" style={styles.buttonIcon} />
                <Text style={styles.buttonText}>Skip</Text>
              </TouchableOpacity>
            )}
          </View>
        </View>
      </View>

    )
  }

  render () {
    return (
      <View
        style={styles.container}
        onLayout={(event) => {
          this.props.onLayout(event)
          if (this.state.didLoadInitialLayout && Platform.OS === 'ios') {
            const screenWidth = Dimensions.get('screen').width
            const isMultiTasking = (
              Math.round(event.nativeEvent.layout.width) < Math.round(screenWidth)
            )
            if (isMultiTasking) {
              this.setState({ isMultiTasking: true, loadingCamera: false })
            } else {
              this.setState({ isMultiTasking: false })
            }
          } else {
            this.setState({ didLoadInitialLayout: true })
          }
        }}
      >
        <StatusBar backgroundColor="black" barStyle="light-content" hidden={Platform.OS !== 'android'} />
        {this.renderCameraView()}
      </View>
    )
  }
}
