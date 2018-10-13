/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import TesseractOCR

class ViewController: UIViewController {
  
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var findTextField: UITextField!
  @IBOutlet weak var replaceTextField: UITextField!
  @IBOutlet weak var topMarginConstraint: NSLayoutConstraint!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }

  // IBAction methods
  @IBAction func backgroundTapped(_ sender: Any) {
    view.endEditing(true)
  }
  
  @IBAction func textFieldEndOnExit(_ sender: Any) {
    view.endEditing(true)
  }
  
  @IBAction func takePhoto(_ sender: Any) {
    view.endEditing(true)
    presentImagePicker()
  }
  
  @IBAction func swapText(_ sender: Any) {
    view.endEditing(true)

    guard let text = textView.text,
      let findText = findTextField.text,
      let replaceText = replaceTextField.text else {
        return
    }

    textView.text = text.replacingOccurrences(of: findText, with: replaceText)
    findTextField.text = nil
    replaceTextField.text = nil
  }
  
  @IBAction func sharePoem(_ sender: Any) {
    if textView.text.isEmpty {
      return
    }
    let activityViewController = UIActivityViewController(activityItems:
      [textView.text], applicationActivities: nil)
    let excludeActivities:[UIActivityType] = [
      .assignToContact,
      .saveToCameraRoll,
      .addToReadingList,
      .postToFlickr,
      .postToVimeo]
    activityViewController.excludedActivityTypes = excludeActivities
    present(activityViewController, animated: true)
  }

  // Tesseract Image Recognition
  func performImageRecognition(_ image: UIImage) {

    if let tesseract = G8Tesseract(language: "eng+fra") {
      tesseract.engineMode = .tesseractCubeCombined
      tesseract.pageSegmentationMode = .auto
      tesseract.image = image.g8_blackAndWhite()
      tesseract.recognize()
      textView.text = tesseract.recognizedText
    }
    activityIndicator.stopAnimating()
  }
  
  // The following methods handle the keyboard resignation/
  // move the view so that the first responders aren't hidden
  func moveViewUp() {
    if topMarginConstraint.constant != 0 {
      return
    }
    topMarginConstraint.constant -= 135
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
    }
  }
  
  func moveViewDown() {
    if topMarginConstraint.constant == 0 {
      return
    }
    topMarginConstraint.constant = 0
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
    }
  }
}

// MARK: - UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
  func textFieldDidBeginEditing(_ textField: UITextField) {
    moveViewUp()
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    moveViewDown()
  }
}

// MARK: - UINavigationControllerDelegate
extension ViewController: UINavigationControllerDelegate {
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate {
  func presentImagePicker() {

    let imagePickerActionSheet = UIAlertController(title: "Snap/Upload Image",
                                                   message: nil, preferredStyle: .actionSheet)
    
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      let cameraButton = UIAlertAction(title: "Take Photo",
                                       style: .default) { (alert) -> Void in
                                        let imagePicker = UIImagePickerController()
                                        imagePicker.delegate = self
                                        imagePicker.sourceType = .camera
                                        self.present(imagePicker, animated: true)
      }
      imagePickerActionSheet.addAction(cameraButton)
    }
    
    let libraryButton = UIAlertAction(title: "Choose Existing",
                                      style: .default) { (alert) -> Void in
                                        let imagePicker = UIImagePickerController()
                                        imagePicker.delegate = self
                                        imagePicker.sourceType = .photoLibrary
                                        self.present(imagePicker, animated: true)
    }
    imagePickerActionSheet.addAction(libraryButton)

    let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)
    imagePickerActionSheet.addAction(cancelButton)

    present(imagePickerActionSheet, animated: true)
  }

  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [String : Any]) {
    
    if let selectedPhoto = info[UIImagePickerControllerOriginalImage] as? UIImage,
      let scaledImage = selectedPhoto.scaleImage(640) {
      
      activityIndicator.startAnimating()

      dismiss(animated: true, completion: {
        self.performImageRecognition(scaledImage)
      })
    }
  }
}

// MARK: - UIImage extension
extension UIImage {
  func scaleImage(_ maxDimension: CGFloat) -> UIImage? {
    
    var scaledSize = CGSize(width: maxDimension, height: maxDimension)
    
    if size.width > size.height {
      let scaleFactor = size.height / size.width
      scaledSize.height = scaledSize.width * scaleFactor
    } else {
      let scaleFactor = size.width / size.height
      scaledSize.width = scaledSize.height * scaleFactor
    }
    
    UIGraphicsBeginImageContext(scaledSize)
    draw(in: CGRect(origin: .zero, size: scaledSize))
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return scaledImage
  }
}
