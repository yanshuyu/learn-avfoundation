//
//  CompositionGenerator.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/25.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation

protocol CompositionGenerator {
    func buildPlayerItem() -> AVPlayerItem?
    func buildExportSessiom() -> AVAssetExportSession?
    func buildImageGenerator() -> AVAssetImageGenerator?
}
