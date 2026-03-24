//
//  network.swift
//  minip
//
//  Created by ByteDance on 2025/6/26.
//

import Foundation

func getIPAddresses() -> (ipv4: String?, ipv6: String?) {
    var ipv4: String?
    var ipv6: String?

    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return (nil, nil) }
    defer { freeifaddrs(ifaddr) }

    var ptr = ifaddr
    while let interface = ptr {
        let flags = Int32(interface.pointee.ifa_flags)
        var addr = interface.pointee.ifa_addr.pointee

        if (flags & (IFF_UP | IFF_RUNNING | IFF_LOOPBACK))
            == (IFF_UP | IFF_RUNNING)
        {
            if addr.sa_family == UInt8(AF_INET)
                || addr.sa_family == UInt8(AF_INET6)
            {
                let name = String(cString: interface.pointee.ifa_name)

                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(
                        &addr,
                        socklen_t(addr.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        socklen_t(0),
                        NI_NUMERICHOST
                    ) == 0 {
                        let address = String(cString: hostname)

                        if addr.sa_family == UInt8(AF_INET) {
                            ipv4 = address
                        } else {
                            ipv6 = address
                        }
                    }
                }
            }
        }
        ptr = interface.pointee.ifa_next
    }

    return (ipv4, ipv6)
}
