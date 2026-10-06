# 差速轮式机器人工具函数 {#wheel-robot-utils}

这些 `rpm.utils` 命名空间中的公共函数用于加载参数文件和导出配置模板。使用前，应将项目根目录（`+rpm/` 的父目录）添加到 MATLAB 搜索路径。它们是独立函数，不是机器人对象的方法。

## 1. 加载参数 {#1-load-parameters}

### `rpm.utils.load_wheel_params(file_path)` {#rpm-utils-load-wheel-params}

读取、规范化并校验 YAML 参数文件。省略 `file_path` 或传入 `""` 时，读取内置的 `+rpm/config/wheel_robot.yaml`，不受当前工作目录影响。显式传入的相对路径以当前工作目录为基准。

- **参数：**
    - `file_path`（可选）
        - 类型：`1x1 string`（也接受可转换为字符串标量的字符向量）
        - 默认值：`""`
        - 含义：已有 YAML 参数文件的路径；不能使用 `[]` 代替空路径
- **返回值：**
    - `params`
        - 类型：标量 `struct`，包含下表全部必需字段，以 `double` 标量或列向量存储
        - 含义：可直接传入 `rpm.wheel_robot(params)` 的参数；不返回 YAML 中的额外字段
- **另见：** [<u>属性 `Params`</u>](Properties.md#3-params), [<u>构造函数 `rpm.wheel_robot`</u>](Methods.md#rpm-wheel-robot), [<u>函数 `rpm.utils.export_wheel_params`</u>](#rpm-utils-export-wheel-params)
- **用法：**
    ```matlab
    params = rpm.utils.load_wheel_params(); % Bundled defaults
    params.wheelRadius = [0.08; 0.12];
    robot = rpm.wheel_robot(params);

    % Load a custom YAML file instead
    params = rpm.utils.load_wheel_params("my_wheel_robot.yaml");
    robot = rpm.wheel_robot(params);
    ```

下表中的所有字段均为必需字段。值必须是有限实数的数值类型；YAML 读取器返回的兼容数值元胞会转换为数值数组。 双元素车轮参数按左轮、右轮排列。标量车轮参数会复制到左右两轮；双元素值会转换为列向量。

| 字段 | 允许的值 | 单位 |
| --- | --- | --- |
| `wheelRadius`、`wheelWidth` | 正数标量或双元素数值；规范为 `2x1` | m |
| `trackWidth` | 正数标量 | m |
| `motorTimeConstant` | 非负标量或双元素数值；规范为 `2x1` | s |
| `maxWheelSpeed` | 正数标量或双元素数值；规范为 `2x1` | rad/s |
| `bodySize` | 三个正数元素；规范为 `3x1`，依次为长、宽、高 | m |
| `axleOffset` | 有限实数标量；可为正、负或零 | m |

加载函数保留零时间常数，不发出警告或替换数值。机器人构造函数会发出警告，并将每个零时间常数替换为 `1e-3` s；通过 `robot.getParams()` 可读取实际仿真参数。

MATLAB 路径中存在 `readyaml` 时，加载函数使用它。否则，内置回退读取器仅支持顶层的 `key: number` 和 `key: [number, ...]`，数值必须兼容 JSON。它跳过空行及整行 `#` 注释；回退语法不支持嵌套 YAML、块序列和行内注释。

加载函数的错误标识符以 `wheel_robot:` 为前缀：

| 标识符后缀 | 含义 |
| --- | --- |
| `ParameterFileNotFound` | 输入文件不存在。 |
| `MissingParameter` | 缺少必需字段。 |
| `InvalidParameterType` | 必需字段不是数值类型，或无法合并数值元胞。 |
| `InvalidParameterSize` | 必需字段的元素数量或形状不正确。 |
| `InvalidParameterValue` | 必需字段包含非有限值、复数或超出范围的数值。 |
| `InvalidYAML` | 回退读取器遇到缺失的冒号或无效字段名。 |
| `UnsupportedYAML` | 回退读取器遇到没有行内值的条目，例如嵌套 YAML。 |
| `DuplicateParameter` | 回退读取器遇到重复字段名。 |
| `InvalidYAMLValue` | 回退读取器无法按 JSON 解码数值。 |
| `UnsupportedYAMLValue` | 回退读取器读到非数值类型的值。 |

`readyaml`、文件读取及 MATLAB 参数校验产生的错误也可能直接传出。

## 2. 导出参数 {#2-export-parameters}

### `rpm.utils.export_wheel_params(file_path)` {#rpm-utils-export-wheel-params}

将内置的 `+rpm/config/wheel_robot.yaml` 模板连同注释复制到新文件。导出的是内置默认参数，不是已有机器人的当前参数。省略 `file_path` 或传入 `""` 时，在当前工作目录创建 `wheel_robot.yaml`。目标路径已有文件或目录时会拒绝导出，不会覆盖。

- **参数：**
    - `file_path`（可选）
        - 类型：`1x1 string`（也接受可转换为字符串标量的字符向量）
        - 默认值：`""`
        - 含义：新目标文件的路径；相对路径以当前工作目录为基准；不能使用 `[]` 代替空路径
- **返回值：**
    - `file_path`
        - 类型：`1x1 string`
        - 含义：导出文件的完整路径，即使输入为相对路径
- **另见：** [<u>函数 `rpm.utils.load_wheel_params`</u>](#rpm-utils-load-wheel-params), [<u>属性 `Params`</u>](Properties.md#3-params)
- **用法：**
    ```matlab
    file_path = rpm.utils.export_wheel_params(); % Target must not exist
    % Edit the exported YAML file before loading it
    params = rpm.utils.load_wheel_params(file_path);
    robot = rpm.wheel_robot(params);
    ```

    ```matlab
    % Export to an existing parent directory with a new file name
    file_path = rpm.utils.export_wheel_params( ...
        fullfile(pwd, "my_wheel_robot.yaml"));
    ```

导出前应创建所需的父目录；该函数不创建父目录。导出错误以 `wheel_robot:` 为前缀：

| 标识符后缀 | 含义 |
| --- | --- |
| `TemplateFileNotFound` | 内置 YAML 模板不存在。 |
| `ExportTargetExists` | 目标路径已有文件或目录。 |
| `ExportFailed` | `copyfile` 报告模板复制失败。 |

MATLAB 参数校验或文件操作产生的错误也可能直接传出。

