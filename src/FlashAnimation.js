import { PropTypes } from 'prop-types';
import React, { Component } from 'react';
import { Animated, StyleSheet } from 'react-native';

const styles = StyleSheet.create({
  flashOverlay: {
    flex: 1,
    position: 'absolute',
    top: 0,
    bottom: 0,
    right: 0,
    left: 0,
    backgroundColor: 'white',
  },
});

export default class FlashAnimation extends Component {
  static propTypes = {
    overlayFlashOpacity: PropTypes.object.isRequired,
  }

  static triggerSnapAnimation(overlayFlashOpacity) {
    Animated.sequence([
      Animated.timing(overlayFlashOpacity, { toValue: 0.2, duration: 100 }),
      Animated.timing(overlayFlashOpacity, { toValue: 0, duration: 50 }),
      Animated.timing(overlayFlashOpacity, { toValue: 0.6, delay: 100, duration: 120 }),
      Animated.timing(overlayFlashOpacity, { toValue: 0, duration: 90 }),
    ]).start();
  }

  render() {
    return (
      <Animated.View style={{ ...styles.flashOverlay, opacity: this.props.overlayFlashOpacity }} />
    );
  }
}
