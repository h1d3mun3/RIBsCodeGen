//
// Created by 今入　庸介 on 2022/05/09.
//

import Foundation
import SourceKittenFramework
import Rainbow
import PathKit

private enum RenameProtocolType: CaseIterable {
    case routing, listener, presentable
    
    var suffix: String {
        switch self {
        case .routing:
            return "Routing"
        case .listener:
            return "Listener"
        case .presentable:
            return "Presentable"
        }
    }
}

private enum RenameVariableType: CaseIterable {
    case routing, listener, presentableListener
    
    var suffix: String {
        switch self {
        case .routing:
            return "Routing?"
        case .listener:
            return "Listener?"
        case .presentableListener:
            return "PresentableListener?"
        }
    }
}

private enum RenameInheritedType: CaseIterable {
    case presentableInteractor, interactable, presentableListener
}

final class RenameCommand: Command {
    private let paths: [String]
    private let renameSetting: RenameSetting
    private let currentName: String
    private let newName: String
    
    private let interactorPath: String
    private let routerPath: String
    private let builderPath: String
    private let viewControllerPath: String?
    private let currentDependenciesPath: [String]
    private var parents: [String] = []
    
    private var replacedFilePaths = [String]()
    
    init(paths: [String], renameSetting: RenameSetting, currentName: String, newName: String) {
        self.paths = paths
        self.renameSetting = renameSetting
        self.currentName = currentName
        self.newName = newName
        
        guard !paths.filter({ $0.contains("/" + currentName + "/") }).isEmpty else {
            fatalError("Not found \(currentName) RIB directory.Might be wrong the target name.".red.bold)
        }
        
        guard let interactorPath = paths.filter({ $0.contains("/" + currentName + "Interactor.swift") }).first else {
            fatalError("Not found \(currentName)Interactor.swift in \(currentName) RIB directory.".red.bold)
        }
        
        guard let routerPath = paths.filter({ $0.contains("/" + currentName + "Router.swift") }).first else {
            fatalError("Not found \(currentName)Router.swift in \(currentName) RIB directory.".red.bold)
        }
        
        guard let builderPath = paths.filter({ $0.contains("/" + currentName + "Builder.swift") }).first else {
            fatalError("Not found \(currentName)Builder.swift in \(currentName) RIB directory.".red.bold)
        }
        
        self.interactorPath = interactorPath
        self.routerPath = routerPath
        self.builderPath = builderPath
        viewControllerPath = paths.filter({ $0.contains("/" + currentName + "ViewController.swift") }).first
        currentDependenciesPath = paths.filter({ $0.contains("/" + currentName + "/Dependencies/") })
    }
    
    func run() -> Result {
        print("\nStart renaming ".bold + currentName.applyingBackgroundColor(.magenta).bold + " to ".bold + newName.applyingBackgroundColor(.blue).bold + ".".bold)
    
        var result: Result?
    
        print("\n\tStart renaming codes for related files.".bold)

        getParents()

        do {
            try renameForInteractor()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target Interactor."))
        }
    
        do {
            try renameForRouter()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target Router."))
        }
    
        do {
            try renameForBuilder()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target Builder."))
        }
    
        do {
            try renameForViewController()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target ViewController."))
        }
    
        do {
            try renameForParentsInteractor()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target parent Interactor."))
        }
    
        do {
            try renameForParentsRouter()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target parent Router."))
        }
    
        do {
            try renameForParentsBuilder()
        } catch {
            result = .failure(error: .failedToRename("Failed to rename operation for target parent Builder."))
        }
    
        do {
            try formatAllReplacedFiles()
        } catch {
            result = .failure(error: .failedFormat)
        }
    
        do {
            try renameDirectoriesAndFiles()
        } catch {
            result = .failure(error: .failedFormat)
        }
        
        return result ?? .success(message: "\nSuccessfully finished renaming ".green.bold + currentName.applyingBackgroundColor(.magenta).green.bold + " to ".green.bold + newName.applyingBackgroundColor(.blue).green.bold + " for related files.".green.bold)
    }
}

// MARK: - Run
private extension RenameCommand {
    func getParents() {
        parents = paths
            .filter({ $0.contains("Builder.swift") })
            .filter({ $0.lastElementSplittedBySlash != "\(currentName)Builder.swift" })
            .filter({ [weak self] builderFilePath in
                self?.hasChildConponent(parentBuilderPath: builderFilePath) ?? false
            })
            .map { $0.lastElementSplittedBySlash }
            .map { $0.dropLast("Builder.swift".count) }
            .map { String($0) }
    }
    
    func hasChildConponent(parentBuilderPath: String) -> Bool {
        let parentBuilderFile = File(path: parentBuilderPath)!
        let parentBuilderFileStructure = try! Structure(file: parentBuilderFile)
        print(parentBuilderPath.lastElementSplittedBySlash)
        var parent = parentBuilderPath.lastElementSplittedBySlash
        parent.removeLast("Builder.swift".count)
        
        let parentBuilderClasses = parentBuilderFileStructure.dictionary.getSubStructures().filterByKeyKind(.class)
        
        if let parentComponentClass = parentBuilderClasses.filterByKeyName("\(parent)Component").first,
           let _ = parentComponentClass.getSubStructures().filterByKeyTypeName("\(currentName)Component").first  {
            return true
        } else {
            return false
        }
    }
    
    func renameForInteractor() throws {
        print("\t\trename for \(interactorPath.lastElementSplittedBySlash)")
        let text = try String.init(contentsOfFile: interactorPath, encoding: .utf8)
        let replacedText = renameSetting.interactor.reduce(text) { (result, interactorSearchText) in
            let searchText = replacePlaceHolder(for: interactorSearchText, with: currentName)
            let replaceText = replacePlaceHolder(for: interactorSearchText, with: newName)
            return result.replacingOccurrences(of: searchText, with: replaceText)
        }
     
        try Path(interactorPath).write(replacedText)
        replacedFilePaths.append(interactorPath)
    }
    
    func renameForRouter() throws {
        print("\t\trename for \(routerPath.lastElementSplittedBySlash)")
        let text = try String.init(contentsOfFile: routerPath, encoding: .utf8)
        let replacedText = renameSetting.router.reduce(text) { (result, routerSearchText) in
            let searchText = replacePlaceHolder(for: routerSearchText, with: currentName)
            let replaceText = replacePlaceHolder(for: routerSearchText, with: newName)
            return result.replacingOccurrences(of: searchText, with: replaceText)
        }
        try Path(routerPath).write(replacedText)
        replacedFilePaths.append(routerPath)
    }
    
    func renameForBuilder() throws {
        print("\t\trename for \(builderPath.lastElementSplittedBySlash)")
        let text = try String.init(contentsOfFile: builderPath, encoding: .utf8)
        let replacedText = renameSetting.builder.reduce(text) { (result, builderSearchText) in
            let searchText = replacePlaceHolder(for: builderSearchText, with: currentName)
            let replaceText = replacePlaceHolder(for: builderSearchText, with: newName)
            return result.replacingOccurrences(of: searchText, with: replaceText)
        }
        
        try Path(builderPath).write(replacedText)
        replacedFilePaths.append(builderPath)
    }
    
    func renameForViewController() throws {
        guard let viewControllerPath = viewControllerPath else {
            return
        }
        print("\t\trename for \(viewControllerPath.lastElementSplittedBySlash)")
        let text = try String.init(contentsOfFile: viewControllerPath, encoding: .utf8)
        let replacedText = renameSetting.viewController.reduce(text) { (result, viewControllerSearchText) in
            let searchText = replacePlaceHolder(for: viewControllerSearchText, with: currentName)
            let replaceText = replacePlaceHolder(for: viewControllerSearchText, with: newName)
            return result.replacingOccurrences(of: searchText, with: replaceText)
        }
        
        try Path(viewControllerPath).write(replacedText)
        replacedFilePaths.append(viewControllerPath)
    }
    
    func renameForParentsInteractor() throws {
        try parents.forEach { parentName in
            guard let parentInteractorPath = paths.filter({ $0.contains("/" + parentName + "Interactor.swift") }).first else {
                print("Not found \(parentName)Interactor.swift in \(parentName) RIB directory.".red.bold)
                print("Skip to rename codes in \(parentName)Interactor.swift.".yellow.bold)
                return
            }
    
            print("\t\trename for \(parentInteractorPath.lastElementSplittedBySlash)")
            let text = try String.init(contentsOfFile: parentInteractorPath, encoding: .utf8)
            let replacedText = renameSetting.parentInteractor.reduce(text) { (result, parentInteractorSearchText) in
                let searchText = replacePlaceHolder(for: parentInteractorSearchText, with: currentName, and: parentName)
                let replaceText = replacePlaceHolder(for: parentInteractorSearchText, with: newName, and: parentName)
                return result.replacingOccurrences(of: searchText, with: replaceText)
            }
            
            try Path(parentInteractorPath).write(replacedText)
            replacedFilePaths.append(parentInteractorPath)
        }
    }
    
    func renameForParentsRouter() throws {
        try parents.forEach { parentName in
            guard let parentRouterPath = paths.filter({ $0.contains("/" + parentName + "Router.swift") }).first else {
                print("Not found \(parentName)Router.swift in \(parentName) RIB directory.".red.bold)
                print("Skip to rename codes in \(parentName)Router.swift.".yellow.bold)
                return
            }
    
            print("\t\trename for \(parentRouterPath.lastElementSplittedBySlash)")
            let text = try String.init(contentsOfFile: parentRouterPath, encoding: .utf8)
            let replacedText = renameSetting.parentRouter.reduce(text) { (result, parentRouterSearchText) in
                let searchText = replacePlaceHolder(for: parentRouterSearchText, with: currentName, and: parentName)
                let replaceText = replacePlaceHolder(for: parentRouterSearchText, with: newName, and: parentName)
                return result.replacingOccurrences(of: searchText, with: replaceText)
            }
            
            try Path(parentRouterPath).write(replacedText)
            replacedFilePaths.append(parentRouterPath)
        }
    }
    
    func renameForParentsBuilder() throws {
        try parents.forEach { parentName in
            guard let parentBuilderPath = paths.filter({ $0.contains("/" + parentName + "Builder.swift") }).first else {
                print("Not found \(parentName)Builder.swift in \(parentName) RIB directory.".red.bold)
                print("Skip to rename codes in \(parentName)Builder.swift.".yellow.bold)
                return
            }
    
            print("\t\trename for \(parentBuilderPath.lastElementSplittedBySlash)")
            let text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)
            let replacedText = renameSetting.parentBuilder.reduce(text) { (result, parentBuilderSearchText) in
                let searchText = replacePlaceHolder(for: parentBuilderSearchText, with: currentName, and: parentName)
                let replaceText = replacePlaceHolder(for: parentBuilderSearchText, with: newName, and: parentName)
                return result.replacingOccurrences(of: searchText, with: replaceText)
            }
            
            try Path(parentBuilderPath).write(replacedText)
            replacedFilePaths.append(parentBuilderPath)
        }
    }
    
    func formatAllReplacedFiles() throws {
        print("\n\tStart format for all replaced files.".bold)
        try replacedFilePaths.forEach { replacedFilePath in
            print("\t\tformat for \(replacedFilePath.lastElementSplittedBySlash)")
            let formattedText = try Formatter.format(path: replacedFilePath)
            try Path(replacedFilePath).write(formattedText)
        }
    }
    
    func renameDirectoriesAndFiles() throws {
        print("\n\tStart renaming directories and files.".bold)
        
        // for target RIB
        let targetRIBDirectoryPath = Path(interactorPath).parent()
        guard targetRIBDirectoryPath.isDirectory else {
            print("\t\tFailed to detect target RIB directory path.".red.bold)
            return
        }

        let newDirectoryPath = Path(targetRIBDirectoryPath.parent().description + "/\(newName)")
        try newDirectoryPath.mkdir()
        print("\t\tNew directory was created.")
        print("\t\t\t\(newDirectoryPath.relativePath)".lightBlack)
        
        let newInteractorPath = Path(newDirectoryPath.description + "/" + interactorPath.lastElementSplittedBySlash.replacingOccurrences(of: currentName, with: newName))
        try Path(interactorPath).move(newInteractorPath)
        print("\t\tInteractor file was renamed and moved to new directory.")
        print("\t\t\t\(newInteractorPath.relativePath)".lightBlack)
        
        let newRouterPath = Path(newDirectoryPath.description + "/" + routerPath.lastElementSplittedBySlash.replacingOccurrences(of: currentName, with: newName))
        try Path(routerPath).move(newRouterPath)
        print("\t\tRouter file was renamed and moved to new directory.")
        print("\t\t\t\(newRouterPath.relativePath)".lightBlack)
        
        let newBuilderPath = Path(newDirectoryPath.description + "/" + builderPath.lastElementSplittedBySlash.replacingOccurrences(of: currentName, with: newName))
        try Path(builderPath).move(newBuilderPath)
        print("\t\tBuilder file was renamed and moved to new directory.")
        print("\t\t\t\(newBuilderPath.relativePath)".lightBlack)
        
        if let viewControllerPath = viewControllerPath {
            let newViewControllerPath = Path(newDirectoryPath.description + "/" + viewControllerPath.lastElementSplittedBySlash.replacingOccurrences(of: currentName, with: newName))
            try Path(viewControllerPath).move(newViewControllerPath)
            print("\t\tViewController file was renamed and moved to new directory.")
            print("\t\t\t\(newViewControllerPath.relativePath)".lightBlack)
        }
    
        if try targetRIBDirectoryPath.children().isEmpty {
            try targetRIBDirectoryPath.delete()
            print("\t\t\(currentName) directory was removed because its files no longer exists.")
            print("\t\t\t\(targetRIBDirectoryPath.relativePath)".lightBlack)
        }
        
        // for parent RIBs
        try parents.forEach { parentName in
            guard let parentInteractorPath = paths.filter({ $0.contains("/" + parentName + "Interactor.swift") }).first else {
                print("Not found \(parentName)Interactor.swift in \(parentName) RIB directory.".red.bold)
                print("Skip to rename codes in \(parentName)Interactor.swift.".yellow.bold)
                return
            }
            let parentRIBDirectoryPath = Path(parentInteractorPath).parent()
            guard parentRIBDirectoryPath.isDirectory else {
                print("Failed to detect target parent RIB \(parentName) directory path.".red.bold)
                return
            }
        }
        
    }
}

// MARK: - Internal extensions
private extension RenameCommand {
    func replacePlaceHolder(for target: String, with ribName: String) -> String {
        target
            .replacingOccurrences(of: "__RIB_NAME_LOWER_CASED_FIRST_LETTER__", with: ribName.lowercasedFirstLetter())
            .replacingOccurrences(of: "__RIB_NAME__", with: ribName)
    }
    
    func replacePlaceHolder(for target: String, with ribName: String, and parentRIBName: String) -> String {
        target
            .replacingOccurrences(of: "__RIB_NAME_LOWER_CASED_FIRST_LETTER__", with: ribName.lowercasedFirstLetter())
            .replacingOccurrences(of: "__PARENT_RIB_NAME__", with: parentRIBName)
            .replacingOccurrences(of: "__RIB_NAME__", with: ribName)
    }
}

private extension String {
    var lastElementSplittedBySlash: String {
        String(self.split(separator: "/").last ?? "")
    }
}

private extension Path {
    var relativePath: String {
        self.description.replacingOccurrences(of: ".*\(setting.targetDirectory)", with: setting.targetDirectory, options: .regularExpression)
    }
}
