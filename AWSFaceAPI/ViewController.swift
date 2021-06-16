//
//  ViewController.swift
//  AWSFaceAPI
//
//  Created by Abzal Toremuratuly on 21.04.2021.
//

import UIKit
import SnapKit
import AWSRekognition

class ViewController: UIViewController {

    var sourceImage: UIImage?
    var targetImage: UIImage?
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("CAMERA", for: .normal)
        button.addTarget(self, action: #selector(camera), for: .touchUpInside)
        button.setTitleColor(.blue, for: .normal)
        return button
    }()
    
    private lazy var detectorButton: UIButton = {
        let button = UIButton()
        button.setTitle("DETECTOR", for: .normal)
        button.addTarget(self, action: #selector(detector), for: .touchUpInside)
        button.setTitleColor(.blue, for: .normal)
        return button
    }()
    
    private lazy var imageView1: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var imageView2: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var loader: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.color = .blue
        return view
    }()
    
    @objc private func camera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    @objc private func detector() {
        let vc = FaceDetectorViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.delegate = self
        self.present(vc, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        [imageView1, imageView2, button, detectorButton, loader].forEach { view.addSubview($0) }
        button.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        detectorButton.snp.makeConstraints {
            $0.top.equalTo(button.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }
        
        imageView1.snp.makeConstraints {
            $0.top.equalTo(view.snp.topMargin).offset(8)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(button.snp.top).offset(-8)
        }
        
        imageView2.snp.makeConstraints {
            $0.top.equalTo(detectorButton.snp.bottom).offset(8)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(view.snp.bottomMargin).offset(-8)
        }
        
        loader.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 40, height: 40))
            $0.left.equalTo(button.snp.right).offset(8)
            $0.centerY.equalTo(button.snp.centerY)
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let sourceImage = info[.originalImage] as? UIImage else { return }
        self.sourceImage = sourceImage
        self.imageView1.image = self.sourceImage
    }
}

extension ViewController: FaceDetectorViewControllerDelegate {
    func didFoundFace(image: UIImage) {
        let image1 = AWSRekognitionImage()
        image1?.bytes = sourceImage?.jpegData(compressionQuality: 1)
        let image2 = AWSRekognitionImage()
        image2?.bytes = image.jpegData(compressionQuality: 1)
        self.imageView2.image = image
        self.loader.startAnimating()
     
        guard let request = AWSRekognitionCompareFacesRequest() else {
            puts("Unable to initialize AWSRekognitionDetectLabelsRequest.")
            return
        }
        
        request.sourceImage = image1
        request.targetImage = image2
        request.qualityFilter = .high
        
        AWSRekognition.default().compareFaces(request) { response, error in
            DispatchQueue.main.async {
                self.loader.stopAnimating()
                guard let count = response?.faceMatches?.count else {
                    self.view.backgroundColor = .yellow
                    return
                }
                
                if count > 0 { self.view.backgroundColor = .green }
                else { self.view.backgroundColor = .red }
            }
            print(error)
            print(response.debugDescription)
            print(response?.unmatchedFaces?.count)
        }
    }
}
