# Versioning and releases

The root `VERSION` file is the single maintained project version. It contains one numeric `major.minor.patch` value without a `v` prefix. Keep this format compatible with the supported MATLAB R2024a packaging workflow. Git commit IDs and working-tree state are recorded separately in build metadata.

Read the version from MATLAB with the project root on the search path:

```matlab
value = rpm.version();
```

The function locates `VERSION` relative to its own file and works in source checkouts, extracted ZIPs, and installed toolboxes without Git. Use the fully qualified name to distinguish it from MATLAB's built-in `version` function. Missing or malformed version files cause explicit errors.

## Build a release

1. Update `VERSION` for the intended release and finish validation.
2. Commit the source, including `VERSION`, and create the matching `v<VERSION>` tag on that commit. The release builder checks for both the matching tag and a clean working tree, including untracked files.
3. From the repository root in MATLAB R2024a or later, run:

```matlab
addpath('scripts');
artifacts = build_release();
```

The builder reads `rpm.version()`, stages `+rpm/`, `VERSION`, `LICENSE`, `README.md`, `RELEASING.md`, `setup.m`, and `BUILD_INFO.json`, then creates a source ZIP and `.mltbx` under `dist/v<VERSION>/`. It sets the toolbox version from the same value and checks the generated toolbox metadata before creating the ZIP. Only the staging root is added to the installed MATLAB path. The toolbox identifier is retained from the previous packaging project so releases represent the same add-on. Release-building scripts remain in the repository; run builds from a full checkout.

`BUILD_INFO.json` records the version, Git commit, dirty state, tags, and whether release checks were enabled. No version query requires this optional metadata. This command does not install, commit, tag, push, or publish anything. Existing output directories are never overwritten; failed builds leave their output for inspection.

For a local preview, explicitly disable the tag and clean-tree requirement:

```matlab
addpath('scripts');
artifacts = build_release(RequireTag=false);
```

Preview builds still check version syntax and toolbox-version consistency, include metadata identifying the unchecked build, and reject existing output directories. In a source ZIP without Git, use this preview option to build locally; the metadata records that Git was unavailable.

The ignored `packaging/*.prj` files and existing `dist/v0.1.0/` artifacts are historical snapshots. The tracked `scripts/build_release.m` entry point replaces their manually maintained version and absolute source paths for future builds.

## Website version

The website reads the same root `VERSION` at configuration/build time and displays it in the English and Chinese footers. Version changes trigger the website workflow. Its build version describes the documentation source; the Releases link continues to identify published downloads. `pages/package.json` describes the private website tooling and does not maintain a separate project version.

## 版本维护说明

只在根目录 `VERSION` 维护项目版本，格式为不带 `v` 前缀的三段非负整数，例如 `0.1.0`。MATLAB 使用 `rpm.version()` 查询；网站构建读取同一文件，中英文页脚同步显示。Git 提交号和未提交状态独立保存在构建产物的 `BUILD_INFO.json`。

正式构建前应提交所有更改，并在当前提交创建与 `VERSION` 一致的 `v<VERSION>` 标签，再运行 `build_release()`。仅预览时可显式使用 `RequireTag=false`。构建函数不会创建标签、上传或安装，也不会覆盖已有发布目录。源码 ZIP 和工具箱都包含 `VERSION`，安装后无需 Git 即可查询版本。历史 `.prj` 和旧发布包不再作为新版本的维护来源。
