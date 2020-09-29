module GenericChannelHeartRateBarrel {

    // Delegate Class for ANT+ Heart Rate Sensor Callbacks.
    class HeartRateSensorDelegate {

        // If the sensor is being tracked this will be called with the latest data.
        function onHeartRateSensorUpdate( data ) {
        }

        // If the extended device number was wildcarded at initialization this will be called with the paired value.
        function onNewExtendedDeviceNumber( extendedDeviceNumber ) {
        }
    }
}