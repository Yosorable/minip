//
//  QRScannerError.swift
//  minip
//
//  Created by LZY on 2025/2/13.
//

import AVFoundation
import Foundation

public enum QRScannerError: Error {
    case unauthorized(AVAuthorizationStatus)
    case deviceFailure(DeviceError)
    case readFailure
    case unknown

    public enum DeviceError {
        case videoUnavailable
        case inputInvalid
        case metadataOutputFailure
        case videoDataOutputFailure
    }
}
