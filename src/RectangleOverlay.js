import { PropTypes } from 'prop-types';
import React, { Component } from 'react';
import { Dimensions, View } from 'react-native';
import { Svg, Path } from 'react-native-svg';

function getDifferenceBetweenRectangles(firstRectangle, secondRectangle) {
  const topRightXDiff = Math.abs(firstRectangle.topRight.x - secondRectangle.topRight.x);
  const topRightYDiff = Math.abs(firstRectangle.topRight.y - secondRectangle.topRight.y);

  const topLeftXDiff = Math.abs(firstRectangle.topLeft.x - secondRectangle.topLeft.x);
  const topLeftYDiff = Math.abs(firstRectangle.topLeft.y - secondRectangle.topLeft.y);

  const bottomRightXDiff = Math.abs(firstRectangle.bottomRight.x - secondRectangle.bottomRight.x);
  const bottomRightYDiff = Math.abs(firstRectangle.bottomRight.y - secondRectangle.bottomRight.y);

  const bottomLeftXDiff = Math.abs(firstRectangle.bottomLeft.x - secondRectangle.bottomLeft.x);
  const bottomLeftYDiff = Math.abs(firstRectangle.bottomLeft.y - secondRectangle.bottomLeft.y);

  return (
    topRightXDiff + topRightYDiff
    + topLeftXDiff + topLeftYDiff
    + bottomRightXDiff + bottomRightYDiff
    + bottomLeftXDiff + bottomLeftYDiff
  );
}

export default class RectangleOverlay extends Component {
  static propTypes = {
    // The rectangle from the scanner native component
    detectedRectangle: PropTypes.oneOfType([PropTypes.shape({
      topRight: PropTypes.shape({ x: PropTypes.number, y: PropTypes.number }),
      topLeft: PropTypes.shape({ x: PropTypes.number, y: PropTypes.number }),
      bottomRight: PropTypes.shape({ x: PropTypes.number, y: PropTypes.number }),
      bottomLeft: PropTypes.shape({ x: PropTypes.number, y: PropTypes.number }),
      dimensions: PropTypes.shape({ height: PropTypes.number, width: PropTypes.number }),
    }), PropTypes.bool]),

    // The preview ratio from the scanner native component (or just 100%x100%)
    previewRatio: PropTypes.shape({
      height: PropTypes.number,
      width: PropTypes.number,
    }),

    backgroundColor: PropTypes.string, // The background fill of the rectangle overlay
    borderColor: PropTypes.string, // The border color of the rectangle overlay
    borderWidth: PropTypes.number, // The border width of the rectangle overlay


    allowDetection: PropTypes.bool, // Finds difference between current and previous rectangle
    onDetectedCapture: PropTypes.func, // A function to call when it has detected a desired rectangle

    detectedBackgroundColor: PropTypes.string, // Background fill of rectangle overlay when it has detected the desired rectangle
    detectedBorderColor: PropTypes.string, // Border color of rectangle overlay when it has detected the desired rectangle
    detectedBorderWidth: PropTypes.number, // Border width of rectangle overlay when it has detected the desired rectangle

    rectangleDifferenceAllowance: PropTypes.number, // The amount of difference allowed between the difference of all the points of the rectangle
    detectionCountBeforeCapture: PropTypes.number, // The amount of similar rectangles before onDetectedCapture is called
    detectionCountBeforeUIChange: PropTypes.number, // The amount of similar rectangles before detected styles are used
  };

  static defaultProps = {
    rectangleDifferenceAllowance: 50,
    detectionCountBeforeCapture: 8,
    detectionCountBeforeUIChange: 3,
    detectedRectangle: false,
    backgroundColor: 'rgba(255,203,6, 0.3)',
    borderColor: 'rgb(255,203,6)',
    borderWidth: 5,
    detectedBackgroundColor: null,
    detectedBorderColor: null,
    detectedBorderWidth: null,
    previewRatio: {
      height: 1,
      width: 1,
    },
    onDetectedCapture: null,
    allowDetection: false,
  };

  static getDerivedStateFromProps(newProps, oldState) {
    if (newProps.allowDetection && newProps.detectedRectangle && oldState.lastRectangle) {
      const newRectangle = newProps.detectedRectangle;
      const oldRectangle = oldState.lastRectangle;

      const diff = getDifferenceBetweenRectangles(newRectangle, oldRectangle);

      let detectionCount = oldState.detectionCount + 1;
      if (diff > newProps.rectangleDifferenceAllowance) detectionCount = 0;
      return {
        lastRectangle: newRectangle,
        detectionCount,
      };
    }
    return {
      lastRectangle: newProps.detectedRectangle,
      detectionCount: 0,
    };
  }

  constructor(props) {
    super(props);

    this.state = {
      lastRectangle: null,
      detectionCount: 0,
    };
  }

  componentDidUpdate() {
    if (!this.props.onDetectedCapture) return;
    if (!this.foundRectangle(this.props.detectionCountBeforeCapture)) return;
    this.setState({
      lastRectangle: null,
      detectionCount: 0,
    });
    this.props.onDetectedCapture();
  }

  foundRectangle(detectionCount) {
    if (this.state.detectionCount < detectionCount) return false;
    return true;
  }

  render() {
    const {
      previewRatio,
      detectedRectangle,
      backgroundColor,
      borderColor,
      borderWidth,
      detectedBackgroundColor,
      detectedBorderColor,
      detectedBorderWidth,
    } = this.props;
    if (!detectedRectangle) return null;
    const {
      topRight,
      topLeft,
      bottomRight,
      bottomLeft,
      dimensions,
    } = detectedRectangle;
    const deviceWindow = Dimensions.get('window');
    const commands = [];
    const plotCoordNode = (cmds, point, svgCMD) => { cmds.push(`${svgCMD}${point.x},${point.y} `); };
    plotCoordNode(commands, topLeft, 'M');
    plotCoordNode(commands, bottomLeft, 'L');
    plotCoordNode(commands, bottomRight, 'L');
    plotCoordNode(commands, topRight, 'L');
    commands.push('Z');
    const d = commands.join(' ');

    let stroke = borderColor;
    let fill = backgroundColor;
    let strokeWidth = borderWidth;

    // adjust styles for initial detection
    if (this.foundRectangle(this.props.detectionCountBeforeUIChange)) {
      stroke = detectedBorderColor || borderColor;
      fill = detectedBackgroundColor || backgroundColor;
      strokeWidth = detectedBorderWidth || borderWidth;
    }

    return (
      <View style={{ position: 'absolute', top: 0, bottom: 0, right: 0, left: 0, backgroundColor: 'rgba(0,0,0,0)' }}>
        <Svg height={deviceWindow.height * previewRatio.height} width={deviceWindow.width * previewRatio.width} viewBox={`0 0 ${dimensions.width} ${dimensions.height}`}>
          <Path
            d={d}
            style={{ fill, stroke, strokeWidth, strokeLinejoin: 'round', strokeLinecap: 'round' }}
          />
        </Svg>
      </View>
    );
  }
}
