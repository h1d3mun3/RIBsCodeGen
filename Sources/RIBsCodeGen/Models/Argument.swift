//
//  Argument.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/08.
//

import Foundation

enum Action {
    case add(String), link(String), scaffold(String), rename(String), unlink(String), remove(String), help

    init(name: String, target: String?) {
        switch name {
        case "add":
            if let target = target {
                self = .add(target)
            } else {
                self = .help
            }
        case "link":
            if let target = target {
                self = .link(target)
            } else {
                self = .help
            }
        case "scaffold":
            if let target = target {
                self = .scaffold(target)
            } else {
                self = .help
            }
        case "rename":
            if let target = target {
                self = .rename(target)
            } else {
                self = .help
            }
        case "unlink":
            if let target = target {
                self = .unlink(target)
            } else {
                self = .help
            }
        case "remove":
            if let target = target {
                self = .remove(target)
            } else {
                self = .help
            }
        case "help":
            self = .help
        default:
            self = .help
        }
    }
}

struct Argument: CustomStringConvertible {
    let action: Action
    let options: [String:String]

    var description: String {
        "action: \(action), options: \(options)"
    }
}

extension Argument {
    var hasParent: Bool {
        options["parent"]?.isEmpty == false // "--parent xxx 「xxx」のチェック"
    }

    var parent: String {
        guard let parentString = options["parent"] else {
            fatalError("--parent is needed.".bold.red)
        }
        return parentString
    }

    var noView: Bool {
        options["noview"] != nil // "--noview の存在有無"
    }

    var needle: Bool {
        options["needle"] != nil // "--needleの存在有無"
    }

    var actionTarget: String {
        switch action {
        case let .add(target):
            return target
        case let .link(target):
            return target
        case let .scaffold(target):
            return target
        case let .rename(target):
            return target
        case let .unlink(target):
            return target
        case let .remove(target):
            return target
        case .help:
            return ""
        }
    }
}
