# 四水箱容器工具函数 {#quadruple-tank-utils}

这些独立函数属于 `rpm.utils`，用于读取参数文件和导出模板。应将项目根目录（`+rpm/` 的父目录）加入 MATLAB 搜索路径。它们不是水箱对象的方法。

## 1. 加载参数 {#1-load-parameters}

### `rpm.utils.load_quadruple_tank_params(file_path)` {#rpm-utils-load-quadruple-tank-params}

读取、校验并规范化[属性文档](Properties.md#2-physical-parameters)中的 19 个物理字段。返回字段名与 YAML 键一致，构造函数校验后直接保存为私有 `Params`。

- **参数：** `file_path`（可选）：`1x1 string`，或可转换为字符串标量的字符向量。默认 `""` 选择随附 `+rpm/config/quadruple_tank.yaml`，不受当前工作目录影响。显式相对路径基于当前工作目录。`[]` 不能代替空路径字符串。
- **返回值：** `params`，标量结构体，仅包含 19 个已识别字段，均为 `double` 标量。额外 YAML 字段不会返回。
- **另见：** [构造函数](Methods.md#rpm-quadruple-tank)、[模板导出](#rpm-utils-export-quadruple-tank-params)。
- **用法：**

    ```matlab
    params = rpm.utils.load_quadruple_tank_params();
    params.gamma_1 = 0.3;
    tank = rpm.quadruple_tank(params);
    ```

    ```matlab
    params = rpm.utils.load_quadruple_tank_params("my_quadruple_tank.yaml");
    tank = rpm.quadruple_tank(params, [0.1; 0.1; 0.1; 0.1]);
    ```

所有必需字段均须为有限实数数值标量。水箱面积、出水孔面积、`g`、箱高、最大流量及设计流速必须大于零；`gamma_1` 和 `gamma_2` 必须在 `[0, 1]` 内。缺少字段会报错，不会逐项补默认值。初始液位、水泵输入和扰动不属于参数结构体。

若存在 `readyaml`，加载器会使用它；否则，内置回退读取器支持顶层 `key: number` 或 `key: [number, ...]`，数值须兼容 JSON。水箱的必需参数仍须为标量。接受空行和整行 `#` 注释；不支持嵌套 YAML、块序列或行内注释。

加载器错误标识符使用 `quadruple_tank:` 前缀：

| 标识符后缀 | 含义 |
| --- | --- |
| `ParameterFileNotFound` | 输入参数文件不存在。 |
| `MissingParameter` | 缺少必需字段。 |
| `InvalidParameterType` | 必需字段不是数值。 |
| `InvalidParameterSize` | 必需字段不是标量。 |
| `InvalidParameterValue` | 必需字段包含非有限值、复数或超范围值。 |
| `InvalidYAML` | 回退读取器遇到缺失冒号或非法字段名。 |
| `UnsupportedYAML` | 回退条目没有行内值。 |
| `DuplicateParameter` | 回退读取器遇到重复键。 |
| `InvalidYAMLValue` | 回退读取器无法按 JSON 解码值。 |
| `UnsupportedYAMLValue` | 回退条目的值不是数值。 |

`readyaml`、文件读取及 MATLAB 参数校验的错误也可能直接传出。

## 2. 导出参数 {#2-export-parameters}

### `rpm.utils.export_quadruple_tank_params(file_path)` {#rpm-utils-export-quadruple-tank-params}

将随附 YAML 模板连同注释复制到新文件。导出的是内置默认参数，而非水箱对象的当前设置。目标位置已有文件或目录时会报错，不会覆盖。

- **参数：** `file_path`（可选）：`1x1 string`，或可转换为字符串标量的字符向量。默认 `""` 在当前工作目录创建 `quadruple_tank.yaml`。显式相对路径也基于该目录；`[]` 不能代替空路径字符串。
- **返回值：** `file_path`，包含导出文件完整路径的字符串标量。
- **另见：** [参数加载器](#rpm-utils-load-quadruple-tank-params)、[物理参数](Properties.md#2-physical-parameters)。
- **用法：**

    ```matlab
    file_path = rpm.utils.export_quadruple_tank_params("my_quadruple_tank.yaml");
    % Edit the exported YAML before loading it.
    params = rpm.utils.load_quadruple_tank_params(file_path);
    tank = rpm.quadruple_tank(params);
    ```

导出前应先创建父目录。导出错误使用 `quadruple_tank:` 前缀：

| 标识符后缀 | 含义 |
| --- | --- |
| `TemplateFileNotFound` | 随附 YAML 模板缺失。 |
| `ExportTargetExists` | 目标位置已存在文件或目录。 |
| `ExportFailed` | `copyfile` 报告复制失败。 |

MATLAB 参数校验或文件操作错误也可能直接传出。
