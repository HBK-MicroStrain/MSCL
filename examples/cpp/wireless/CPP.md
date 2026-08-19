# Wireless C++ Examples

This guide walks through common wireless workflows using the MSCL C++ library.

## Setup

See the [C++ Integration Guide](../../../guides/Integration.md) for how to add
MSCL to your project (via CMake `FetchContent`, `find_package`, or manual
integration).

Include the relevant MSCL headers:

```cpp
#include <mscl/MicroStrain/Wireless/BaseStation.h>
#include <mscl/MicroStrain/Wireless/WirelessNode.h>
```

Create a `Connection` to the Base Station's serial port, then wrap it in a `BaseStation`. Base Stations use a baudrate of 3000000:

```cpp
static constexpr const char* COM_PORT = "COM3";
static constexpr uint32_t BAUDRATE = 3000000;

// Create a SerialConnection with the COM port and (optional) baudrate
mscl::Connection connection = mscl::Connection::Serial(COM_PORT, BAUDRATE);

// Create a BaseStation with the SerialConnection
mscl::BaseStation baseStation(connection);

// Due to the nature of wireless devices, it is possible to lose packets over the air.
// MSCL has a built-in way of performing retries whenever an eeprom address is attempted to be read.
// By default, this value is set to 0. You may wish to keep it at 0 and handle retries yourself
// depending on your application.
baseStation.readWriteRetries(3);
```

Each Node connected to the Base Station is represented by a `WirelessNode`, constructed with its node address and the `BaseStation` it communicates through:

```cpp
static constexpr int NODE_ADDRESS = 12345;

mscl::WirelessNode node(NODE_ADDRESS, baseStation);
node.readWriteRetries(3);
```

## Pinging Nodes

The ping command is used to check if there is proper communication between the Base Station and the Node.

```cpp
const mscl::PingResponse response = node.ping();

if (response.success())
{
    // Get some details from the response
    printf("Successfully pinged Node %d\n", node.nodeAddress());
    printf("Base Station RSSI: %d\n", response.baseRssi());
    printf("Node RSSI: %d\n\n", response.nodeRssi());

    // We can talk to the Node, so let's get some more info
    printf("Node Information: \n");
    printf("Model Number: %d\n", node.model());
    printf("Serial: %s\n", node.serial().c_str());
    printf("Firmware: %s\n\n", node.firmwareVersion().str().c_str());
}
else
{
    // Note: To communicate with a Wireless Node, all the following must be true:
    //  - The Node is powered on, and within range of the BaseStation
    //  - The Node is on the same frequency as the BaseStation
    //  - The Node is in Idle Mode (not sampling, and not sleeping)
    //  - The Node is on the same communication protocol as the BaseStation (LXRS vs LXRS+)
    printf("Failed to ping Node %d.\n", node.nodeAddress());
}
```

## Setting to Idle

The **Set to Idle** command is used to put a Node that is sampling, or sleeping, back into the Idle Mode so that it may be communicated with.

```cpp
// Call the set to idle function and get the resulting SetToIdleStatus object
//  Note: This starts the set to idle node command, which is an ongoing operation. The SetToIdleStatus should be queried for progress.
mscl::SetToIdleStatus status = node.setToIdle();

printf("Setting Node to Idle");

// Using the SetToIdleStatus object, check if the Set to Idle operation is complete.
// Note: we are specifying a timeout of 300 milliseconds here, which is the maximum
//      amount of time that the complete function will block if the Set to Idle
//      operation has not finished. Leaving this blank defaults to a timeout of 10ms.
while (!status.complete(300))
{
    // Note: the Set to Idle operation can be canceled by calling status.cancel()
    printf(".");
}

// At this point, the Set to Idle operation has completed

// Check the result of the Set to Idle operation
switch (status.result())
{
    // Completed successfully
    case mscl::SetToIdleStatus::setToIdleResult_success:
    {
        printf("Successfully set to idle!\n");
        break;
    }
    // Canceled by the user
    case mscl::SetToIdleStatus::setToIdleResult_canceled:
    {
        printf("Set to Idle was canceled!\n");
        break;
    }
    // Failed to perform the operation
    case mscl::SetToIdleStatus::setToIdleResult_failed:
    default:
    {
        printf("Set to Idle has failed!\n");
        break;
    }
}
```

## Getting Current Configuration Settings

Configuration indicates how a Node is set up for data acquisition. It includes settings such as sampling mode/rate, offsets, hardware gain, etc.

To read current configuration settings on the Node:

```cpp
printf("Current Configuration Settings\n");

// Read some of the current configuration settings on the node
printf("# of Triggers: %d\n", node.getNumDatalogSessions());
printf("User Inactivity Timeout: %d seconds\n", node.getInactivityTimeout());
printf("Total active channels: %d\n", node.getActiveChannels().count());
printf("# of sweeps: %d\n", node.getNumSweeps());
```

If a configuration function requires a `ChannelMask` parameter, this indicates that the option may affect one or more channels on the Node. You can either:

- Provide the channel mask when asking for the configuration (if known beforehand)
- Programmatically determine the mask for each setting

### Programmatically Determining The Mask For Each Setting

```cpp
// Get the ChannelGroups that the node supports
const mscl::ChannelGroups chGroups = node.features().channelGroups();

// Iterate over each channel group
for (const mscl::ChannelGroup& group: chGroups)
{
    // Get all the settings for this group (i.e., may contain linear equation and hardware gain)
    const mscl::WirelessTypes::ChannelGroupSettings groupSettings = group.settings();

    // Iterate over each setting for this group
    for (const mscl::WirelessTypes::ChannelGroupSetting& setting: groupSettings)
    {
        // If the group contains the linear equation setting
        if (setting == mscl::WirelessTypes::chSetting_linearEquation)
        {
            // We can now pass the channel mask (group.channels()) for this group to node.getLinearEquation.
            // Note: once this channel mask is known for a specific node (+ fw version), it should never change
            mscl::LinearEquation le = node.getLinearEquation(group.channels());

            printf("Linear Equation for: %s\n", group.name().c_str());
            printf("Slope: %06.03f\n", le.slope());
            printf("Offset: %06.03f\n", le.offset());
        }
    }
}
```

## Setting Current Configuration Settings

To set current configuration settings for a Node:

```cpp
// Just changing a small subset of settings for this example.
// More settings are available. Please reference the documentation for the full list of functions.

printf("\nChanging configuration settings...");

// Create a WirelessNodeConfig which is used to set all node configuration options
mscl::WirelessNodeConfig config;

// Set the configuration options that we want to change
config.defaultMode(mscl::WirelessTypes::defaultMode_idle);
config.inactivityTimeout(7200);
config.samplingMode(mscl::WirelessTypes::samplingMode_sync);
config.sampleRate(mscl::WirelessTypes::sampleRate_256Hz);
config.unlimitedDuration(true);

// Attempt to verify the configuration with the Node we want to apply it to
//  Note: this step is not required before applying; however, the apply will throw an
//        Error_InvalidNodeConfig exception if the config fails to verify.
mscl::ConfigIssues issues;

if (!node.verifyConfig(config, issues))
{
    printf("\nFailed to verify the configuration. The following issues were found:\n");

    // Print out all the issues that were found
    for (const mscl::ConfigIssue& issue : issues)
    {
        printf("%s\n", issue.description().c_str());
    }

    printf("Configuration will not be applied.\n");
}
else
{
    // Apply the configuration to the Node
    //  Note: this writes multiple options to the Node. If an Error_NodeCommunication
    //        exception is thrown, it is possible that some options were successfully
    //        applied, while others failed. It is recommended to keep calling
    //        applyConfig until no exception is thrown.
    node.applyConfig(config);
}

printf("Done.\n");
```

## Starting Sync Sampling

Synchronized Sampling is a sampling mode that automatically coordinates all incoming Node data to a particular Base Station. It is designed to ensure data arrival and sequence.

This code snippet provides the function to start sync sampling. It assumes `nodes` is a `std::vector<mscl::WirelessNode>` (already configured for Sync Sampling, as shown above) that should be added to the network:

```cpp
// Create a SyncSamplingNetwork object, giving it the BaseStation that will be the master BaseStation for the network.
mscl::SyncSamplingNetwork network(baseStation);

// Add the WirelessNodes to the network.
// Note: The Nodes must already be configured for Sync Sampling before adding to the network, or else Error_InvalidNodeConfig will be thrown.
for (mscl::WirelessNode& node : nodes)
{
    printf("Adding Node %d to the network...", node.nodeAddress());
    network.addNode(node);
    printf("Done.\n");
}

// Can get information about the network
printf("Network info:\n");
printf("Network OK: %s\n", network.ok() ? "TRUE" : "FALSE");
printf("Percent of Bandwidth: %04.02f%%\n", network.percentBandwidth());
printf("Lossless Enabled: %s\n", network.lossless() ? "TRUE" : "FALSE");

// Apply the network configuration to every node in the network
printf("Applying network configuration...");
network.applyConfiguration();
printf("Done.\n");

// Start all the nodes in the network sampling. The master BaseStation's beacon will be enabled with the system time.
//  Note: if you wish to provide your own start time (not use the system time), pass a mscl::Timestamp object as a second parameter to this function.
//  Note: if you do not want to enable a beacon at this time, use the startSampling_noBeacon() function. (The nodes will wait until they hear a beacon to start sampling).
printf("Starting the network...");
network.startSampling();
printf("Done.\n");
```

## Enabling Beacons

The beacon is used to synchronize and start a group of Nodes when performing Synchronized Sampling.

To enable a beacon:

```cpp
// Make sure we can ping the base station
if (!baseStation.ping())
{
    printf("Failed to ping the Base Station\n");
}

if (baseStation.features().supportsBeaconStatus())
{
    mscl::BeaconStatus status = baseStation.beaconStatus();
    printf("Beacon current status: Enabled?: %s", status.enabled() ? "TRUE" : "FALSE");
    printf(" Time: %s\n", status.timestamp().str().c_str());
}

printf("Attempting to enable the beacon...\n");

// Enable the beacon on the Base Station using the PC time
mscl::Timestamp beaconTime = baseStation.enableBeacon();

// If we got here, no exception was thrown, so enableBeacon was successful
printf("Successfully enabled the beacon on the Base Station\n");
printf("Beacon's initial Timestamp: %s\n", beaconTime.str().c_str());

printf("Beacon is active\n");
```

> Note: If you wish to provide your own start time (instead of using the PC time), pass a `mscl::Timestamp` object as a parameter to `enableBeacon`.

## Disabling Beacons

To disable a beacon:

```cpp
// Disable the beacon on the Base Station
baseStation.disableBeacon();

// If we got here, no exception was thrown, so disableBeacon was successful
printf("Successfully disabled the beacon on the Base Station\n");
```

> Note: Disabling the beacon while a Synchronized Sampling network is running will stop any Nodes that rely on it for timing from sampling.

## Streaming Data

Once a Node is sampling (see [Starting Sync Sampling](#starting-sync-sampling)), data sweeps can be read from the `BaseStation`:

```cpp
// Endless loop of reading in data
while (true)
{
    // Loop through all the data sweeps that have been collected by the BaseStation, with a timeout of 10 milliseconds
    for (const mscl::DataSweep& sweep : baseStation.getData(10))
    {
        // Print out information about the sweep
        printf("Packet Received: ");
        printf("Node %d ", sweep.nodeAddress());
        printf("Timestamp: %s ", sweep.timestamp().str().c_str());
        printf("Tick: %d ", sweep.tick());
        printf("Sample Rate: %s ", sweep.sampleRate().prettyStr().c_str());
        printf("Base RSSI: %d ", sweep.baseRssi());
        printf("Node RSSI: %d ", sweep.nodeRssi());

        printf("DATA: ");

        // Iterate over each point in the sweep
        for (const mscl::WirelessDataPoint& dataPoint: sweep.data())
        {
            // Print out the channel name
            printf("%s: ", dataPoint.channelName().c_str());

            // Print out the channel data
            // Note: The as_string() function is being used here for simplicity.
            //      Other methods (i.e., as_float, as_uint16, as_Vector) are also available.
            //      To determine the format that a dataPoint is stored in, use dataPoint.storedAs().
            printf("%s ", dataPoint.as_string().c_str());
        }

        printf("\n");
    }
}
```

> Note: In addition to sweeps of measurement data, the BaseStation may also periodically deliver diagnostic sweeps (containing channels such as `diagnostic_internalTemp`, `diagnostic_lowBatteryFlag`, etc.) for each Node. These are returned from the same `getData` call and can be distinguished by their channel names.

## Downloading Logged Data

A Node can keep recording to its own internal memory even if it loses connection to the Base Station (Datalogging). That data can be downloaded once the Node is back in range and in Idle Mode.

To view the current datalogging status for a Node:

```cpp
printf("Datalog sessions stored on node: %d\n", node.getNumDatalogSessions());
```

> Note: The Node must be in Idle Mode (see [Setting to Idle](#setting-to-idle)) before a download can be started.

A `DatalogDownloader` reads datalogging information from the Node as soon as it is constructed, then `getNextData` is called repeatedly to walk through each logged sweep until `complete` returns `true`:

```cpp
mscl::DatalogDownloader downloader(node);

while (!downloader.complete())
{
    // Gets the next logged data sweep, parsing more data from the Node as needed
    mscl::LoggedDataSweep sweep = downloader.getNextData();

    // startOfSession() is true for the first sweep of a session, or any time the metadata changes mid-session
    if (downloader.startOfSession())
    {
        printf("--- Start of session %d, sample rate %s ---\n", downloader.sessionIndex(), downloader.sampleRate().prettyStr().c_str());
    }

    printf("Tick: %llu ", (unsigned long long)sweep.tick());

    // Iterate over each point in the sweep, same as with live streamed data
    for (const mscl::WirelessDataPoint& dataPoint : sweep.data())
    {
        printf("%s: %s ", dataPoint.channelName().c_str(), dataPoint.as_string().c_str());
    }

    printf("\n");

    printf("Download progress: %.1f%%\n", downloader.percentComplete());
}
```
