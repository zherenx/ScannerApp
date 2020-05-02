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

DualCameraViewController.swift is responsible for dual camera capture, which is not ready for code review.

DepthViewController.swift is a file that I used to test the depth related API, which will not be included in any releases.

## Development Notes

### Camera View

Camera view is responsible for scanning.

Related files

* CameraViewController.swift
* MotionManager.swift
* used by CameraViewController, handle IMU recording
  * uses MotionData
* MotionData.swift
* MetaData.swift
* PreviewView.swift
  * this file copied from Apple's sample app

### Library View

Library view shows a list of previous recordings

Related files

* LibraryViewController.swift
* ScanTableViewCell.swift
* ScanTableViewCell.xib
* HttpRequestHandler.swift
  * handle http request related (e.g. upload verify)

### Configuration View

Configuation view is for user input related

Related files

* ConfiguationViewController.swift

### Other files

* VideoHelper.swift
  * include helper functions related to video or video file handling
* Helper.swift
  * other helper functions
