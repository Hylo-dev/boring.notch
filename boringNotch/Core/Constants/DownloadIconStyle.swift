//
//  DownloadIconStyle.swift
//  boringNotch
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 01/12/25.
//

import Defaults

enum DownloadIconStyle: String, Defaults.Serializable {
    case onlyAppIcon = "Only app icon"
    case onlyIcon = "Only download icon"
    case iconAndAppIcon = "Icon and app icon"
}
