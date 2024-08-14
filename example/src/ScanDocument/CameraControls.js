import React from 'react';
import { SafeAreaView, Text, TouchableOpacity, View } from 'react-native';
import { Filters } from 'react-native-rectangle-scanner';

import { styles } from './styles';

const CameraControls = ({ closeScanner, capture, isCapturing, flashIsAvailable, flashOn, setFlashOn, filterId, setFilterId }) => (
  <SafeAreaView style={[styles.overlay]}>
    <View style={{ flexDirection: 'row', justifyContent: 'space-around' }}>
      {Filters.RECOMMENDED_PLATFORM_FILTERS.map((f) => (
        <TouchableOpacity key={f.id} onPress={() => setFilterId(f.id)}>
          <Text style={{ color: 'white', fontSize: 13, fontWeight: filterId === f.id ? 'bold' : 'normal' }}>{f.name}</Text>
        </TouchableOpacity>
      ))}
    </View>

    <View style={styles.buttonBottomContainer}>
      <View style={styles.buttonGroup}>
        <TouchableOpacity
          style={styles.button}
          onPress={closeScanner}
          activeOpacity={0.8}
        >
          <Text style={styles.buttonText}>Cancel</Text>
        </TouchableOpacity>
      </View>
      <View style={[styles.cameraOutline, { opacity: isCapturing ? 0.8 : 1 }]}>
        <TouchableOpacity
          activeOpacity={0.8}
          style={styles.cameraButton}
          onPress={isCapturing ? () => null : () => capture}
        />
      </View>
      <View>
        <View style={[styles.buttonActionGroup, { justifyContent: 'flex-end', marginBottom: 16 }]}>
          {flashIsAvailable && (
            <TouchableOpacity
              style={{
                borderRadius: 30,
                margin: 8,
                backgroundColor: flashOn ? '#FFFFFF80' : '#00000080',
                alignItems: 'center',
                justifyContent: 'center',
                paddingTop: 7,
                height: 50,
                width: 50
              }}
              activeOpacity={0.8}
              onPress={() => setFlashOn(!flashOn)}
            >
              <Text style={{ color: flashOn ? '#333' : '#FFF' }}>Flash: {flashOn ? 'ON' : 'OFF'}</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>
    </View>
  </SafeAreaView>
);

export default CameraControls;