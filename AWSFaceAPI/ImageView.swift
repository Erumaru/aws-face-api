//
//  ImageView.swift
//  AWSFaceAPI
//
//  Created by Abzal Toremuratuly on 23.04.2021.
//

import UIKit

class ImageView: UIImageView {
    private let x, y, h, w: Double
    init(image: UIImage, x: Double, y: Double, h: Double, w: Double) {
        self.x = x
        self.y = y
        self.h = h
        self.w = w
        super.init(image: image)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
