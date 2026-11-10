#!/usr/bin/env python3
"""生成 TerminalApp.xcodeproj/project.pbxproj"""

import os
import uuid

# 所有 Swift 來源檔案（相對於 TerminalApp/ 目錄）
SOURCE_FILES = [
    "App/TerminalAppApp.swift",
    "App/TerminalWindowManager.swift",
    "Models/TerminalTab.swift",
    "Models/TabManager.swift",
    "Models/ShortcutSettings.swift",
    "Models/AppearanceSettings.swift",
    "Models/ScheduleManager.swift",
    "Models/ScheduledInputItem.swift",
    "App/ScheduleMenuCommands.swift",
    "ViewModels/KeyboardHandler.swift",
    "ViewModels/TerminalViewModel.swift",
    "Views/ContentView.swift",
    "Views/TabBarView.swift",
    "Views/TabDragSourceView.swift",
    "Views/TerminalContainerView.swift",
    "Views/TerminalNSViewWrapper.swift",
    "Views/ToastView.swift",
    "Views/Settings/SettingsView.swift",
    "Views/Settings/ShortcutSettingsView.swift",
    "Views/Settings/ShortcutRecorderView.swift",
    "Views/Settings/ScheduleListView.swift",
    "Views/Settings/ScheduleEditView.swift",
    "Views/Settings/AppearanceSettingsView.swift",
    "Terminal/ShellLauncher.swift",
    "Terminal/TerminalSessionManager.swift",
]

TEST_SOURCE_FILES = [
    "ScrollbackBufferTests.swift",
]

def uid():
    return uuid.uuid4().hex[:24].upper()

# --- 固定 GUIDs ---
PROJECT_ID       = uid()
TARGET_ID        = uid()
MAIN_GROUP_ID    = uid()
SOURCES_GROUP_ID = uid()
PRODUCTS_GROUP_ID= uid()
FRAMEWORKS_GROUP_ID = uid()
RESOURCES_GROUP_ID = uid()

SOURCE_PHASE_ID  = uid()
RESOURCES_PHASE_ID = uid()
FRAMEWORKS_PHASE_ID = uid()
APP_PRODUCT_ID   = uid()

ENTITLEMENTS_FILE_ID = uid()
INFOPLIST_FILE_ID    = uid()
XCASSETS_FILE_ID     = uid()
XCASSETS_BUILD_FILE_ID = uid()
LOCALIZATION_FILE_ID = uid()
LOCALIZATION_BUILD_FILE_ID = uid()

DEBUG_CONFIG_ID   = uid()
RELEASE_CONFIG_ID = uid()
TARGET_DEBUG_ID   = uid()
TARGET_RELEASE_ID = uid()
CONFIG_LIST_ID    = uid()
TARGET_CONFIG_LIST_ID = uid()

SWIFTTERM_PACKAGE_REF_ID = uid()
SWIFTTERM_PRODUCT_REF_ID = uid()
SWIFTTERM_DEPENDENCY_ID  = uid()
SWIFTTERM_BUILD_FILE_ID  = uid()
SWIFTTERM_PACKAGE_PRODUCT_ID = uid()

TEST_TARGET_ID = uid()
TEST_SOURCE_PHASE_ID = uid()
TEST_FRAMEWORKS_PHASE_ID = uid()
TEST_PRODUCT_ID = uid()
TEST_GROUP_ID = uid()
TEST_CONFIG_LIST_ID = uid()
TEST_DEBUG_ID = uid()
TEST_RELEASE_ID = uid()
TEST_DEPENDENCY_ID = uid()
XCTEST_FILE_ID = uid()
XCTEST_BUILD_FILE_ID = uid()

XCWORKSPACE_DATA = """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
"""

XCSCHEME_DATA = """<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.7">
   <!-- App product: {APP_PRODUCT_ID}; test product: {TEST_PRODUCT_ID} -->
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{TARGET_ID}" BuildableName="TerminalApp.app" BlueprintName="TerminalApp" ReferencedContainer="container:TerminalApp.xcodeproj" />
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
      <Testables>
         <TestableReference skipped="NO">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{TEST_TARGET_ID}" BuildableName="TerminalAppTests.xctest" BlueprintName="TerminalAppTests" ReferencedContainer="container:TerminalApp.xcodeproj" />
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{TARGET_ID}" BuildableName="TerminalApp.app" BlueprintName="TerminalApp" ReferencedContainer="container:TerminalApp.xcodeproj" />
      </BuildableProductRunnable>
   </LaunchAction>
</Scheme>
"""

def make_pbxproj():
    # 每個 Swift 來源檔案的 file ref ID 和 build file ID
    file_refs = {}   # path -> file_ref_id
    build_files = {} # path -> build_file_id
    for f in SOURCE_FILES:
        file_refs[f] = uid()
        build_files[f] = uid()

    test_file_refs = {}
    test_build_files = {}
    for f in TEST_SOURCE_FILES:
        test_file_refs[f] = uid()
        test_build_files[f] = uid()

    lines = []
    lines.append("// !$*UTF8*$!")
    lines.append("{")
    lines.append("\tarchiveVersion = 1;")
    lines.append("\tclasses = {")
    lines.append("\t};")
    lines.append("\tobjectVersion = 56;")
    lines.append("\tobjects = {")
    lines.append("")

    # PBXBuildFile - source files
    lines.append("/* Begin PBXBuildFile section */")
    for f in SOURCE_FILES:
        name = os.path.basename(f)
        lines.append(f"\t\t{build_files[f]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {name} */; }};")
    for f in TEST_SOURCE_FILES:
        name = os.path.basename(f)
        lines.append(f"\t\t{test_build_files[f]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {test_file_refs[f]} /* {name} */; }};")
    # SwiftTerm framework
    lines.append(f"\t\t{SWIFTTERM_BUILD_FILE_ID} /* SwiftTerm in Frameworks */ = {{isa = PBXBuildFile; productRef = {SWIFTTERM_PACKAGE_PRODUCT_ID} /* SwiftTerm */; }};")
    lines.append(f"\t\t{XCASSETS_BUILD_FILE_ID} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {XCASSETS_FILE_ID} /* Assets.xcassets */; }};")
    lines.append(f"\t\t{LOCALIZATION_BUILD_FILE_ID} /* Localizable.xcstrings in Resources */ = {{isa = PBXBuildFile; fileRef = {LOCALIZATION_FILE_ID} /* Localizable.xcstrings */; }};")
    lines.append(f"\t\t{XCTEST_BUILD_FILE_ID} /* XCTest.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {XCTEST_FILE_ID} /* XCTest.framework */; }};")
    lines.append("/* End PBXBuildFile section */")
    lines.append("")

    # PBXFileReference - source files
    lines.append("/* Begin PBXFileReference section */")
    for f in SOURCE_FILES:
        name = os.path.basename(f)
        lines.append(f'\t\t{file_refs[f]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{name}"; sourceTree = "<group>"; }};')
    for f in TEST_SOURCE_FILES:
        name = os.path.basename(f)
        lines.append(f'\t\t{test_file_refs[f]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{name}"; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{APP_PRODUCT_ID} /* TerminalApp.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = TerminalApp.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    lines.append(f'\t\t{TEST_PRODUCT_ID} /* TerminalAppTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = TerminalAppTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')
    lines.append(f'\t\t{XCTEST_FILE_ID} /* XCTest.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = XCTest.framework; path = System/Library/Frameworks/XCTest.framework; sourceTree = SDKROOT; }};')
    lines.append(f'\t\t{ENTITLEMENTS_FILE_ID} /* TerminalApp.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = TerminalApp.entitlements; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{INFOPLIST_FILE_ID} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{XCASSETS_FILE_ID} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{LOCALIZATION_FILE_ID} /* Localizable.xcstrings */ = {{isa = PBXFileReference; lastKnownFileType = text.json.xcstrings; path = Localizable.xcstrings; sourceTree = "<group>"; }};')
    lines.append("/* End PBXFileReference section */")
    lines.append("")

    # XCRemoteSwiftPackageReference
    lines.append("/* Begin XCRemoteSwiftPackageReference section */")
    lines.append(f"\t\t{SWIFTTERM_PACKAGE_REF_ID} /* XCRemoteSwiftPackageReference \"SwiftTerm\" */ = {{")
    lines.append(f"\t\t\tisa = XCRemoteSwiftPackageReference;")
    lines.append(f'\t\t\trepositoryURL = "https://github.com/migueldeicaza/SwiftTerm";')
    lines.append(f'\t\t\trequirement = {{')
    lines.append(f'\t\t\t\tkind = upToNextMajorVersion;')
    lines.append(f'\t\t\t\tminimumVersion = "1.0.0";')
    lines.append(f'\t\t\t}};')
    lines.append(f"\t\t}};")
    lines.append("/* End XCRemoteSwiftPackageReference section */")
    lines.append("")

    # XCSwiftPackageProductDependency
    lines.append("/* Begin XCSwiftPackageProductDependency section */")
    lines.append(f"\t\t{SWIFTTERM_PACKAGE_PRODUCT_ID} /* SwiftTerm */ = {{")
    lines.append(f"\t\t\tisa = XCSwiftPackageProductDependency;")
    lines.append(f"\t\t\tpackage = {SWIFTTERM_PACKAGE_REF_ID} /* XCRemoteSwiftPackageReference \"SwiftTerm\" */;")
    lines.append(f'\t\t\tproductName = SwiftTerm;')
    lines.append(f"\t\t}};")
    lines.append("/* End XCSwiftPackageProductDependency section */")
    lines.append("")

    # PBXFrameworksBuildPhase
    lines.append("/* Begin PBXFrameworksBuildPhase section */")
    lines.append(f"\t\t{FRAMEWORKS_PHASE_ID} /* Frameworks */ = {{")
    lines.append(f"\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append(f"\t\t\tbuildActionMask = 2147483647;")
    lines.append(f"\t\t\tfiles = (")
    lines.append(f"\t\t\t\t{SWIFTTERM_BUILD_FILE_ID} /* SwiftTerm in Frameworks */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXFrameworksBuildPhase section */")
    lines.append("")

    lines.append("/* Begin PBXFrameworksBuildPhase section */")
    lines.append(f"\t\t{TEST_FRAMEWORKS_PHASE_ID} /* Frameworks */ = {{")
    lines.append(f"\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append(f"\t\t\tbuildActionMask = 2147483647;")
    lines.append(f"\t\t\tfiles = (")
    lines.append(f"\t\t\t\t{XCTEST_BUILD_FILE_ID} /* XCTest.framework in Frameworks */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXFrameworksBuildPhase section */")
    lines.append("")

    # Build groups hierarchy
    # App/ Models/ ViewModels/ Views/ Views/Settings/ Terminal/ Resources/
    app_group_id     = uid()
    models_group_id  = uid()
    vm_group_id      = uid()
    views_group_id   = uid()
    settings_group_id= uid()
    terminal_group_id= uid()
    resources_group_id_2 = uid()

    def files_in(prefix):
        return [f for f in SOURCE_FILES if f.startswith(prefix + "/") and "/" not in f[len(prefix)+1:]]

    lines.append("/* Begin PBXGroup section */")

    # Main group
    lines.append(f"\t\t{MAIN_GROUP_ID} = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{SOURCES_GROUP_ID} /* TerminalApp */,")
    lines.append(f"\t\t\t\t{TEST_GROUP_ID} /* TerminalAppTests */,")
    lines.append(f"\t\t\t\t{FRAMEWORKS_GROUP_ID} /* Frameworks */,")
    lines.append(f"\t\t\t\t{PRODUCTS_GROUP_ID} /* Products */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    # Products group
    lines.append(f"\t\t{PRODUCTS_GROUP_ID} /* Products */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{APP_PRODUCT_ID} /* TerminalApp.app */,")
    lines.append(f"\t\t\t\t{TEST_PRODUCT_ID} /* TerminalAppTests.xctest */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tname = Products;")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    lines.append(f"\t\t{FRAMEWORKS_GROUP_ID} /* Frameworks */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{XCTEST_FILE_ID} /* XCTest.framework */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tname = Frameworks;")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    lines.append(f"\t\t{TEST_GROUP_ID} /* TerminalAppTests */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    for f in TEST_SOURCE_FILES:
        lines.append(f"\t\t\t\t{test_file_refs[f]} /* {os.path.basename(f)} */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tpath = TerminalAppTests;")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    # TerminalApp root group
    lines.append(f"\t\t{SOURCES_GROUP_ID} /* TerminalApp */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{app_group_id} /* App */,")
    lines.append(f"\t\t\t\t{models_group_id} /* Models */,")
    lines.append(f"\t\t\t\t{vm_group_id} /* ViewModels */,")
    lines.append(f"\t\t\t\t{views_group_id} /* Views */,")
    lines.append(f"\t\t\t\t{terminal_group_id} /* Terminal */,")
    lines.append(f"\t\t\t\t{resources_group_id_2} /* Resources */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tname = TerminalApp;")
    lines.append(f"\t\t\tpath = TerminalApp;")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    def subgroup(gid, name, rel_path, prefix):
        local = files_in(prefix)
        lines.append(f"\t\t{gid} /* {name} */ = {{")
        lines.append(f"\t\t\tisa = PBXGroup;")
        lines.append(f"\t\t\tchildren = (")
        for f in local:
            lines.append(f"\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */,")
        if name == "Views":
            lines.append(f"\t\t\t\t{settings_group_id} /* Settings */,")
        lines.append(f"\t\t\t);")
        lines.append(f"\t\t\tpath = {rel_path};")
        lines.append(f"\t\t\tsourceTree = \"<group>\";")
        lines.append(f"\t\t}};")

    subgroup(app_group_id,      "App",       "App",       "App")
    subgroup(models_group_id,   "Models",    "Models",    "Models")
    subgroup(vm_group_id,       "ViewModels","ViewModels","ViewModels")
    subgroup(views_group_id,    "Views",     "Views",     "Views")
    subgroup(terminal_group_id, "Terminal",  "Terminal",  "Terminal")

    # Settings subgroup
    settings_files = [f for f in SOURCE_FILES if f.startswith("Views/Settings/")]
    lines.append(f"\t\t{settings_group_id} /* Settings */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    for f in settings_files:
        lines.append(f"\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tpath = Settings;")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    # Resources group
    lines.append(f"\t\t{resources_group_id_2} /* Resources */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{ENTITLEMENTS_FILE_ID} /* TerminalApp.entitlements */,")
    lines.append(f"\t\t\t\t{INFOPLIST_FILE_ID} /* Info.plist */,")
    lines.append(f"\t\t\t\t{XCASSETS_FILE_ID} /* Assets.xcassets */,")
    lines.append(f"\t\t\t\t{LOCALIZATION_FILE_ID} /* Localizable.xcstrings */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tpath = Resources;")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    lines.append("/* End PBXGroup section */")
    lines.append("")

    # PBXNativeTarget
    lines.append("/* Begin PBXNativeTarget section */")
    lines.append(f"\t\t{TARGET_ID} /* TerminalApp */ = {{")
    lines.append(f"\t\t\tisa = PBXNativeTarget;")
    lines.append(f"\t\t\tbuildConfigurationList = {TARGET_CONFIG_LIST_ID} /* Build configuration list for PBXNativeTarget \"TerminalApp\" */;")
    lines.append(f"\t\t\tbuildPhases = (")
    lines.append(f"\t\t\t\t{SOURCE_PHASE_ID} /* Sources */,")
    lines.append(f"\t\t\t\t{FRAMEWORKS_PHASE_ID} /* Frameworks */,")
    lines.append(f"\t\t\t\t{RESOURCES_PHASE_ID} /* Resources */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tbuildRules = (")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tdependencies = (")
    lines.append(f"\t\t\t);")
    lines.append(f'\t\t\tname = TerminalApp;')
    lines.append(f'\t\t\tpackageProductDependencies = (')
    lines.append(f'\t\t\t\t{SWIFTTERM_PACKAGE_PRODUCT_ID} /* SwiftTerm */,')
    lines.append(f'\t\t\t);')
    lines.append(f'\t\t\tproductName = TerminalApp;')
    lines.append(f'\t\t\tproductReference = {APP_PRODUCT_ID} /* TerminalApp.app */;')
    lines.append(f'\t\t\tproductType = "com.apple.product-type.application";')
    lines.append(f"\t\t}};")
    lines.append(f"\t\t{TEST_TARGET_ID} /* TerminalAppTests */ = {{")
    lines.append(f"\t\t\tisa = PBXNativeTarget;")
    lines.append(f"\t\t\tbuildConfigurationList = {TEST_CONFIG_LIST_ID} /* Build configuration list for PBXNativeTarget \"TerminalAppTests\" */;")
    lines.append(f"\t\t\tbuildPhases = (")
    lines.append(f"\t\t\t\t{TEST_SOURCE_PHASE_ID} /* Sources */,")
    lines.append(f"\t\t\t\t{TEST_FRAMEWORKS_PHASE_ID} /* Frameworks */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tbuildRules = (")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tdependencies = (")
    lines.append(f"\t\t\t\t{TEST_DEPENDENCY_ID} /* PBXTargetDependency */,")
    lines.append(f"\t\t\t);")
    lines.append(f'\t\t\tname = TerminalAppTests;')
    lines.append(f'\t\t\tproductName = TerminalAppTests;')
    lines.append(f'\t\t\tproductReference = {TEST_PRODUCT_ID} /* TerminalAppTests.xctest */;')
    lines.append(f'\t\t\tproductType = "com.apple.product-type.bundle.unit-test";')
    lines.append(f"\t\t}};")
    lines.append("/* End PBXNativeTarget section */")
    lines.append("")

    # PBXProject
    lines.append("/* Begin PBXProject section */")
    lines.append(f"\t\t{PROJECT_ID} /* Project object */ = {{")
    lines.append(f"\t\t\tisa = PBXProject;")
    lines.append(f"\t\t\tattributes = {{")
    lines.append(f"\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    lines.append(f'\t\t\t\tLastSwiftUpdateCheck = 1600;')
    lines.append(f'\t\t\t\tLastUpgradeCheck = 1600;')
    lines.append(f"\t\t\t\tTargetAttributes = {{")
    lines.append(f"\t\t\t\t\t{TARGET_ID} = {{")
    lines.append(f"\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;")
    lines.append(f"\t\t\t\t\t}};")
    lines.append(f"\t\t\t\t\t{TEST_TARGET_ID} = {{")
    lines.append(f"\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;")
    lines.append(f"\t\t\t\t\t}};")
    lines.append(f"\t\t\t\t}};")
    lines.append(f"\t\t\t}};")
    lines.append(f"\t\t\tbuildConfigurationList = {CONFIG_LIST_ID} /* Build configuration list for PBXProject \"TerminalApp\" */;")
    lines.append(f'\t\t\tcompatibilityVersion = "Xcode 14.0";')
    lines.append(f'\t\t\tdevelopmentRegion = en;')
    lines.append(f'\t\t\thasScannedForEncodings = 0;')
    lines.append(f'\t\t\tknownRegions = (')
    lines.append(f'\t\t\t\ten,')
    lines.append(f'\t\t\t\tja,')
    lines.append(f'\t\t\t\tko,')
    lines.append(f'\t\t\t\t"zh-Hant",')
    lines.append(f'\t\t\t\tBase,')
    lines.append(f'\t\t\t);')
    lines.append(f'\t\t\tmainGroup = {MAIN_GROUP_ID};')
    lines.append(f'\t\t\tpackageReferences = (')
    lines.append(f'\t\t\t\t{SWIFTTERM_PACKAGE_REF_ID} /* XCRemoteSwiftPackageReference "SwiftTerm" */,')
    lines.append(f'\t\t\t);')
    lines.append(f'\t\t\tproductRefGroup = {PRODUCTS_GROUP_ID} /* Products */;')
    lines.append(f'\t\t\tprojectDirPath = "";')
    lines.append(f'\t\t\tprojectRoot = "";')
    lines.append(f'\t\t\ttargets = (')
    lines.append(f'\t\t\t\t{TARGET_ID} /* TerminalApp */,')
    lines.append(f'\t\t\t\t{TEST_TARGET_ID} /* TerminalAppTests */,')
    lines.append(f'\t\t\t);')
    lines.append(f"\t\t}};")
    lines.append("/* End PBXProject section */")
    lines.append("")

    # PBXResourcesBuildPhase
    lines.append("/* Begin PBXResourcesBuildPhase section */")
    lines.append(f"\t\t{RESOURCES_PHASE_ID} /* Resources */ = {{")
    lines.append(f"\t\t\tisa = PBXResourcesBuildPhase;")
    lines.append(f"\t\t\tbuildActionMask = 2147483647;")
    lines.append(f"\t\t\tfiles = (")
    lines.append(f"\t\t\t\t{XCASSETS_BUILD_FILE_ID} /* Assets.xcassets in Resources */,")
    lines.append(f"\t\t\t\t{LOCALIZATION_BUILD_FILE_ID} /* Localizable.xcstrings in Resources */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXResourcesBuildPhase section */")
    lines.append("")

    lines.append("/* Begin PBXTargetDependency section */")
    lines.append(f"\t\t{TEST_DEPENDENCY_ID} /* PBXTargetDependency */ = {{")
    lines.append(f"\t\t\tisa = PBXTargetDependency;")
    lines.append(f"\t\t\ttarget = {TARGET_ID} /* TerminalApp */;")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXTargetDependency section */")
    lines.append("")

    # PBXSourcesBuildPhase
    lines.append("/* Begin PBXSourcesBuildPhase section */")
    lines.append(f"\t\t{SOURCE_PHASE_ID} /* Sources */ = {{")
    lines.append(f"\t\t\tisa = PBXSourcesBuildPhase;")
    lines.append(f"\t\t\tbuildActionMask = 2147483647;")
    lines.append(f"\t\t\tfiles = (")
    for f in SOURCE_FILES:
        name = os.path.basename(f)
        lines.append(f"\t\t\t\t{build_files[f]} /* {name} in Sources */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXSourcesBuildPhase section */")
    lines.append("")

    lines.append("/* Begin PBXSourcesBuildPhase section */")
    lines.append(f"\t\t{TEST_SOURCE_PHASE_ID} /* Sources */ = {{")
    lines.append(f"\t\t\tisa = PBXSourcesBuildPhase;")
    lines.append(f"\t\t\tbuildActionMask = 2147483647;")
    lines.append(f"\t\t\tfiles = (")
    for f in TEST_SOURCE_FILES:
        lines.append(f"\t\t\t\t{test_build_files[f]} /* {os.path.basename(f)} in Sources */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXSourcesBuildPhase section */")
    lines.append("")

    # XCBuildConfiguration
    lines.append("/* Begin XCBuildConfiguration section */")

    # Project Debug
    lines.append(f"\t\t{DEBUG_CONFIG_ID} /* Debug */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tbuildSettings = {{")
    lines.append(f'\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;')
    lines.append(f'\t\t\t\tCLANG_ANALYZER_NONNULL = YES;')
    lines.append(f'\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";')
    lines.append(f'\t\t\t\tCLANG_ENABLE_MODULES = YES;')
    lines.append(f'\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;')
    lines.append(f'\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;')
    lines.append(f'\t\t\t\tCOPY_PHASE_STRIP = NO;')
    lines.append(f'\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;')
    lines.append(f'\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;')
    lines.append(f'\t\t\t\tENABLE_TESTABILITY = YES;')
    lines.append(f'\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;')
    lines.append(f'\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;')
    lines.append(f'\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;')
    lines.append(f'\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;')
    lines.append(f'\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)");')
    lines.append(f'\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;')
    lines.append(f'\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;')
    lines.append(f'\t\t\t\tMTL_FAST_MATH = YES;')
    lines.append(f'\t\t\t\tONLY_ACTIVE_ARCH = YES;')
    lines.append(f'\t\t\t\tSDKROOT = macosx;')
    lines.append(f'\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;')
    lines.append(f'\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";')
    lines.append(f"\t\t\t}};")
    lines.append(f'\t\t\tname = Debug;')
    lines.append(f"\t\t}};")

    # Project Release
    lines.append(f"\t\t{RELEASE_CONFIG_ID} /* Release */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tbuildSettings = {{")
    lines.append(f'\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;')
    lines.append(f'\t\t\t\tCLANG_ANALYZER_NONNULL = YES;')
    lines.append(f'\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";')
    lines.append(f'\t\t\t\tCLANG_ENABLE_MODULES = YES;')
    lines.append(f'\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;')
    lines.append(f'\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;')
    lines.append(f'\t\t\t\tCOPY_PHASE_STRIP = NO;')
    lines.append(f'\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";')
    lines.append(f'\t\t\t\tENABLE_NS_ASSERTIONS = NO;')
    lines.append(f'\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;')
    lines.append(f'\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;')
    lines.append(f'\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;')
    lines.append(f'\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;')
    lines.append(f'\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;')
    lines.append(f'\t\t\t\tMTL_FAST_MATH = YES;')
    lines.append(f'\t\t\t\tSDKROOT = macosx;')
    lines.append(f'\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;')
    lines.append(f"\t\t\t}};")
    lines.append(f'\t\t\tname = Release;')
    lines.append(f"\t\t}};")

    # Target Debug
    lines.append(f"\t\t{TARGET_DEBUG_ID} /* Debug */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tbuildSettings = {{")
    lines.append(f'\t\t\t\tASSET_CATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;')
    lines.append(f'\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;')
    lines.append(f'\t\t\t\tCODE_SIGN_ENTITLEMENTS = TerminalApp/Resources/TerminalApp.entitlements;')
    lines.append(f'\t\t\t\tCODE_SIGN_STYLE = Automatic;')
    lines.append(f'\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;')
    lines.append(f'\t\t\t\tDEVELOPMENT_TEAM = "";')
    lines.append(f'\t\t\t\tINFOPLIST_FILE = TerminalApp/Resources/Info.plist;')
    lines.append(f'\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks");')
    lines.append(f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.nickycho.TerminalApp;')
    lines.append(f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
    lines.append(f'\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;')
    lines.append(f'\t\t\t\tSWIFT_VERSION = 5.0;')
    lines.append(f"\t\t\t}};")
    lines.append(f'\t\t\tname = Debug;')
    lines.append(f"\t\t}};")

    # Target Release
    lines.append(f"\t\t{TARGET_RELEASE_ID} /* Release */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tbuildSettings = {{")
    lines.append(f'\t\t\t\tASSET_CATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;')
    lines.append(f'\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;')
    lines.append(f'\t\t\t\tCODE_SIGN_ENTITLEMENTS = TerminalApp/Resources/TerminalApp.entitlements;')
    lines.append(f'\t\t\t\tCODE_SIGN_STYLE = Automatic;')
    lines.append(f'\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;')
    lines.append(f'\t\t\t\tDEVELOPMENT_TEAM = "";')
    lines.append(f'\t\t\t\tINFOPLIST_FILE = TerminalApp/Resources/Info.plist;')
    lines.append(f'\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks");')
    lines.append(f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.nickycho.TerminalApp;')
    lines.append(f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
    lines.append(f'\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;')
    lines.append(f'\t\t\t\tSWIFT_VERSION = 5.0;')
    lines.append(f"\t\t\t}};")
    lines.append(f'\t\t\tname = Release;')
    lines.append(f"\t\t}};")

    for config_id, config_name in ((TEST_DEBUG_ID, "Debug"), (TEST_RELEASE_ID, "Release")):
        lines.append(f"\t\t{config_id} /* {config_name} */ = {{")
        lines.append(f"\t\t\tisa = XCBuildConfiguration;")
        lines.append(f"\t\t\tbuildSettings = {{")
        lines.append(f'\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";')
        lines.append(f'\t\t\t\tGENERATE_INFOPLIST_FILE = YES;')
        lines.append(f'\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;')
        lines.append(f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.nickycho.TerminalAppTests;')
        lines.append(f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
        lines.append(f'\t\t\t\tSWIFT_VERSION = 5.0;')
        lines.append(f'\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/TerminalApp.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TerminalApp";')
        lines.append(f"\t\t\t}};")
        lines.append(f'\t\t\tname = {config_name};')
        lines.append(f"\t\t}};")

    lines.append("/* End XCBuildConfiguration section */")
    lines.append("")

    # XCConfigurationList
    lines.append("/* Begin XCConfigurationList section */")
    lines.append(f"\t\t{CONFIG_LIST_ID} /* Build configuration list for PBXProject \"TerminalApp\" */ = {{")
    lines.append(f"\t\t\tisa = XCConfigurationList;")
    lines.append(f"\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{DEBUG_CONFIG_ID} /* Debug */,")
    lines.append(f"\t\t\t\t{RELEASE_CONFIG_ID} /* Release */,")
    lines.append(f"\t\t\t);")
    lines.append(f'\t\t\tdefaultConfigurationIsVisible = 0;')
    lines.append(f'\t\t\tdefaultConfigurationName = Release;')
    lines.append(f"\t\t}};")

    lines.append(f"\t\t{TARGET_CONFIG_LIST_ID} /* Build configuration list for PBXNativeTarget \"TerminalApp\" */ = {{")
    lines.append(f"\t\t\tisa = XCConfigurationList;")
    lines.append(f"\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{TARGET_DEBUG_ID} /* Debug */,")
    lines.append(f"\t\t\t\t{TARGET_RELEASE_ID} /* Release */,")
    lines.append(f"\t\t\t);")
    lines.append(f'\t\t\tdefaultConfigurationIsVisible = 0;')
    lines.append(f'\t\t\tdefaultConfigurationName = Release;')
    lines.append(f"\t\t}};")

    lines.append(f"\t\t{TEST_CONFIG_LIST_ID} /* Build configuration list for PBXNativeTarget \"TerminalAppTests\" */ = {{")
    lines.append(f"\t\t\tisa = XCConfigurationList;")
    lines.append(f"\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{TEST_DEBUG_ID} /* Debug */,")
    lines.append(f"\t\t\t\t{TEST_RELEASE_ID} /* Release */,")
    lines.append(f"\t\t\t);")
    lines.append(f'\t\t\tdefaultConfigurationIsVisible = 0;')
    lines.append(f'\t\t\tdefaultConfigurationName = Release;')
    lines.append(f"\t\t}};")
    lines.append("/* End XCConfigurationList section */")
    lines.append("")

    lines.append("\t};")
    lines.append(f"\trootObject = {PROJECT_ID} /* Project object */;")
    lines.append("}")

    return "\n".join(lines)

if __name__ == "__main__":
    base = "/Users/nickycho/Dev/claude-code/osx-terminal-app"

    # Write project.pbxproj
    xcodeproj_dir = os.path.join(base, "TerminalApp.xcodeproj")
    os.makedirs(xcodeproj_dir, exist_ok=True)

    pbxproj_path = os.path.join(xcodeproj_dir, "project.pbxproj")
    with open(pbxproj_path, "w") as f:
        f.write(make_pbxproj())
    print(f"已生成: {pbxproj_path}")

    # Write xcworkspace/contents.xcworkspacedata
    ws_dir = os.path.join(xcodeproj_dir, "project.xcworkspace")
    os.makedirs(ws_dir, exist_ok=True)
    ws_data_path = os.path.join(ws_dir, "contents.xcworkspacedata")
    with open(ws_data_path, "w") as f:
        f.write(XCWORKSPACE_DATA)
    print(f"已生成: {ws_data_path}")

    scheme_dir = os.path.join(xcodeproj_dir, "xcshareddata", "xcschemes")
    os.makedirs(scheme_dir, exist_ok=True)
    scheme_path = os.path.join(scheme_dir, "TerminalApp.xcscheme")
    with open(scheme_path, "w") as f:
        f.write(XCSCHEME_DATA.format(
            TARGET_ID=TARGET_ID,
            TEST_TARGET_ID=TEST_TARGET_ID,
            APP_PRODUCT_ID=APP_PRODUCT_ID,
            TEST_PRODUCT_ID=TEST_PRODUCT_ID,
        ))
    print(f"已生成: {scheme_path}")

    print("完成！")
