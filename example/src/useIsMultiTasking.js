import { Dimensions, useWindowDimensions } from "react-native";

// return true when the device goes into multi-tasking view (the window width will be less than the screen width)
export default function () {
  const { width, height } = useWindowDimensions();
  const screenWidth = Math.round(Dimensions.get('screen').width);
  const screenHeight = Math.round(Dimensions.get('screen').height);

  return (width < screenWidth);
}