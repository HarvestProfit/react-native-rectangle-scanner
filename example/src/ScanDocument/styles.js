import { StyleSheet } from "react-native";

export const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'black',
  },
  overlay: {
    flex: 1,
    position: 'absolute',
    top: 0,
    bottom: 0,
    right: 0,
    left: 0,
  },
  buttonBottomContainer: {
    position: 'absolute',
    bottom: 40,
    left: 25,
    right: 25,
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    flexDirection: 'row',
  },
  buttonTopContainer: {
    position: 'absolute',
    top: 40,
    left: 25,
    right: 25,
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    flexDirection: 'row',
  },
  buttonContainer: {
    position: 'absolute',
    right: 25,
    top: 25,
    bottom: 25,
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    flexDirection: 'column',
  },
  buttonActionGroup: {
    flex: 1,
    justifyContent: 'space-between',
    flexDirection: 'column',
  },
  cameraOutline: {
    borderWidth: 3,
    borderColor: 'white',
    borderRadius: 50,
    height: 70,
    width: 70,
  },
  cameraButton: {
    backgroundColor: 'white',
    borderRadius: 50,
    margin: 3,
    flex: 1,
  },
  buttonGroup: {
    backgroundColor: '#00000080',
    borderRadius: 17,
  },
  button: {
    alignItems: 'center',
    justifyContent: 'center',
    height: 70,
    width: 65,
  },
  buttonText: {
    color: 'white',
    fontSize: 13,
  },
  buttonIcon: {
    color: 'white',
    fontSize: 22,
    marginBottom: 3,
    textAlign: 'center',
  },
  scanner: {
    flex: 1,
  },
  cameraNotAvailableContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    marginHorizontal: 2,
  },
  cameraNotAvailableText: {
    color: 'white',
    fontSize: 25,
    textAlign: 'center',
  },
  loadingCameraMessage: {
    marginTop: 10,
    color: 'white',
    fontSize: 18,
    textAlign: 'center',
  },
});