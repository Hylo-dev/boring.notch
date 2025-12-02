//
//  SliderColorEnum.swift
//  boringNotch
//  Created by Harsh Vardhan  Goswami  on 04/08/24.
//  Modified by Eliomar Alejandro Rodriguez Ferrer on 01/12/25.
//

import Defaults

enum SliderColorEnum: String, CaseIterable, Defaults.Serializable {
    case white = "White"
    case albumArt = "Match album art"
    case accent = "Accent color"
}
