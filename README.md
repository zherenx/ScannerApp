# Scanner App (iOS)

## Requirements

### Single camera capture

* iOS 12 or above

### Dual camera capture

* iOS 13 or above
* A12/A12X processor or above (more testing required to confirm this)

## Build (do we need this section?)

(based on <https://github.com/ScanNet/ScanNet/blob/master/ScannerApp/README.md>)

Open ScannerApp-Swift.xcodeproj with Xcode
Attach your iOS device and authorize the development machine to build to the device
Build the Scanner target for your device (select "Scanner" and your attached device name at the top left next to the "play" icon, and click the "play" icon)
The app should automatically launch on your device

## Configuation

Most of the important config parameters are stored in Constants.swift file, and they can be accessed easily within the project.

Some important ones include,

* Constants.Server.host (which should be set to server URL)
* Constants.sceneTypes (which is the list of pre-defined scene types)
* etc.

## Code Review Notes

Views to code review (and corresponding view controllers)

* Camera view (CameraViewController.swift)
* Library view (LibraryViewController.swift)
* Configuartion view (ConfiguationViewController.swift)

DualCameraViewController is responsible for dual camera capture, which is not ready for code review.

DepthViewController is a cl that I used to test the depth related API, which will not be included in any releases.

## Development Notes

### Camera View

Camera view is responsible for (single camera) scanning.

Corresponding view controller

* ```CameraViewController```

```CameraViewController``` utilizes [```AVCaptureSession```](https://developer.apple.com/documentation/avfoundation/avcapturesession) to capture rgb video stream with built-in camera sensor (e.g. wide-angle camera). Please refer to [useful links](#useful-links-for-video-capturing-on-ios-devices) section below for more information about iOS video capturing, configuation and more.

#### viewDidLoad()

* ```configurateSession()``` configurates things related to camera capture/AVCaptureSession
* ```loadUserDefaults()``` reads from UserDefaults to class variables
* ```updateGpsLocation()``` updates gps location and stores it in class variable
  * TODO: gps related implementation could be improved
  * TODO: might not necessary to be called in ViewDidLoad()
* ```configPopUpView()``` configurates the pop-up view for user input (which is showed when users press the "Record" button)

#### startRecoring()

When "Start" button (on the pop-up view) is pressed, ```startRecoring()``` is called and the recording is started. This function includes many things,

* start rgb video capture
* start motion data capture (using [```MotionManager```](#motionmanager))
* determine recording id and file save path

#### stopRecording()

This function is called when "Stop" button is pressed. It ends the video and motion data recording; it prepares and saves metadata file.

Related classes

* [```MotionManager```](#motionmanager)
* [```MotionData```](#motiondata)
* [```MetaData```](#metadata)
* [```PreviewView```](#previewview)
* [```UserDefaultsExtension```](#userdefaultsextension)

### Dual Camera View

Corresponding view controller

* ```DualCameraViewController```

```DualCameraViewController``` utilizes [```AVCaptureMultiCamSession```](https://developer.apple.com/documentation/avfoundation/avcapturemulticamsession)

TODO:

### Library View

Library view shows a list of previous recordings

Corresponding view controller

* ```LibraryTableViewController```

Related classes

* [```LibraryTableViewCell```](#librarytableviewcell)
* [```HttpRequestHandler```](#httprequesthandler)

### Configuration View

Configuation view is for user input related

Corresponding view controller

* ```ConfiguationViewController```

Related class

* [```UserDefaultsExtension```](#userdefaultsextension)

### Other Files

#### MotionManager

```MotionManager``` handles motion data recording for the project. To start and stop motion data recording, simply call ```startRecoring(dataPathString: String, fileId: String)```  and ```stopRecording()``` (use ```stopRecordingAndReturnNumberOfMeasurements()``` or ```stopRecordingAndReturnStreamInfo()``` when needed).

While recording, whenever ```motionManager``` (a ```CMMotionManager``` instance) receives a valid reading of motion data, a [```MotionData```](#motiondata) object will be instantiated and writing to file operation will be performed. Please see ```startRecording()``` (near where ```CMMotionManager.startDeviceMotionUpdates(...)``` is called) for implementation.

Useful links

* [CMMotionManager](https://developer.apple.com/documentation/coremotion/cmmotionmanager)
* [CMDeviceMotion](https://developer.apple.com/documentation/coremotion/cmdevicemotion)

#### MotionData

* a ```MotionData``` instance is constructed with a ```CMDeviceMotion``` instance (i.e. motion data from sensors)
* has function to display itself and write to files (e.g. ```display()```, ```writeToFileInBinaryFormat()```, etc.)

TODO: MotionData and MotionManager are somewhat coupled with each other, consider improve on this

#### Metadata

* a template of Scanner App metadata
* json encodable
* has function to display itself and write to file (e.g. ```display()```, ```writeToFile()```)

Some notes about metadata

* device id
  * the app is currently using [```identifierForVendor```](https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor) as the unique identifier for a device
* device model code
  * ```Helper.getDeviceModelCode()``` is responsible for getting the model code (e.g. ```iPhone7,2```)
  * the model code can be uniqlely mapped to an Apple device model (e.g. ```iPhone7,2``` is iPhone 6)

Useful links

* some device info is available in [UIDevice](https://developer.apple.com/documentation/uikit/uidevice)
* some links related to getting device model code and model code mapping
  * <https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model>
  * <https://www.tutorialspoint.com/how-to-determine-device-type-iphone-ipod-touch-with-iphone-sdk>
  * <https://gist.github.com/adamawolf/3048717>

#### HttpRequestHandler

* handle http request related (e.g. upload, verify)
* ```uploadAllFilesOneByOne(fileUrls: [URL])```
  * under current setup, the "upload" button on the library view is essentially calling this function
  * this function uploads files specified by ```fileUrls``` from small to large recursively
  * a verify request is sent after each upload request complete

#### UserDefaultsExtension

* an extension to the ```UserDefaults``` class
* contains implementation of project specific UserDefaults behavior
* default value for UserDefaults (if necessary) can be specified here
* nil value for UserDefaults can be prevented here (if necessary)

#### VideoHelper

* include helper functions related to video or video file handling

#### Helper

* other helper functions

#### PreviewView

* this file copied from Apple's sample app
* responsible for previewing color camera capturing

#### LibraryTableViewCell

* define behavior for cell in library view

## Useful Links for Video Capturing on iOS Devices

* [AVCaptureSession](https://developer.apple.com/documentation/avfoundation/avcapturesession)
* [AVCaptureMultiCamSession](https://developer.apple.com/documentation/avfoundation/avcapturemulticamsession)
* Apple's sample camera app: [AVCam](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app)
* Apple's sample camera app for multicam capturing: [AVMultiCamPiP](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avmulticampip_capturing_from_multiple_cameras)
* Article: [Setting Up a Capture Session](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/setting_up_a_capture_session)
* WWDC 2019 presentation [Advances in Camera Capture & Photo Segmentation](https://developer.apple.com/videos/play/wwdc2019/225), which introduces AVCaptureMultiCamSession and talks about multicam capturing
