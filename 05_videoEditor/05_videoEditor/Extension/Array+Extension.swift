//
//  Array+Extension.swift
//  05_videoEditor
//
//  Created by sy on 2020/5/29.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation

extension Array where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
