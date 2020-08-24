using Toybox.Ant;

module GenericChannelHeartRateBarrel {
    // Channel configuration
    const CHANNEL_PERIOD = 8070;    // ANT+ HR Channel Period
    const DEVICE_NUMBER = 0;        // 0 to wildcard for pairing
    const DEVICE_TYPE = 120;        // ANT+ HR Device Type
    const TRANSMISSION_TYPE = 0;    // 0 to wildcard for pairing
    const RADIO_FREQUENCY = 57;     // ANT+ Radio Frequency
    
    // Message indexes
    const MESSAGE_ID_INDEX = 0;
    const MESSAGE_CODE_INDEX = 1;
    
    class LegacyHeartData {
        var computedHeartRate;
        
        function initialize() {
            computedHeartRate = 0;
        }
    }
    
    class LegacyHeartRateMessage {
        hidden const COMPUTED_HR_INDEX = 7;
        
        function parse( payload, data ) {
            data.computedHeartRate = payload[7];
        }
    }
    
    class AntPlusHeartRateSensor extends Toybox.Ant.GenericChannel {

        var chanAssign;
        var deviceCfg;
        var searching;
        var data;

        // Initializes AntPlusHeartRateSensor, configures and opens channel
        function initialize( ) {
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
                :deviceNumber => DEVICE_NUMBER,
                :deviceType => DEVICE_TYPE,
                :transmissionType => TRANSMISSION_TYPE,
                :messagePeriod => CHANNEL_PERIOD,
                :radioFrequency => RADIO_FREQUENCY,
                :searchTimeoutLowPriority => 12,        // Timeout in 30s
                :searchThreshold => 0} );               // Pair to any sensor in range
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
