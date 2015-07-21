//
//  UIImage+Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 8/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

extension UIImage {

    func hnk_imageByScalingToSize(toSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(toSize, !hnk_hasAlpha(), 0.0)
        drawInRect(CGRectMake(0, 0, toSize.width, toSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

    func hnk_hasAlpha() -> Bool {
        let alpha = CGImageGetAlphaInfo(self.CGImage)
        switch alpha {
        case .First, .Last, .PremultipliedFirst, .PremultipliedLast, .Only:
            return true
        case .None, .NoneSkipFirst, .NoneSkipLast:
            return false
        }
    }
    
    func hnk_data(compressionQuality: Float = 1.0) -> NSData! {
        let hasAlpha = self.hnk_hasAlpha()
        let data = hasAlpha ? UIImagePNGRepresentation(self) : UIImageJPEGRepresentation(self, CGFloat(compressionQuality))
        return data
    }
    
    func hnk_decompressedImage() -> UIImage! {
        let originalImageRef = self.CGImage
        let originalBitmapInfo = CGImageGetBitmapInfo(originalImageRef)
        let alphaInfo = CGImageGetAlphaInfo(originalImageRef)
        
        // See: http://stackoverflow.com/questions/23723564/which-cgimagealphainfo-should-we-use
        let bitmapInfo = originalBitmapInfo
        switch (alphaInfo) {
        case .None:
            bitmapInfo.union([CGBitmapInfo.AlphaInfoMask])
//            bitmapInfo = (bitmapInfo)[CGImageAlphaInfo.NoneSkipFirst]
        case .PremultipliedFirst, .PremultipliedLast, .NoneSkipFirst, .NoneSkipLast:
            break
        case .Only, .Last, .First: // Unsupported
            return self
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let pixelSize = CGSizeMake(self.size.width * self.scale, self.size.height * self.scale)
        
        //func CGBitmapContextCreate(data: UnsafeMutablePointer<Void>, _ width: Int, _ height: Int, _ bitsPerComponent: Int, _ bytesPerRow: Int, _ space: CGColorSpace!, _ bitmapInfo: UInt32) -> CGContext!
        if let context = CGBitmapContextCreate(nil, Int(ceil(pixelSize.width)), Int(ceil(pixelSize.height)), CGImageGetBitsPerComponent(originalImageRef) as Int, 0, colorSpace as CGColorSpace!, bitmapInfo.rawValue) {
            
            let imageRect = CGRectMake(0, 0, pixelSize.width, pixelSize.height)
            UIGraphicsPushContext(context)
            
            // Flip coordinate system. See: http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage
            CGContextTranslateCTM(context, 0, pixelSize.height)
            CGContextScaleCTM(context, 1.0, -1.0)
            
            // UIImage and drawInRect takes into account image orientation, unlike CGContextDrawImage.
            self.drawInRect(imageRect)
            UIGraphicsPopContext()
            let decompressedImageRef = CGBitmapContextCreateImage(context)
            
            let scale = UIScreen.mainScreen().scale
            let image = UIImage(CGImage: decompressedImageRef!, scale:scale, orientation:UIImageOrientation.Up)
            
            return image
            
        } else {
            return self
        }
    }
    
}
