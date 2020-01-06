import { Platform } from 'react-native';

const PHOTO_FILTER = { id: 1, name: 'Photo' };
const GREYSCALE_FILTER = { id: 2, name: 'Greyscale' };
const COLOR_FILTER = { id: 3, name: 'Color' };
const BLACK_AND_WHITE_FILTER = { id: 4, name: 'Black & White' };

const RECOMMENDED_PLATFORM_FILTERS = [
  COLOR_FILTER,
  BLACK_AND_WHITE_FILTER,
];
let PLATFORM_DEFAULT_FILTER_ID = COLOR_FILTER.id;

// On Android the color and black and white are too similar to
// the original and greyscale to justify showing all 4 filters
if (Platform.OS === 'ios') {
  RECOMMENDED_PLATFORM_FILTERS.push(GREYSCALE_FILTER);
  RECOMMENDED_PLATFORM_FILTERS.push(PHOTO_FILTER);
  PLATFORM_DEFAULT_FILTER_ID = PHOTO_FILTER.id;
}

export default {
  PHOTO_FILTER,
  GREYSCALE_FILTER,
  COLOR_FILTER,
  BLACK_AND_WHITE_FILTER,
  RECOMMENDED_PLATFORM_FILTERS,
  PLATFORM_DEFAULT_FILTER_ID,
};
