//
//  TestTrackingModeVC.swift
//  PivoBasicSDKTestApp
//
//  Created by Tuan on 2020/04/13.
//  Copyright © 2020 3i. All rights reserved.
//

import UIKit
import PivoProSDK

class TestTrackingModeVC: UIViewController {
  
  static func storyboardInstance() -> TestTrackingModeVC? {
    let storyboard = UIStoryboard(name: String(describing: TestTrackingModeVC.self), bundle: nil)
    return storyboard.instantiateInitialViewController() as? TestTrackingModeVC
  }
  
  @IBOutlet weak var imageViewContainer: UIView!
  @IBOutlet weak var imageView: UIImageView!
  
  private var pivoSDK = PivoProSDK.shared
  private let imagePicker = UIImagePickerController()
  private var image: UIImage?
  private var trackingType: TrackingType = .object
  
  private var imageOrientation: UIInterfaceOrientation = .portrait
  
  private var targetViews: [UIView] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    initImagePicker()
  }
  
  private func initImagePicker() {
    imagePicker.modalPresentationStyle = .currentContext
    imagePicker.sourceType = .photoLibrary
    imagePicker.delegate = self
  }
  
  @IBAction func didTrackingTypeOptionChanged(_ sender: UISegmentedControl) {
    let selectedIndex = sender.selectedSegmentIndex
    switch selectedIndex {
    case 0:
      self.trackingType = .object
    case 1:
      self.trackingType = .human
    case 2:
      self.trackingType = .horse
    default:
      break
    }
    startTracking()
  }
  
  @IBAction func didPickImageButtonClicked(_ sender: UIButton) {
    self.present(imagePicker, animated: true, completion: nil)
  }
  
  private func startTracking() {
    targetViews.forEach { $0.removeFromSuperview() }
    targetViews.removeAll()
    
    guard let image = self.image else { return }
    switch trackingType {
    case .object:
      let drawnRect = CGRect(x: 100, y: 100, width: 100, height: 100)
      let boundingBox = CoordinatorHelper.convertImageViewCoordinateToImageCoordinate(imageContainerViewSize: imageView.size, imageContainerViewContentMode: .resizeAspectFill, imageSize: image.size, rectToConvert: drawnRect)
      do {
        try pivoSDK.startObjectTracking(image: image, boundingBox: boundingBox, trackingSensitivity: .off, delegate: self)
      }
      catch {
        print("Not supported")
      }
    case .human:
      startTracking(image: image)
    case .horse:
      do {
        try pivoSDK.startHorseTracking(image: image, trackingSensitivity: .fast, delegate: self)
      }
      catch {
        print("Not supported")
      }
    }
  }
  
  private func startTracking(image: UIImage) {
    switch imageOrientation {
    case .portrait:
      startTrackingInPortraitMode(image: image)
    case .landscapeLeft:
      startTrackingInLandscapeLeftMode(image: image)
    case .landscapeRight:
      startTrackingInLandscapeRightMode(image: image)
    default:
      break
    }
  }
  
  private func startTrackingInPortraitMode(image: UIImage) {
    do {
      try pivoSDK.startHumanTracking(image: image, trackingSensitivity: .off, delegate: self)
    }
    catch {}
  }
  
  private func startTrackingInLandscapeLeftMode(image: UIImage) {
    guard let rotatedImage = image.rotate(radians: -CGFloat.pi / 2) else { return }
    
    do {
      try pivoSDK.startHumanTracking(image: rotatedImage, trackingSensitivity: .off, delegate: self)
    }
    catch {}
  }
  
  private func startTrackingInLandscapeRightMode(image: UIImage) {
    guard let rotatedImage = image.rotate(radians: CGFloat.pi / 2) else { return }
    
    do {
      try pivoSDK.startHumanTracking(image: rotatedImage, trackingSensitivity: .off, delegate: self)
    }
    catch {}
  }
}

extension TestTrackingModeVC: TrackerDelegate {
  func tracker(didDetected targets: [Target]) {
    switch imageOrientation {
    case .portrait:
      handleTargetDetectedInPortraitMode(targets: targets)
    case .landscapeLeft:
      handleTargetDetecdInLandsccapeLeftMode(targets: targets)
    case .landscapeRight:
      handleTargetDetecdInLandsccapeRightMode(targets: targets)
    default:
      break
    }
  }
  
  private func handleTargetDetectedInPortraitMode(targets: [Target]) {
    targetViews.forEach { $0.removeFromSuperview() }
    DispatchQueue.main.async { [weak self] in
      guard let strongSelf = self else { return }
      guard let image = strongSelf.image else { return }
      for target in targets {
        let rectInScreenCoordinate = CoordinatorHelper.convertImageCoordinateToImageViewCoordinate(imageContainerViewSize: strongSelf.imageView.size, imageContainerViewContentMode: .resizeAspectFill, imageSize: image.size, rectToConvert: target.boundingBox)
        
        let targetView = UIView(frame: rectInScreenCoordinate)
        targetView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.3)
        strongSelf.targetViews.append(targetView)
        strongSelf.imageViewContainer.addSubview(targetView)
      }
    }
  }
  
  private func handleTargetDetecdInLandsccapeLeftMode(targets: [Target]) {
    targetViews.forEach { $0.removeFromSuperview() }
    DispatchQueue.main.async { [weak self] in
      guard let strongSelf = self else { return }
      guard let image = strongSelf.image else { return }
      for target in targets {
        
        let size = CGSize(width: image.size.height, height: image.size.width)
        let convertedRect = CoordinatorHelper.rotateRectInsideImage(imageSize: size, rect: target.boundingBox, rotateAngle: CGFloat.pi / 2)
        
        let rectInScreenCoordinate = CoordinatorHelper.convertImageCoordinateToImageViewCoordinate(imageContainerViewSize: strongSelf.imageView.size, imageContainerViewContentMode: .resizeAspectFill, imageSize: image.size, rectToConvert: convertedRect)
        
        let targetView = UIView(frame: rectInScreenCoordinate)
        targetView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.3)
        strongSelf.targetViews.append(targetView)
        strongSelf.imageViewContainer.addSubview(targetView)
      }
    }
  }
  
  private func handleTargetDetecdInLandsccapeRightMode(targets: [Target]) {
    targetViews.forEach { $0.removeFromSuperview() }
    DispatchQueue.main.async { [weak self] in
      guard let strongSelf = self else { return }
      guard let image = strongSelf.image else { return }
      for target in targets {
        
        let size = CGSize(width: image.size.height, height: image.size.width)
        let convertedRect = CoordinatorHelper.rotateRectInsideImage(imageSize: size, rect: target.boundingBox, rotateAngle: -CGFloat.pi / 2)
        
        let rectInScreenCoordinate = CoordinatorHelper.convertImageCoordinateToImageViewCoordinate(imageContainerViewSize: strongSelf.imageView.size, imageContainerViewContentMode: .resizeAspectFill, imageSize: image.size, rectToConvert: convertedRect)
        
        let targetView = UIView(frame: rectInScreenCoordinate)
        targetView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.3)
        strongSelf.targetViews.append(targetView)
        strongSelf.imageViewContainer.addSubview(targetView)
      }
    }
  }
}

extension TestTrackingModeVC: UINavigationControllerDelegate {
  
}

extension TestTrackingModeVC: UIImagePickerControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    if let image = info[.originalImage] as? UIImage {
      self.image = image
      imageView.image = image
      picker.dismiss(animated: true, completion: nil)
      startTracking()
    }
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    
  }
}
