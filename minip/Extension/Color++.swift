//
//  Color++.swift
//  minip
//
//  Created by ByteDance on 2023/7/8.
//

import SwiftUI

extension Color {
    init?(hexOrCSSName: String) {
        if let uiColor = UIColor(hexOrCSSName: hexOrCSSName) {
            self.init(uiColor)
        } else {
            return nil
        }
    }
}

extension UIColor {
    private static let CSS3ColorMap: [String: UIColor] = [
        "aliceblue": UIColor(red: 240/255, green: 248/255, blue: 255/255, alpha: 1.0),
        "antiquewhite": UIColor(red: 250/255, green: 235/255, blue: 215/255, alpha: 1.0),
        "aqua": UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha: 1.0),
        "aquamarine": UIColor(red: 127/255, green: 255/255, blue: 212/255, alpha: 1.0),
        "azure": UIColor(red: 240/255, green: 255/255, blue: 255/255, alpha: 1.0),
        "beige": UIColor(red: 245/255, green: 245/255, blue: 220/255, alpha: 1.0),
        "bisque": UIColor(red: 255/255, green: 228/255, blue: 196/255, alpha: 1.0),
        "black": UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0),
        "blanchedalmond": UIColor(red: 255/255, green: 235/255, blue: 205/255, alpha: 1.0),
        "blue": UIColor(red: 0/255, green: 0/255, blue: 255/255, alpha: 1.0),
        "blueviolet": UIColor(red: 138/255, green: 43/255, blue: 226/255, alpha: 1.0),
        "brown": UIColor(red: 165/255, green: 42/255, blue: 42/255, alpha: 1.0),
        "burlywood": UIColor(red: 222/255, green: 184/255, blue: 135/255, alpha: 1.0),
        "cadetblue": UIColor(red: 95/255, green: 158/255, blue: 160/255, alpha: 1.0),
        "chartreuse": UIColor(red: 127/255, green: 255/255, blue: 0/255, alpha: 1.0),
        "chocolate": UIColor(red: 210/255, green: 105/255, blue: 30/255, alpha: 1.0),
        "coral": UIColor(red: 255/255, green: 127/255, blue: 80/255, alpha: 1.0),
        "cornflowerblue": UIColor(red: 100/255, green: 149/255, blue: 237/255, alpha: 1.0),
        "cornsilk": UIColor(red: 255/255, green: 248/255, blue: 220/255, alpha: 1.0),
        "crimson": UIColor(red: 220/255, green: 20/255, blue: 60/255, alpha: 1.0),
        "cyan": UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha: 1.0),
        "darkblue": UIColor(red: 0/255, green: 0/255, blue: 139/255, alpha: 1.0),
        "darkcyan": UIColor(red: 0/255, green: 139/255, blue: 139/255, alpha: 1.0),
        "darkgoldenrod": UIColor(red: 184/255, green: 134/255, blue: 11/255, alpha: 1.0),
        "darkgray": UIColor(red: 169/255, green: 169/255, blue: 169/255, alpha: 1.0),
        "darkgreen": UIColor(red: 0/255, green: 100/255, blue: 0/255, alpha: 1.0),
        "darkgrey": UIColor(red: 169/255, green: 169/255, blue: 169/255, alpha: 1.0),
        "darkkhaki": UIColor(red: 189/255, green: 183/255, blue: 107/255, alpha: 1.0),
        "darkmagenta": UIColor(red: 139/255, green: 0/255, blue: 139/255, alpha: 1.0),
        "darkolivegreen": UIColor(red: 85/255, green: 107/255, blue: 47/255, alpha: 1.0),
        "darkorange": UIColor(red: 255/255, green: 140/255, blue: 0/255, alpha: 1.0),
        "darkorchid": UIColor(red: 153/255, green: 50/255, blue: 204/255, alpha: 1.0),
        "darkred": UIColor(red: 139/255, green: 0/255, blue: 0/255, alpha: 1.0),
        "darksalmon": UIColor(red: 233/255, green: 150/255, blue: 122/255, alpha: 1.0),
        "darkseagreen": UIColor(red: 143/255, green: 188/255, blue: 143/255, alpha: 1.0),
        "darkslateblue": UIColor(red: 72/255, green: 61/255, blue: 139/255, alpha: 1.0),
        "darkslategray": UIColor(red: 47/255, green: 79/255, blue: 79/255, alpha: 1.0),
        "darkslategrey": UIColor(red: 47/255, green: 79/255, blue: 79/255, alpha: 1.0),
        "darkturquoise": UIColor(red: 0/255, green: 206/255, blue: 209/255, alpha: 1.0),
        "darkviolet": UIColor(red: 148/255, green: 0/255, blue: 211/255, alpha: 1.0),
        "deeppink": UIColor(red: 255/255, green: 20/255, blue: 147/255, alpha: 1.0),
        "deepskyblue": UIColor(red: 0/255, green: 191/255, blue: 255/255, alpha: 1.0),
        "dimgray": UIColor(red: 105/255, green: 105/255, blue: 105/255, alpha: 1.0),
        "dimgrey": UIColor(red: 105/255, green: 105/255, blue: 105/255, alpha: 1.0),
        "dodgerblue": UIColor(red: 30/255, green: 144/255, blue: 255/255, alpha: 1.0),
        "firebrick": UIColor(red: 178/255, green: 34/255, blue: 34/255, alpha: 1.0),
        "floralwhite": UIColor(red: 255/255, green: 250/255, blue: 240/255, alpha: 1.0),
        "forestgreen": UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 1.0),
        "fuchsia": UIColor(red: 255/255, green: 0/255, blue: 255/255, alpha: 1.0),
        "gainsboro": UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1.0),
        "ghostwhite": UIColor(red: 248/255, green: 248/255, blue: 255/255, alpha: 1.0),
        "gold": UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0),
        "goldenrod": UIColor(red: 218/255, green: 165/255, blue: 32/255, alpha: 1.0),
        "gray": UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1.0),
        "green": UIColor(red: 0/255, green: 128/255, blue: 0/255, alpha: 1.0),
        "greenyellow": UIColor(red: 173/255, green: 255/255, blue: 47/255, alpha: 1.0),
        "grey": UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1.0),
        "honeydew": UIColor(red: 240/255, green: 255/255, blue: 240/255, alpha: 1.0),
        "hotpink": UIColor(red: 255/255, green: 105/255, blue: 180/255, alpha: 1.0),
        "indianred": UIColor(red: 205/255, green: 92/255, blue: 92/255, alpha: 1.0),
        "indigo": UIColor(red: 75/255, green: 0/255, blue: 130/255, alpha: 1.0),
        "ivory": UIColor(red: 255/255, green: 255/255, blue: 240/255, alpha: 1.0),
        "khaki": UIColor(red: 240/255, green: 230/255, blue: 140/255, alpha: 1.0),
        "lavender": UIColor(red: 230/255, green: 230/255, blue: 250/255, alpha: 1.0),
        "lavenderblush": UIColor(red: 255/255, green: 240/255, blue: 245/255, alpha: 1.0),
        "lawngreen": UIColor(red: 124/255, green: 252/255, blue: 0/255, alpha: 1.0),
        "lemonchiffon": UIColor(red: 255/255, green: 250/255, blue: 205/255, alpha: 1.0),
        "lightblue": UIColor(red: 173/255, green: 216/255, blue: 230/255, alpha: 1.0),
        "lightcoral": UIColor(red: 240/255, green: 128/255, blue: 128/255, alpha: 1.0),
        "lightcyan": UIColor(red: 224/255, green: 255/255, blue: 255/255, alpha: 1.0),
        "lightgoldenrodyellow": UIColor(red: 250/255, green: 250/255, blue: 210/255, alpha: 1.0),
        "lightgray": UIColor(red: 211/255, green: 211/255, blue: 211/255, alpha: 1.0),
        "lightgreen": UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 1.0),
        "lightgrey": UIColor(red: 211/255, green: 211/255, blue: 211/255, alpha: 1.0),
        "lightpink": UIColor(red: 255/255, green: 182/255, blue: 193/255, alpha: 1.0),
        "lightsalmon": UIColor(red: 255/255, green: 160/255, blue: 122/255, alpha: 1.0),
        "lightseagreen": UIColor(red: 32/255, green: 178/255, blue: 170/255, alpha: 1.0),
        "lightskyblue": UIColor(red: 135/255, green: 206/255, blue: 250/255, alpha: 1.0),
        "lightslategray": UIColor(red: 119/255, green: 136/255, blue: 153/255, alpha: 1.0),
        "lightslategrey": UIColor(red: 119/255, green: 136/255, blue: 153/255, alpha: 1.0),
        "lightsteelblue": UIColor(red: 176/255, green: 196/255, blue: 222/255, alpha: 1.0),
        "lightyellow": UIColor(red: 255/255, green: 255/255, blue: 224/255, alpha: 1.0),
        "lime": UIColor(red: 0/255, green: 255/255, blue: 0/255, alpha: 1.0),
        "limegreen": UIColor(red: 50/255, green: 205/255, blue: 50/255, alpha: 1.0),
        "linen": UIColor(red: 250/255, green: 240/255, blue: 230/255, alpha: 1.0),
        "magenta": UIColor(red: 255/255, green: 0/255, blue: 255/255, alpha: 1.0),
        "maroon": UIColor(red: 128/255, green: 0/255, blue: 0/255, alpha: 1.0),
        "mediumaquamarine": UIColor(red: 102/255, green: 205/255, blue: 170/255, alpha: 1.0),
        "mediumblue": UIColor(red: 0/255, green: 0/255, blue: 205/255, alpha: 1.0),
        "mediumorchid": UIColor(red: 186/255, green: 85/255, blue: 211/255, alpha: 1.0),
        "mediumpurple": UIColor(red: 147/255, green: 112/255, blue: 219/255, alpha: 1.0),
        "mediumseagreen": UIColor(red: 60/255, green: 179/255, blue: 113/255, alpha: 1.0),
        "mediumslateblue": UIColor(red: 123/255, green: 104/255, blue: 238/255, alpha: 1.0),
        "mediumspringgreen": UIColor(red: 0/255, green: 250/255, blue: 154/255, alpha: 1.0),
        "mediumturquoise": UIColor(red: 72/255, green: 209/255, blue: 204/255, alpha: 1.0),
        "mediumvioletred": UIColor(red: 199/255, green: 21/255, blue: 133/255, alpha: 1.0),
        "midnightblue": UIColor(red: 25/255, green: 25/255, blue: 112/255, alpha: 1.0),
        "mintcream": UIColor(red: 245/255, green: 255/255, blue: 250/255, alpha: 1.0),
        "mistyrose": UIColor(red: 255/255, green: 228/255, blue: 225/255, alpha: 1.0),
        "moccasin": UIColor(red: 255/255, green: 228/255, blue: 181/255, alpha: 1.0),
        "navajowhite": UIColor(red: 255/255, green: 222/255, blue: 173/255, alpha: 1.0),
        "navy": UIColor(red: 0/255, green: 0/255, blue: 128/255, alpha: 1.0),
        "oldlace": UIColor(red: 253/255, green: 245/255, blue: 230/255, alpha: 1.0),
        "olive": UIColor(red: 128/255, green: 128/255, blue: 0/255, alpha: 1.0),
        "olivedrab": UIColor(red: 107/255, green: 142/255, blue: 35/255, alpha: 1.0),
        "orange": UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1.0),
        "orangered": UIColor(red: 255/255, green: 69/255, blue: 0/255, alpha: 1.0),
        "orchid": UIColor(red: 218/255, green: 112/255, blue: 214/255, alpha: 1.0),
        "palegoldenrod": UIColor(red: 238/255, green: 232/255, blue: 170/255, alpha: 1.0),
        "palegreen": UIColor(red: 152/255, green: 251/255, blue: 152/255, alpha: 1.0),
        "paleturquoise": UIColor(red: 175/255, green: 238/255, blue: 238/255, alpha: 1.0),
        "palevioletred": UIColor(red: 219/255, green: 112/255, blue: 147/255, alpha: 1.0),
        "papayawhip": UIColor(red: 255/255, green: 239/255, blue: 213/255, alpha: 1.0),
        "peachpuff": UIColor(red: 255/255, green: 218/255, blue: 185/255, alpha: 1.0),
        "peru": UIColor(red: 205/255, green: 133/255, blue: 63/255, alpha: 1.0),
        "pink": UIColor(red: 255/255, green: 192/255, blue: 203/255, alpha: 1.0),
        "plum": UIColor(red: 221/255, green: 160/255, blue: 221/255, alpha: 1.0),
        "powderblue": UIColor(red: 176/255, green: 224/255, blue: 230/255, alpha: 1.0),
        "purple": UIColor(red: 128/255, green: 0/255, blue: 128/255, alpha: 1.0),
        "red": UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1.0),
        "rosybrown": UIColor(red: 188/255, green: 143/255, blue: 143/255, alpha: 1.0),
        "royalblue": UIColor(red: 65/255, green: 105/255, blue: 225/255, alpha: 1.0),
        "saddlebrown": UIColor(red: 139/255, green: 69/255, blue: 19/255, alpha: 1.0),
        "salmon": UIColor(red: 250/255, green: 128/255, blue: 114/255, alpha: 1.0),
        "sandybrown": UIColor(red: 244/255, green: 164/255, blue: 96/255, alpha: 1.0),
        "seagreen": UIColor(red: 46/255, green: 139/255, blue: 87/255, alpha: 1.0),
        "seashell": UIColor(red: 255/255, green: 245/255, blue: 238/255, alpha: 1.0),
        "sienna": UIColor(red: 160/255, green: 82/255, blue: 45/255, alpha: 1.0),
        "silver": UIColor(red: 192/255, green: 192/255, blue: 192/255, alpha: 1.0),
        "skyblue": UIColor(red: 135/255, green: 206/255, blue: 235/255, alpha: 1.0),
        "slateblue": UIColor(red: 106/255, green: 90/255, blue: 205/255, alpha: 1.0),
        "slategray": UIColor(red: 112/255, green: 128/255, blue: 144/255, alpha: 1.0),
        "slategrey": UIColor(red: 112/255, green: 128/255, blue: 144/255, alpha: 1.0),
        "snow": UIColor(red: 255/255, green: 250/255, blue: 250/255, alpha: 1.0),
        "springgreen": UIColor(red: 0/255, green: 255/255, blue: 127/255, alpha: 1.0),
        "steelblue": UIColor(red: 70/255, green: 130/255, blue: 180/255, alpha: 1.0),
        "tan": UIColor(red: 210/255, green: 180/255, blue: 140/255, alpha: 1.0),
        "teal": UIColor(red: 0/255, green: 128/255, blue: 128/255, alpha: 1.0),
        "thistle": UIColor(red: 216/255, green: 191/255, blue: 216/255, alpha: 1.0),
        "tomato": UIColor(red: 255/255, green: 99/255, blue: 71/255, alpha: 1.0),
        "turquoise": UIColor(red: 64/255, green: 224/255, blue: 208/255, alpha: 1.0),
        "violet": UIColor(red: 238/255, green: 130/255, blue: 238/255, alpha: 1.0),
        "wheat": UIColor(red: 245/255, green: 222/255, blue: 179/255, alpha: 1.0),
        "white": UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0),
        "whitesmoke": UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0),
        "yellow": UIColor(red: 255/255, green: 255/255, blue: 0/255, alpha: 1.0),
        "yellowgreen": UIColor(red: 154/255, green: 205/255, blue: 50/255, alpha: 1.0),
    ]

    convenience init?(hexOrCSSName: String) {
        if hexOrCSSName.hasPrefix("#") {
            self.init(hex: hexOrCSSName)
        } else if let uiColor = Self.CSS3ColorMap[hexOrCSSName] {
            self.init(cgColor: uiColor.cgColor)
        } else {
            return nil
        }
    }

    private convenience init?(hex: String) {
        var str = hex
        if str.hasPrefix("#") {
            str.removeFirst()
        }
        if str.count == 3 {
            str = String(repeating: str[str.startIndex], count: 2)
                + String(repeating: str[str.index(str.startIndex, offsetBy: 1)], count: 2)
                + String(repeating: str[str.index(str.startIndex, offsetBy: 2)], count: 2)
        } else if !str.count.isMultiple(of: 2) || str.count > 8 {
            return nil
        }
        let scanner = Scanner(string: str)
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        if str.count == 2 {
            let gray = Double(Int(color) & 0xFF)/255
            self.init(red: gray, green: gray, blue: gray, alpha: 1)
        } else if str.count == 4 {
            let gray = Double(Int(color >> 8) & 0x00FF)/255
            let alpha = Double(Int(color) & 0x00FF)/255
            self.init(red: gray, green: gray, blue: gray, alpha: alpha)
        } else if str.count == 6 {
            let red = Double(Int(color >> 16) & 0x0000FF)/255
            let green = Double(Int(color >> 8) & 0x0000FF)/255
            let blue = Double(Int(color) & 0x0000FF)/255
            self.init(red: red, green: green, blue: blue, alpha: 1)
        } else if str.count == 8 {
            let red = Double(Int(color >> 24) & 0x000000FF)/255
            let green = Double(Int(color >> 16) & 0x000000FF)/255
            let blue = Double(Int(color >> 8) & 0x000000FF)/255
            let alpha = Double(Int(color) & 0x000000FF)/255
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        } else {
            return nil
        }
    }

    convenience init?(light: UIColor?, dark: UIColor?) {
        var lightColor = light ?? dark
        var darkColor = dark ?? light
        if let lc = lightColor, let dc = darkColor {
            self.init { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    dc
                } else {
                    lc
                }
            }
        } else {
            return nil
        }
    }
}
