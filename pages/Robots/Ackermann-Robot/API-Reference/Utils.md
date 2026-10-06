# Ackermann-Robot Utils

These public functions in the `rpm.utils` namespace load parameter files and export configuration templates. Call them with the project root (the parent of `+rpm/`) on the MATLAB search path. They are standalone functions, not robot object methods.

## 1. Load Parameters {#1-load-parameters}

### `rpm.utils.load_ackermann_params(file_path)` {#rpm-utils-load-ackermann-params}

Read, normalize, and validate a YAML parameter file. Omit `file_path` or pass `""` to load the bundled `+rpm/config/ackermann_robot.yaml`, regardless of the current working directory. An explicit relative path is resolved from the current working directory.

- **Argument:**
    - `file_path` (optional)
        - type: `1x1 string` (character vectors convertible to a string scalar are also accepted)
        - default: `""`
        - meaning: path to an existing YAML parameter file; `[]` is not an empty-path shortcut
- **Return:**
    - `params`
        - type: scalar `struct` with all required fields below, stored as `double` scalars or column vectors
        - meaning: parameters that can be passed directly to `rpm.ackermann_robot(params)`; additional YAML fields are not returned
- **see also:** [<u>property `Params`</u>](Properties.md#3-params), [<u>constructor `rpm.ackermann_robot`</u>](Methods.md#rpm-ackermann-robot), [<u>function `rpm.utils.export_ackermann_params`</u>](#rpm-utils-export-ackermann-params)
- **Usage:**
    ```matlab
    params = rpm.utils.load_ackermann_params(); % Bundled defaults
    params.maxPhysicalSteeringAngle = 0.5;
    robot = rpm.ackermann_robot(params);

    % Load a custom YAML file instead
    params = rpm.utils.load_ackermann_params("my_ackermann_robot.yaml");
    robot = rpm.ackermann_robot(params);
    ```

All fields in this table are required. Values must be numeric, finite, and real; compatible numeric cells returned by a YAML reader are converted to numeric arrays.

| Field | Accepted value | Unit |
| --- | --- | --- |
| `wheelRadius`, `wheelBase`, `trackWidth`, `wheelWidth` | Positive scalar | m |
| `wheelTimeConstant`, `steeringTimeConstant` | Nonnegative scalar | s |
| `maxPhysicalWheelSpeed` | Positive scalar | rad/s |
| `maxPhysicalSteeringAngle` | Positive scalar, strictly less than `pi/2` | rad |
| `bodySize` | Three positive elements; normalized to `3x1`, ordered length, width, height | m |
| `rearAxleOffset` | Finite real scalar; either sign or zero | m |

The loader preserves zero time constants without warning or replacement. The robot constructor warns and replaces each zero time constant with `1e-3` s; use `robot.getParams()` to read the actual simulation parameters.

If `readyaml` is available on the MATLAB path, the loader uses it. Otherwise, the built-in fallback supports only top-level `key: number` and `key: [number, ...]` entries with JSON-compatible numeric values. It skips blank lines and whole-line `#` comments. Nested YAML, block sequences, and inline comments are outside this fallback syntax.

The loader's error identifiers use the prefix `ackermann_robot:`:

| Identifier suffix | Meaning |
| --- | --- |
| `ParameterFileNotFound` | The input file does not exist. |
| `MissingParameter` | A required field is missing. |
| `InvalidParameterType` | A required field is not numeric or numeric cells cannot be combined. |
| `InvalidParameterSize` | A required field has the wrong number of elements or shape. |
| `InvalidParameterValue` | A required field contains nonfinite, complex, or out-of-range values. |
| `InvalidYAML` | The fallback reader encounters a missing colon or invalid field name. |
| `UnsupportedYAML` | A fallback entry has no inline value, such as nested YAML. |
| `DuplicateParameter` | The fallback reader encounters a duplicate field name. |
| `InvalidYAMLValue` | The fallback reader cannot decode a value as JSON. |
| `UnsupportedYAMLValue` | A fallback value is not numeric. |

Errors from `readyaml`, file reading, and MATLAB argument validation may also propagate.

## 2. Export Parameters {#2-export-parameters}

### `rpm.utils.export_ackermann_params(file_path)` {#rpm-utils-export-ackermann-params}

Copy the bundled `+rpm/config/ackermann_robot.yaml` template, including its comments, to a new file. This exports bundled defaults, not an existing robot's current parameters. Omit `file_path` or pass `""` to create `ackermann_robot.yaml` in the current working directory. Existing files and directories at the target path are rejected without overwriting.

- **Argument:**
    - `file_path` (optional)
        - type: `1x1 string` (character vectors convertible to a string scalar are also accepted)
        - default: `""`
        - meaning: new destination file path; relative paths use the current working directory; `[]` is not an empty-path shortcut
- **Return:**
    - `file_path`
        - type: `1x1 string`
        - meaning: full path of the exported file, even if the input path was relative
- **see also:** [<u>function `rpm.utils.load_ackermann_params`</u>](#rpm-utils-load-ackermann-params), [<u>property `Params`</u>](Properties.md#3-params)
- **Usage:**
    ```matlab
    file_path = rpm.utils.export_ackermann_params(); % Target must not exist
    % Edit the exported YAML file before loading it
    params = rpm.utils.load_ackermann_params(file_path);
    robot = rpm.ackermann_robot(params);
    ```

    ```matlab
    % Export to an existing parent directory with a new file name
    file_path = rpm.utils.export_ackermann_params( ...
        fullfile(pwd, "my_ackermann_robot.yaml"));
    ```

Create any parent directory before exporting; the function does not create it. Export errors use the prefix `ackermann_robot:`:

| Identifier suffix | Meaning |
| --- | --- |
| `TemplateFileNotFound` | The bundled YAML template is missing. |
| `ExportTargetExists` | A file or directory already exists at the target path. |
| `ExportFailed` | `copyfile` reports a failure to copy the template. |

MATLAB argument validation or file-operation errors may also propagate.

