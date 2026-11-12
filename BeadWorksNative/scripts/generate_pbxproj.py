#!/usr/bin/env python3
"""Regenerate BeadWorks.xcodeproj/project.pbxproj from the on-disk source tree."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / "BeadWorks.xcodeproj" / "project.pbxproj"


def pbx_quote(value: str) -> str:
    if not value or any(ch in value for ch in " \t+@"):
        return f'"{value}"'
    return value


def pbx_id(seed: str) -> str:
    digest = hashlib.md5(seed.encode("utf-8")).hexdigest().upper()
    return digest[:24]


def collect_files(relative_dir: str, extensions: tuple[str, ...]) -> list[str]:
    base = ROOT / relative_dir
    files: list[str] = []
    for path in sorted(base.rglob("*")):
        if path.is_file() and path.suffix in extensions and ".xcassets/" not in path.as_posix():
            files.append(str(path.relative_to(ROOT)))
    return files


def group_children(files: list[str], parent: str) -> tuple[list[str], list[str]]:
    """Return (child_group_names, child_files) for a folder relative to ROOT."""
    prefix = parent.rstrip("/") + "/"
    groups: set[str] = set()
    child_files: list[str] = []
    for path in files:
        if parent == "":
            rel = path
        elif path.startswith(prefix):
            rel = path[len(prefix):]
        else:
            continue
        if "/" in rel:
            groups.add(rel.split("/", 1)[0])
        else:
            child_files.append(path)
    return sorted(groups), sorted(child_files)


def emit_groups(files: list[str], folder: str, group_id: str, display_name: str | None = None) -> list[str]:
    lines: list[str] = []
    groups, child_files = group_children(files, folder)
    children: list[str] = []
    for name in groups:
        child_path = f"{folder}/{name}" if folder else name
        child_id = pbx_id(f"group:{child_path}")
        children.append(f"\t\t\t\t{child_id} /* {name} */,\n")
        lines.extend(emit_groups(files, child_path, child_id))
    for path in child_files:
        file_id = pbx_id(f"file:{path}")
        children.append(f"\t\t\t\t{file_id} /* {Path(path).name} */,\n")

    path_value = Path(folder).name if folder else folder
    name_comment = display_name or path_value or "root"
    lines.append(f"\t\t{group_id} /* {name_comment} */ = {{\n")
    lines.append("\t\t\tisa = PBXGroup;\n")
    lines.append("\t\t\tchildren = (\n")
    lines.extend(children)
    lines.append("\t\t\t);\n")
    if folder:
        lines.append(f"\t\t\tpath = {pbx_quote(path_value)};\n")
    lines.append('\t\t\tsourceTree = "<group>";\n')
    lines.append("\t\t};\n")
    return lines


def main() -> None:
    app_swift = collect_files("BeadWorks", (".swift",))
    app_assets = ["BeadWorks/Assets.xcassets"]
    test_swift = collect_files("BeadWorksTests", (".swift",))
    ui_swift = collect_files("BeadWorksUITests", (".swift",))

    app_files = app_swift + app_assets
    all_source_files = [(path, "app") for path in app_swift] + [(path, "asset") for path in app_assets]
    all_source_files += [(path, "test") for path in test_swift]
    all_source_files += [(path, "ui") for path in ui_swift]

    file_refs: list[str] = []
    build_files: list[str] = []
    app_sources: list[str] = []
    test_sources: list[str] = []
    ui_sources: list[str] = []
    resources: list[str] = []

    product_app = pbx_id("product:BeadWorks.app")
    product_tests = pbx_id("product:BeadWorksTests.xctest")
    product_ui = pbx_id("product:BeadWorksUITests.xctest")

    for path, kind in all_source_files:
        name = Path(path).name
        file_id = pbx_id(f"file:{path}")
        build_id = pbx_id(f"build:{path}")
        if kind == "asset":
            file_refs.append(
                f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {pbx_quote(name)}; sourceTree = "<group>"; }};\n'
            )
            build_files.append(
                f"\t\t{build_id} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};\n"
            )
            resources.append(f"\t\t\t\t{build_id} /* {name} in Resources */,\n")
        else:
            file_refs.append(
                f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {pbx_quote(name)}; sourceTree = "<group>"; }};\n'
            )
            build_files.append(
                f"\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};\n"
            )
            entry = f"\t\t\t\t{build_id} /* {name} in Sources */,\n"
            if kind == "app":
                app_sources.append(entry)
            elif kind == "test":
                test_sources.append(entry)
            else:
                ui_sources.append(entry)

    file_refs.append(
        f'\t\t{product_app} /* BeadWorks.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = BeadWorks.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n'
    )
    file_refs.append(
        f'\t\t{product_tests} /* BeadWorksTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = BeadWorksTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};\n'
    )
    file_refs.append(
        f'\t\t{product_ui} /* BeadWorksUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = BeadWorksUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};\n'
    )

    app_group = pbx_id("group:BeadWorks")
    test_group = pbx_id("group:BeadWorksTests")
    ui_group = pbx_id("group:BeadWorksUITests")
    products_group = pbx_id("group:Products")
    root_group = pbx_id("group:root")

    group_section: list[str] = []
    group_section.extend(emit_groups(app_files, "BeadWorks", app_group))
    group_section.extend(emit_groups(test_swift, "BeadWorksTests", test_group))
    group_section.extend(emit_groups(ui_swift, "BeadWorksUITests", ui_group))
    group_section.append(f"\t\t{products_group} /* Products */ = {{\n")
    group_section.append("\t\t\tisa = PBXGroup;\n")
    group_section.append("\t\t\tchildren = (\n")
    group_section.append(f"\t\t\t\t{product_app} /* BeadWorks.app */,\n")
    group_section.append(f"\t\t\t\t{product_tests} /* BeadWorksTests.xctest */,\n")
    group_section.append(f"\t\t\t\t{product_ui} /* BeadWorksUITests.xctest */,\n")
    group_section.append("\t\t\t);\n")
    group_section.append("\t\t\tname = Products;\n")
    group_section.append('\t\t\tsourceTree = "<group>";\n')
    group_section.append("\t\t};\n")
    group_section.append(f"\t\t{root_group} = {{\n")
    group_section.append("\t\t\tisa = PBXGroup;\n")
    group_section.append("\t\t\tchildren = (\n")
    group_section.append(f"\t\t\t\t{app_group} /* BeadWorks */,\n")
    group_section.append(f"\t\t\t\t{test_group} /* BeadWorksTests */,\n")
    group_section.append(f"\t\t\t\t{ui_group} /* BeadWorksUITests */,\n")
    group_section.append(f"\t\t\t\t{products_group} /* Products */,\n")
    group_section.append("\t\t\t);\n")
    group_section.append('\t\t\tsourceTree = "<group>";\n')
    group_section.append("\t\t};\n")

    target_app = "3780057F74FDE2FD7D59FFF9"
    target_tests = "E89470568F2E3B4CDEA4D11A"
    target_ui = "AE555F90B55FCF3FD346B026"
    project_id = "349D86F092B849B0672990E1"
    sources_app = pbx_id("phase:app-sources")
    sources_tests = pbx_id("phase:test-sources")
    sources_ui = pbx_id("phase:ui-sources")
    resources_phase = pbx_id("phase:app-resources")
    proxy_tests = "06FEB6240A08ECFB429A9A03"
    proxy_ui = "E162FCADC63F61AB67008428"
    dep_tests = "5C5055ADFEB28EBD0F677B38"
    dep_ui = "6137582563D4AD8D2440004A"

    text = []
    text.append("// !$*UTF8*$!\n")
    text.append("{\n")
    text.append("\tarchiveVersion = 1;\n")
    text.append("\tclasses = {\n")
    text.append("\t};\n")
    text.append("\tobjectVersion = 77;\n")
    text.append("\tobjects = {\n\n")
    text.append("/* Begin PBXBuildFile section */\n")
    text.extend(sorted(build_files))
    text.append("/* End PBXBuildFile section */\n\n")
    text.append("/* Begin PBXContainerItemProxy section */\n")
    text.append(f"\t\t{proxy_tests} /* PBXContainerItemProxy */ = {{\n")
    text.append("\t\t\tisa = PBXContainerItemProxy;\n")
    text.append(f"\t\t\tcontainerPortal = {project_id} /* Project object */;\n")
    text.append("\t\t\tproxyType = 1;\n")
    text.append(f"\t\t\tremoteGlobalIDString = {target_app};\n")
    text.append("\t\t\tremoteInfo = BeadWorks;\n")
    text.append("\t\t};\n")
    text.append(f"\t\t{proxy_ui} /* PBXContainerItemProxy */ = {{\n")
    text.append("\t\t\tisa = PBXContainerItemProxy;\n")
    text.append(f"\t\t\tcontainerPortal = {project_id} /* Project object */;\n")
    text.append("\t\t\tproxyType = 1;\n")
    text.append(f"\t\t\tremoteGlobalIDString = {target_app};\n")
    text.append("\t\t\tremoteInfo = BeadWorks;\n")
    text.append("\t\t};\n")
    text.append("/* End PBXContainerItemProxy section */\n\n")
    text.append("/* Begin PBXFileReference section */\n")
    text.extend(sorted(file_refs))
    text.append("/* End PBXFileReference section */\n\n")
    text.append("/* Begin PBXGroup section */\n")
    text.extend(group_section)
    text.append("/* End PBXGroup section */\n\n")
    text.append("/* Begin PBXNativeTarget section */\n")
    text.append(f"\t\t{target_app} /* BeadWorks */ = {{\n")
    text.append("\t\t\tisa = PBXNativeTarget;\n")
    text.append("\t\t\tbuildConfigurationList = 03991F6BE6CD0B3E570C13DD /* Build configuration list for PBXNativeTarget \"BeadWorks\" */;\n")
    text.append("\t\t\tbuildPhases = (\n")
    text.append(f"\t\t\t\t{sources_app} /* Sources */,\n")
    text.append(f"\t\t\t\t{resources_phase} /* Resources */,\n")
    text.append("\t\t\t);\n")
    text.append("\t\t\tbuildRules = (\n")
    text.append("\t\t\t);\n")
    text.append("\t\t\tdependencies = (\n")
    text.append("\t\t\t);\n")
    text.append("\t\t\tname = BeadWorks;\n")
    text.append("\t\t\tpackageProductDependencies = (\n")
    text.append("\t\t\t);\n")
    text.append("\t\t\tproductName = BeadWorks;\n")
    text.append(f"\t\t\tproductReference = {product_app} /* BeadWorks.app */;\n")
    text.append('\t\t\tproductType = "com.apple.product-type.application";\n')
    text.append("\t\t};\n")
    text.append(f"\t\t{target_ui} /* BeadWorksUITests */ = {{\n")
    text.append("\t\t\tisa = PBXNativeTarget;\n")
    text.append("\t\t\tbuildConfigurationList = 090F3616A116DADB35974825 /* Build configuration list for PBXNativeTarget \"BeadWorksUITests\" */;\n")
    text.append("\t\t\tbuildPhases = (\n")
    text.append(f"\t\t\t\t{sources_ui} /* Sources */,\n")
    text.append("\t\t\t);\n")
    text.append("\t\t\tbuildRules = (\n")
    text.append("\t\t\t);\n")
    text.append("\t\t\tdependencies = (\n")
    text.append(f"\t\t\t\t{dep_ui} /* PBXTargetDependency */,\n")
    text.append("\t\t\t);\n")
    text.append("\t\t\tname = BeadWorksUITests;\n")
    text.append("\t\t\tpackageProductDependencies = (\n")
    text.append("\t\t\t);\n")
    text.append("\t\t\tproductName = BeadWorksUITests;\n")
    text.append(f"\t\t\tproductReference = {product_ui} /* BeadWorksUITests.xctest */;\n")
    text.append('\t\t\tproductType = "com.apple.product-type.bundle.ui-testing";\n')
    text.append("\t\t};\n")
    text.append(f"\t\t{target_tests} /* BeadWorksTests */ = {{\n")
    text.append("\t\t\tisa = PBXNativeTarget;\n")
    text.append("\t\t\tbuildConfigurationList = BEE8CBE0655B95EC3C524615 /* Build configuration list for PBXNativeTarget \"BeadWorksTests\" */;\n")
    text.append("\t\t\tbuildPhases = (\n")
    text.append(f"\t\t\t\t{sources_tests} /* Sources */,\n")
    text.append("\t\t\t);\n")
    text.append("\t\t\tbuildRules = (\n")
    text.append("\t\t\t);\n")
    text.append("\t\t\tdependencies = (\n")
    text.append(f"\t\t\t\t{dep_tests} /* PBXTargetDependency */,\n")
    text.append("\t\t\t);\n")
    text.append("\t\t\tname = BeadWorksTests;\n")
    text.append("\t\t\tpackageProductDependencies = (\n")
    text.append("\t\t\t);\n")
    text.append("\t\t\tproductName = BeadWorksTests;\n")
    text.append(f"\t\t\tproductReference = {product_tests} /* BeadWorksTests.xctest */;\n")
    text.append('\t\t\tproductType = "com.apple.product-type.bundle.unit-test";\n')
    text.append("\t\t};\n")
    text.append("/* End PBXNativeTarget section */\n\n")
    text.append("/* Begin PBXProject section */\n")
    text.append(f"\t\t{project_id} /* Project object */ = {{\n")
    text.append("\t\t\tisa = PBXProject;\n")
    text.append("\t\t\tattributes = {\n")
    text.append("\t\t\t\tBuildIndependentTargetsInParallel = YES;\n")
    text.append("\t\t\t\tLastUpgradeCheck = 1430;\n")
    text.append("\t\t\t\tTargetAttributes = {\n")
    text.append(f"\t\t\t\t\t{target_ui} = {{\n")
    text.append(f"\t\t\t\t\t\tTestTargetID = {target_app};\n")
    text.append("\t\t\t\t\t};\n")
    text.append("\t\t\t\t};\n")
    text.append("\t\t\t};\n")
    text.append("\t\t\tbuildConfigurationList = EDCFED88E9A43434B4C058EC /* Build configuration list for PBXProject \"BeadWorks\" */;\n")
    text.append("\t\t\tdevelopmentRegion = en;\n")
    text.append("\t\t\thasScannedForEncodings = 0;\n")
    text.append("\t\t\tknownRegions = (\n")
    text.append("\t\t\t\tBase,\n")
    text.append("\t\t\t\ten,\n")
    text.append("\t\t\t);\n")
    text.append(f"\t\t\tmainGroup = {root_group};\n")
    text.append("\t\t\tminimizedProjectReferenceProxies = 1;\n")
    text.append("\t\t\tpreferredProjectObjectVersion = 77;\n")
    text.append(f"\t\t\tproductRefGroup = {products_group} /* Products */;\n")
    text.append('\t\t\tprojectDirPath = "";\n')
    text.append('\t\t\tprojectRoot = "";\n')
    text.append("\t\t\ttargets = (\n")
    text.append(f"\t\t\t\t{target_app} /* BeadWorks */,\n")
    text.append(f"\t\t\t\t{target_tests} /* BeadWorksTests */,\n")
    text.append(f"\t\t\t\t{target_ui} /* BeadWorksUITests */,\n")
    text.append("\t\t\t);\n")
    text.append("\t\t};\n")
    text.append("/* End PBXProject section */\n\n")
    text.append("/* Begin PBXResourcesBuildPhase section */\n")
    text.append(f"\t\t{resources_phase} /* Resources */ = {{\n")
    text.append("\t\t\tisa = PBXResourcesBuildPhase;\n")
    text.append("\t\t\tbuildActionMask = 2147483647;\n")
    text.append("\t\t\tfiles = (\n")
    text.extend(resources)
    text.append("\t\t\t);\n")
    text.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
    text.append("\t\t};\n")
    text.append("/* End PBXResourcesBuildPhase section */\n\n")
    text.append("/* Begin PBXSourcesBuildPhase section */\n")
    text.append(f"\t\t{sources_app} /* Sources */ = {{\n")
    text.append("\t\t\tisa = PBXSourcesBuildPhase;\n")
    text.append("\t\t\tbuildActionMask = 2147483647;\n")
    text.append("\t\t\tfiles = (\n")
    text.extend(sorted(app_sources))
    text.append("\t\t\t);\n")
    text.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
    text.append("\t\t};\n")
    text.append(f"\t\t{sources_ui} /* Sources */ = {{\n")
    text.append("\t\t\tisa = PBXSourcesBuildPhase;\n")
    text.append("\t\t\tbuildActionMask = 2147483647;\n")
    text.append("\t\t\tfiles = (\n")
    text.extend(sorted(ui_sources))
    text.append("\t\t\t);\n")
    text.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
    text.append("\t\t};\n")
    text.append(f"\t\t{sources_tests} /* Sources */ = {{\n")
    text.append("\t\t\tisa = PBXSourcesBuildPhase;\n")
    text.append("\t\t\tbuildActionMask = 2147483647;\n")
    text.append("\t\t\tfiles = (\n")
    text.extend(sorted(test_sources))
    text.append("\t\t\t);\n")
    text.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
    text.append("\t\t};\n")
    text.append("/* End PBXSourcesBuildPhase section */\n\n")
    text.append("/* Begin PBXTargetDependency section */\n")
    text.append(f"\t\t{dep_tests} /* PBXTargetDependency */ = {{\n")
    text.append("\t\t\tisa = PBXTargetDependency;\n")
    text.append(f"\t\t\ttarget = {target_app} /* BeadWorks */;\n")
    text.append(f"\t\t\ttargetProxy = {proxy_tests} /* PBXContainerItemProxy */;\n")
    text.append("\t\t};\n")
    text.append(f"\t\t{dep_ui} /* PBXTargetDependency */ = {{\n")
    text.append("\t\t\tisa = PBXTargetDependency;\n")
    text.append(f"\t\t\ttarget = {target_app} /* BeadWorks */;\n")
    text.append(f"\t\t\ttargetProxy = {proxy_ui} /* PBXContainerItemProxy */;\n")
    text.append("\t\t};\n")
    text.append("/* End PBXTargetDependency section */\n\n")
    text.append(Path(__file__).with_name("pbxproj_build_settings.snippet").read_text())
    text.append("\t};\n")
    text.append(f"\trootObject = {project_id} /* Project object */;\n")
    text.append("}\n")

    PBX.write_text("".join(text))
    print(f"Wrote {PBX} with {len(app_swift)} app, {len(test_swift)} unit, {len(ui_swift)} ui files")


if __name__ == "__main__":
    os.chdir(ROOT)
    main()
