using Toybox.Ant;

module GenericChannelHeartRateBarrel {
    // Channel configuration
    const CHANNEL_PERIOD = 8070;    // ANT+ HR Channel Period
    const DEVICE_TYPE = 120;        // ANT+ HR Device Type
    const RADIO_FREQUENCY = 57;     // ANT+ Radio Frequency
    const SEARCH_TIMEOUT = 2;       // 5 second search timeout
    
    // Message indexes
    const MESSAGE_ID_INDEX = 0;
    const MESSAGE_CODE_INDEX = 1;
    
    class LegacyHeartData {
        const INVALID_HR = 0;
        
        var computedHeartRate;
        
        function initialize() {
            computedHeartRate = INVALID_HR;
        }
    }
    
    class LegacyHeartRateMessage {
        static const COMPUTED_HR_INDEX = 7;
        
        static function parse( payload, data ) {
            data.computedHeartRate = payload[COMPUTED_HR_INDEX];
        }
    }
    
    class AntPlusHeartRateSensor extends Toybox.Ant.GenericChannel {
    
        const WILDCARD_PAIRING = 0;
        const CLOSEST_SEARCH_BIN = 1;
        const FARTHEST_SEARCH_BIN = 10;

        var chanAssign;
        var deviceCfg;
        var searching;
        var data;
        hidden var deviceNumber;
        hidden var transmissionType;
        hidden var searchThreshold;

        // Initializes AntPlusHeartRateSensor, configures and opens channel
        function initialize( extendedDeviceNumber, isProximityPairing ) {
            
            if (extendedDeviceNumber == WILDCARD_PAIRING) {
                deviceNumber = WILDCARD_PAIRING;
                transmissionType = WILDCARD_PAIRING;
	        } else {
                // Parse the extended device number for the upper nibble
                deviceNumber = extendedDeviceNumber & 0xFFFF;
                transmissionType = ((extendedDeviceNumber >> 12) & 0xF0) | 0x01;
	        }
	        
	        if ( isProximityPairing ) {
	           searchThreshold = CLOSEST_SEARCH_BIN;
	        } else { 
	           searchThreshold = WILDCARD_PAIRING;
	       }
            
            searching = true;   // Searching is the default state of the ANT channel
            
            data = new LegacyHeartData();
            
            // Create channel assignment
            chanAssign = new Toybox.Ant.ChannelAssignment(
            Toybox.Ant.CHANNEL_TYPE_RX_NOT_TX,
            Toybox.Ant.NETWORK_PLUS);
            
            // Initialize the channel through the superclass
            GenericChannel.initialize( method(:onMessage), chanAssign );
            
            // Set the configuration
            deviceCfg = new Toybox.Ant.DeviceConfig( {
                :deviceNumber => deviceNumber,
                :deviceType => DEVICE_TYPE,
                :transmissionType => transmissionType,
                :messagePeriod => CHANNEL_PERIOD,
                :radioFrequency => RADIO_FREQUENCY,
                :searchTimeoutLowPriority => SEARCH_TIMEOUT,
                :searchThreshold => searchThreshold} );
            GenericChannel.setDeviceConfig( deviceCfg );
        }
        
        // Opens the generic channel
        function open() {
            GenericChannel.open();
        }
        
        // On new ANT Message, parses the message
        // @param msg, a Toybox.Ant.Message object
        function onMessage( msg ) {
            // Parse the payload
            var payload = msg.getPayload();
            
            if ( Toybox.Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId ) {
                if ( Toybox.Ant.MSG_ID_RF_EVENT == payload[MESSAGE_ID_INDEX] ) {
                    switch(payload[MESSAGE_CODE_INDEX]) {
                        case Toybox.Ant.MSG_CODE_EVENT_CHANNEL_CLOSED:
                            // Expand search radius after each channel close event due to search timeout
                            if ( searchThreshold != 0 ) {
                                if ( searchThreshold < FARTHEST_SEARCH_BIN ) {
                                    searchThreshold++;
                                } else {
                                    searchThreshold = WILDCARD_PAIRING;
                                }
                            }
                            
                            // Channel closed, re-open
                            open();
                            break;
                            
                        case Toybox.Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH:
                            searching = true;
                            break;
                    }
                }
            } else if ( Toybox.Ant.MSG_ID_BROADCAST_DATA == msg.messageId ) {
                if ( searching ) {
                    searching = false;  // ANT channel is now tracking
                }
                
                LegacyHeartRateMessage.parse(payload, data);    // Parse payload into data
            }
        }
    }
}
