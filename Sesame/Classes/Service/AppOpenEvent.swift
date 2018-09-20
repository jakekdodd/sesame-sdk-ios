//
//  AppOpenEvent.swift
//  Sesame
//
//  Created by Akash Desai on 8/20/18.
//

import Foundation

/// App Open actions provide crucial information about the user’s journey, such as motivation and cue,
/// that  we can use to design good habits.
/// This struct stores the action and also its cue.
/// A reward can then adjust according to what cued the user to open the app.
///
struct AppOpenEvent {

    enum Source {
        case  `default`, shortcut, deepLink, notification

        public var cueCategory: Cue.Category {
            switch self {
            case .default, .shortcut:
                return .internal

            case .deepLink:
                return .external

            case .notification:
                return .synthetic
            }
        }
    }

    let date: Date
    var name: String { return BMSEvent.AppOpenName }
    var metadata = [String: Any]()
    let source: Source
    var cueCategory: Cue.Category {
        return source.cueCategory
    }

    init(source: Source, date: Date = Date()) {
        self.source = source
        self.date = date
    }

}
