<div align="center">
  <img src="images/logo.png" width="800">
</div>

# RIBsCodeGen
RIBsCodeGen generates [RIBs](https://github.com/uber/RIBs) boilerplate. Router, Interactor, Builder and ViewController are created automatically following its templates.

This tool also resolves the dependencies between parent and child RIB. Not only add the ComponentExtension file but also add the child listener and builder to parent Router, Builder. 

Additionally, the operation is enable to run for multiple RIBs. If writes the RIBs tree by Markdown list style, this tool generates all RIBs following the tree. 

Let's save time to create RIBs as much as possible.

# Features

- [x] Generate Router, Interactor, Builder, ViewController following template
- [x] Generate ComponentExtension following template
- [x] Add child listener and builder to parent Router and Builder file
- [x] Bulk generation following RIBs tree
- [x] Remove the RIB and the related codes
- [x] Rename the RIB directories, files and the related codes
  - [x] Customise rename targets


# Settings

add `.ribscodegen` file to the current directory the operation runs. RIBsCodeGen loads this setting file before runs the below commands.

```
targetDirectory: "Sample"
templateDirectory: "Templates"
```

`targetDirectory` is RIBs source codes directory. This tool loads RIBs files under the target directory. And the output is generated to the target directory.

RIBs templates are added to `templateDirectory`. The hierarchy is the below.

```
- ComponentExtension
  - ComponentExtension.swift
- Default
  - Router.swift
  - Interactor.swift
  - Builder.swift
- OwnsView
  - Router.swift
  - Interactor.swift
  - Builder.swift
  - ViewController.swift
```

Template file is based on Xcode template style. Refer to sample [Templates](/Templates) for the detail.

# Usage

## Scaffold

`scaffold`, it is bulk generation command. Loads the RIBs tree and generates files and directories, then resolves the dependencies for its parent.

This operation is combination of `add` and `link` commands.

```
swift run ribscodegen scaffold ribstree.md --parent SampleParent
```

Write RIBs tree as Markfown like the below.

```
- **Node1**
  - Node2
  - Node3
- Node4
  - **Node5**
    - Node6
```

Show the hierarchy as list style ( `-` ). Add bold style ( `**` ) for Viewless RIB.

## Add

`add`, it is just creating a single RIB command. 

```
swift run ribscodegen add Demo
```

The below files are generated.

- Demo/DemoRouter.swift
- Demo/DemoInteractor.swift
- Demo/DemoBuilder.swift
- Demo/DemoViewController.swift

If wants to create viewless RIB, add `--noview` command.

RIBsCodeGen is also support Needle.

https://github.com/uber/needle

If you needs to specify Needle dependency injection type, you can specify that via pass `--needle` parameter.

If passed `--needle`, will create RIBs use Needle as dependency injection.

## Add with parent

`add` command with `--parent` option, it is creating a single RIB and resolving the dependency for its parent.

```
swift run ribscodegen add Demo --parent SampleParent
```

The below files are generated.

- Demo/DemoRouter.swift
- Demo/DemoInteractor.swift
- Demo/DemoBuilder.swift
- Demo/DemoViewController.swift
- SampleParent/Dependencies/SampleParentComponent+Demo.swift

And the below files would be updated for resolving dependency.

- SampleParent/SampleParentRouter.swift
- SampleParent/SampleParentBuilder.swift


## Link

`link` command, it is resolving dependency for the parent. If there are reusable RIBs, the command is useful.

```
swift run ribscodegen link Demo --parent SampleParent
```

The below files are generated.

- SampleParent/Dependencies/SampleParentComponent+Demo.swift

And the below files would be updated for resolving dependency.

- SampleParent/SampleParentRouter.swift
- SampleParent/SampleParentBuilder.swift

## Unlink

`unlink` command, it is deleting dependency from the parent. 

```
swift run ribscodegen unlink Demo --parent SampleParent
```

This command uses `replacingOccurrences` method, there's no guarantee to delete perfectly. ( regular expression option is used. )

The deleting codes are managed by `.ribscodegen_unlink` file. The example is [here](.ribscodegen_unlink).

The below words are replaced to concrete RIB name.
- `__PARENT_RIB_NAME__`
- `__RIB_NAME__`
- `__RIB_NAME_LOWER_CASED_FIRST_LETTER__`


## Rename

`rename` command, it is renaming RIB name. Related protocols, classes, methods and some codes are renamed. Additionally, the directory and file name is renamed as well.

```
swift run ribscodegen rename Sample NewSample
```

This command uses `replacingOccurrences` method, there's no guarantee to rename perfectly. ( regular expression option is NOT used. )

The replaced text is managed by `.ribscodegen_rename` file.

if run `ribscodegen rename Sample NewSample` command with the below condition,

```
interactor:
  - "protocol __RIB_NAME__Routing:"
```

RIBsCodeGen reads SampleInteractor.swift file, search `protocol SampleRouting:` and replace it with `protocol NewSampleRouting:` .

`.ribscodegen_rename` setting example is [here](.ribscodegen_rename).

## Remove

`remove` command, it is deleting the target RIB after deleting the dependencies for its all parent.

```
swift run ribscodegen remove Sample
```

`unlink` command is used in `remove`. Deleting the dependencies for it all parent, remove the target RIB directory and files.


## Help

`help` command, it is checking the tool usage.

```
swift run ribscodegen help
```


