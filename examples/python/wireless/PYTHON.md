# Wireless Python Examples

This guide walks through common wireless workflows using the MSCL Python bindings.

## Setup

Install MSCL from PyPI:

```shell
pip install pymscl
```

Import the MSCL module:

```python
import mscl
```

Create a `Connection` to the Base Station's serial port, then wrap it in a `BaseStation`. Base Stations use a baudrate of 3000000:

```python
COM_PORT = "COM3"
BAUDRATE = 3000000

connection = mscl.Connection.Serial(COM_PORT, BAUDRATE)
baseStation = mscl.BaseStation(connection)

# Due to the nature of wireless devices, it is possible to lose packets over the air.
# MSCL has a built-in way of performing retries whenever an eeprom address is attempted to be read.
# By default, this value is set to 0. You may wish to keep it at 0 and handle retries yourself
# depending on your application.
baseStation.readWriteRetries(3)
```

Each Node connected to the Base Station is represented by a `WirelessNode`, constructed with its node address and the `BaseStation` it communicates through:

```python
NODE_ADDRESS = 12345

node = mscl.WirelessNode(NODE_ADDRESS, baseStation)
node.readWriteRetries(3)
```

## Pinging Nodes

The ping command is used to check if there is proper communication between the Base Station and the Node.

```python
response = node.ping()

if response.success():
    # Get some details from the response
    print("Successfully pinged Node {0}".format(node.nodeAddress()))
    print("Base Station RSSI: {0}".format(response.baseRssi()))
    print("Node RSSI: {0}".format(response.nodeRssi()))

    # We can talk to the Node, so let's get some more info
    print("\nNode Information:")
    print("--------------------")
    print("Model Number: {0}".format(node.model()))
    print("Serial: {0}".format(node.serial()))
    print("Firmware: {0}\n".format(node.firmwareVersion()))
else:
    print("Failed to ping Node {0}".format(node.nodeAddress()))
```

> **Note: To communicate with a Wireless Node, all the following must be true:**
>
>    - The Node is powered on, and within range of the Base Station
>    - The Node is on the same frequency as the Base Station
>    - The Node is in Idle Mode (not sampling, and not sleeping)
>    - The Node is on the same communication protocol as the Base Station (LXRS vs LXRS+)

## Setting to Idle

The **Set to Idle** command is used to put a Node that is sampling, or sleeping, back into the Idle Mode so that it may be communicated with.

```python
# setToIdle starts an ongoing node operation and returns a SetToIdleStatus that should be queried for progress
status = node.setToIdle()

print("Setting Node to Idle")

# Note: we are specifying a timeout of 300 milliseconds here, which is the maximum
#       amount of time that the complete function will block if the Set to Idle
#       operation has not finished. Leaving this blank defaults to a timeout of 10ms.
while not status.complete(300):
    # Note: the Set to Idle operation can be canceled by calling status.cancel()
    print(".", end="")

# At this point, the Set to Idle operation has completed
result = status.result()

if result == mscl.SetToIdleStatus.setToIdleResult_success:
    print("Successfully set to idle!")
elif result == mscl.SetToIdleStatus.setToIdleResult_canceled:
    print("Set to Idle was canceled!")
else:
    print("Set to Idle has failed!")
```

## Getting Current Configuration Settings

Configuration indicates how a Node is set up for data acquisition. It includes settings such as sampling mode/rate, offsets, hardware gain, etc.

To read current configuration settings on the Node:

```python
print("Current Configuration Settings")

# Read some of the current configuration settings on the node
print("# of Triggers: {0}".format(node.getNumDatalogSessions()))
print("User Inactivity Timeout: {0} seconds".format(node.getInactivityTimeout()))
print("Total active channels: {0}".format(node.getActiveChannels().count()))
print("# of sweeps: {0}".format(node.getNumSweeps()))
```

If a configuration function requires a `ChannelMask` parameter, this indicates that the option may affect one or more channels on the Node. You can either:

- Provide the channel mask when asking for the configuration (if known beforehand)
- Programmatically determine the mask for each setting

### Programmatically Determining The Mask For Each Setting

```python
# Get the ChannelGroups that the node supports
chGroups = node.features().channelGroups()

# Iterate over each channel group
for group in chGroups:
    # Get all the settings for this group (i.e., may contain linear equation and hardware gain)
    groupSettings = group.settings()

    # Iterate over each setting for this group
    for setting in groupSettings:
        # If the group contains the linear equation setting
        if setting == mscl.WirelessTypes.chSetting_linearEquation:
            # We can now pass the channel mask (group.channels()) for this group to node.getLinearEquation.
            # Note: once this channel mask is known for a specific node (+ fw version), it should never change
            le = node.getLinearEquation(group.channels())

            print("Linear Equation for: {0}".format(group.name()))
            print("Slope: {0:06.3f}".format(le.slope()))
            print("Offset: {0:06.3f}".format(le.offset()))
```

## Setting Current Configuration Settings

To set current configuration settings for a Node:

```python
# Just changing a small subset of settings for this example.
# More settings are available. Please reference the documentation for the full list of functions.

print("\nChanging configuration settings...", end="")

# Create a WirelessNodeConfig which is used to set all node configuration options
config = mscl.WirelessNodeConfig()

# Set the configuration options that we want to change
config.defaultMode(mscl.WirelessTypes.defaultMode_idle)
config.inactivityTimeout(7200)
config.samplingMode(mscl.WirelessTypes.samplingMode_sync)
config.sampleRate(mscl.WirelessTypes.sampleRate_256Hz)
config.unlimitedDuration(True)

# Attempt to verify the configuration with the Node we want to apply it to
#  Note: this step is not required before applying; however, the apply will throw an
#        Error_InvalidNodeConfig exception if the config fails to verify.
issues = mscl.ConfigIssues()

if not node.verifyConfig(config, issues):
    print("\nFailed to verify the configuration. The following issues were found:")

    # Print out all the issues that were found
    for issue in issues:
        print(issue.description())

    print("Configuration will not be applied.")
else:
    # Apply the configuration to the Node
    #  Note: this writes multiple options to the Node. If an Error_NodeCommunication
    #        exception is thrown, it is possible that some options were successfully
    #        applied, while others failed. It is recommended to keep calling
    #        applyConfig until no exception is thrown.
    node.applyConfig(config)

print("Done.")
```

## Starting Sync Sampling

Synchronized Sampling is a sampling mode that automatically coordinates all incoming Node data to a particular Base Station. It is designed to ensure data arrival and sequence.

This code snippet provides the function to start sync sampling. It assumes `nodes` is a list of the `WirelessNode` objects (already configured for Sync Sampling, as shown above) that should be added to the network:

```python
# Create a SyncSamplingNetwork object, giving it the BaseStation that will be the master BaseStation for the network
network = mscl.SyncSamplingNetwork(baseStation)

# Add the WirelessNodes to the network.
# Note: The Nodes must already be configured for Sync Sampling before adding to the network,
#       or else Error_InvalidNodeConfig will be thrown.
for node in nodes:
    print("Adding node {0} to the network...".format(node.nodeAddress()), end="")
    network.addNode(node)
    print("Done.")

# Can get information about the network
print("Network info:")
print("Network OK: {0}".format("TRUE" if network.ok() else "FALSE"))
print("Percent of Bandwidth: {0:04.02f}%".format(network.percentBandwidth()))
print("Lossless Enabled: {0}".format("TRUE" if network.lossless() else "FALSE"))

# Apply the network configuration to every node in the network
print("Applying network configuration...", end="")
network.applyConfiguration()
print("Done.")

# Start all the nodes in the network sampling. The master BaseStation's beacon will be enabled with the system time.
#  Note: if you wish to provide your own start time (not use the system time), pass a mscl.Timestamp object
#        as a second parameter to this function.
#  Note: if you do not want to enable a beacon at this time, use the network.startSampling_noBeacon() function.
#        The nodes will wait until they hear a beacon to start sampling.
print("Starting the network...", end="")
network.startSampling()
print("Done.")
```

## Enabling Beacons

The beacon is used to synchronize and start a group of Nodes when performing Synchronized Sampling.

To enable a beacon:

```python
# Make sure we can ping the base station
if not baseStation.ping():
    print("Failed to ping the Base Station")

if baseStation.features().supportsBeaconStatus():
    status = baseStation.beaconStatus()
    print("Beacon current status: Enabled?: {0}".format("TRUE" if status.enabled() else "FALSE"), end="")
    print(" Time: {0}".format(status.timestamp()))

print("Attempting to enable the beacon...")

# Enable the beacon on the Base Station using the PC time
beaconTime = baseStation.enableBeacon()

# If we got here, no exception was thrown, so enableBeacon was successful
print("Successfully enabled the beacon on the Base Station")
print("Beacon's initial Timestamp: {0}".format(beaconTime))

print("Beacon is active")
```

> Note: If you wish to provide your own start time (instead of using the PC time), pass a `mscl.Timestamp` object as a parameter to `enableBeacon`.

## Disabling Beacons

To disable a beacon:

```python
# Disable the beacon on the Base Station
baseStation.disableBeacon()

# If we got here, no exception was thrown, so disableBeacon was successful
print("Successfully disabled the beacon on the Base Station")
```

> Note: Disabling the beacon while a Synchronized Sampling network is running will stop any Nodes that rely on it for timing from sampling.

## Streaming Data

Once a Node is sampling (see [Starting Sync Sampling](#starting-sync-sampling)), data sweeps can be read from the `BaseStation`:

```python
# Endless loop of reading in data
while True:
    # Loop through all the data sweeps that have been collected by the BaseStation, with a timeout of 10 milliseconds
    for sweep in baseStation.getData(10):
        # Print out information about the sweep
        print("Packet Received: ", end="")
        print("Node {0} ".format(sweep.nodeAddress()), end="")
        print("Timestamp: {0} ".format(sweep.timestamp()), end="")
        print("Tick: {0} ".format(sweep.tick()), end="")
        print("Sample Rate: {0} ".format(sweep.sampleRate().prettyStr()), end="")
        print("Base RSSI: {0} ".format(sweep.baseRssi()), end="")
        print("Node RSSI: {0} ".format(sweep.nodeRssi()), end="")

        print("DATA: ", end="")

        # Iterate over each point in the sweep
        for dataPoint in sweep.data():
            # Print out the channel name
            print("{0}: ".format(dataPoint.channelName()), end="")

            # Print out the channel data
            # Note: The as_string() function is being used here for simplicity.
            #       Other methods (i.e., as_float, as_uint16, as_Vector) are also available.
            #       To determine the format that a dataPoint is stored in, use dataPoint.storedAs().
            print("{0} ".format(dataPoint.as_string()), end="")

        print("")
```

> Note: In addition to sweeps of measurement data, the BaseStation may also periodically deliver diagnostic sweeps (containing channels such as `diagnostic_internalTemp`, `diagnostic_lowBatteryFlag`, etc.) for each Node. These are returned from the same `getData` call and can be distinguished by their channel names.

## Downloading Logged Data

A Node can keep recording to its own internal memory even if it loses connection to the Base Station (Datalogging). That data can be downloaded once the Node is back in range and in Idle Mode.

To view the current datalogging status for a Node:

```python
print("Datalog sessions stored on node: {0}".format(node.getNumDatalogSessions()))
```

> Note: The Node must be in Idle Mode (see [Setting to Idle](#setting-to-idle)) before a download can be started.

A `DatalogDownloader` reads datalogging information from the Node as soon as it is constructed, then `getNextData` is called repeatedly to walk through each logged sweep until `complete` returns `True`:

```python
downloader = mscl.DatalogDownloader(node)

while not downloader.complete():
    # Gets the next logged data sweep, parsing more data from the Node as needed
    sweep = downloader.getNextData()

    # metaDataUpdated() is true for the first sweep of a session, or any time the metadata changes mid-session
    if downloader.startOfSession():
        print("--- Start of session {0}, sample rate {1} ---".format(downloader.sessionIndex(), downloader.sampleRate().prettyStr()))

    print("Tick: {0} ".format(sweep.tick()), end="")

    # Iterate over each point in the sweep, same as with live streamed data
    for dataPoint in sweep.data():
        print("{0}: {1} ".format(dataPoint.channelName(), dataPoint.as_string()), end="")

    print("")

    print("Download progress: {0:.1f}%".format(downloader.percentComplete()))
```
