//
//  logger.swift
//  minip
//
//  Created by LZY on 2024/4/27.
//

import Foundation
import OSLog
import FlyingSocks

let logger = Logger()


public final class LoggerForFlyingFox: Logging {
    let prefix: String
    init(prefix: String = "http-server") {
        self.prefix = prefix
    }
    public func logDebug(_ debug: @autoclosure () -> String) {
#if DEBUG
        let msg = debug()
        logger.debug("[\(self.prefix)] \(msg)")
#endif
    }
    
    public func logInfo(_ info: @autoclosure () -> String) {
#if DEBUG
        let msg = info()
        logger.info("[\(self.prefix)] \(msg)")
#endif
    }
    
    public func logWarning(_ warning: @autoclosure () -> String) {
#if DEBUG
        let msg = warning()
        logger.warning("[\(self.prefix)] \(msg)")
#endif
    }
    
    public func logError(_ error: @autoclosure () -> String) {
        let msg = error()
        logger.error("[\(self.prefix)] \(msg)")
    }
    
    public func logCritical(_ critical: @autoclosure () -> String) {
        let msg = critical()
        logger.critical("[\(self.prefix)] \(msg)")
    }
}
