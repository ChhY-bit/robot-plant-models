# Quadruple-Tank Utils

These standalone functions in `rpm.utils` read parameter files and export templates. Put the project root (the parent of `+rpm/`) on the MATLAB search path. They are not tank object methods.

## 1. Load Parameters {#1-load-parameters}

### `rpm.utils.load_quadruple_tank_params(file_path)` {#rpm-utils-load-quadruple-tank-params}

Read, validate, and normalize the 19 physical fields listed in [Properties](Properties.md#2-physical-parameters). Returned names match the YAML keys; the constructor validates and stores the structure in private `Params`.

- **Argument:** `file_path` (optional): `1x1 string`, or a character vector convertible to one. Default `""` selects bundled `+rpm/config/quadruple_tank.yaml` independently of the current working directory. Explicit relative paths use the current working directory. `[]` is not an empty-path shortcut.
- **Return:** `params`, a scalar structure containing exactly the 19 recognized fields as `double` scalars. Extra YAML fields are not returned.
- **see also:** [constructor](Methods.md#rpm-quadruple-tank), [template export](#rpm-utils-export-quadruple-tank-params).
- **Usage:**

    ```matlab
    params = rpm.utils.load_quadruple_tank_params();
    params.gamma_1 = 0.3;
    tank = rpm.quadruple_tank(params);
    ```

    ```matlab
    params = rpm.utils.load_quadruple_tank_params("my_quadruple_tank.yaml");
    tank = rpm.quadruple_tank(params, [0.1; 0.1; 0.1; 0.1]);
    ```

All required fields must be numeric, real, finite scalars. Tank areas, hole areas, `g`, tank heights, maximum flows, and design flow speeds must be positive; `gamma_1` and `gamma_2` must lie in `[0, 1]`. Missing fields are errors rather than requests for individual defaults. Initial water levels, pump inputs, and disturbances are not part of the parameter structure.

The loader uses `readyaml` if it is available. Otherwise, the built-in fallback reads top-level `key: number` or `key: [number, ...]` entries with JSON-compatible numeric values. Required tank parameters must still be scalars. Blank lines and whole-line `#` comments are accepted; nested YAML, block sequences, and inline comments are outside the fallback syntax.

Loader errors use the prefix `quadruple_tank:`:

| Identifier suffix | Meaning |
| --- | --- |
| `ParameterFileNotFound` | The input parameter file does not exist. |
| `MissingParameter` | A required field is missing. |
| `InvalidParameterType` | A required field is not numeric. |
| `InvalidParameterSize` | A required field is not a scalar. |
| `InvalidParameterValue` | A required field is nonfinite, complex, or outside its range. |
| `InvalidYAML` | The fallback reader encounters a missing colon or invalid field name. |
| `UnsupportedYAML` | A fallback entry has no inline value. |
| `DuplicateParameter` | The fallback reader encounters a repeated key. |
| `InvalidYAMLValue` | The fallback reader cannot decode a value as JSON. |
| `UnsupportedYAMLValue` | A fallback value is not numeric. |

Errors from `readyaml`, file reading, and MATLAB argument validation may also propagate.

## 2. Export Parameters {#2-export-parameters}

### `rpm.utils.export_quadruple_tank_params(file_path)` {#rpm-utils-export-quadruple-tank-params}

Copy the bundled YAML template, including comments, to a new file. This exports bundled defaults rather than the current settings of a tank object. Existing files and directories at the destination are rejected without overwriting.

- **Argument:** `file_path` (optional): `1x1 string`, or a character vector convertible to one. Default `""` creates `quadruple_tank.yaml` in the current working directory. Explicit relative paths also use that directory; `[]` is not an empty-path shortcut.
- **Return:** `file_path`, a string scalar containing the full path of the copied file.
- **see also:** [parameter loader](#rpm-utils-load-quadruple-tank-params), [physical parameters](Properties.md#2-physical-parameters).
- **Usage:**

    ```matlab
    file_path = rpm.utils.export_quadruple_tank_params("my_quadruple_tank.yaml");
    % Edit the exported YAML before loading it.
    params = rpm.utils.load_quadruple_tank_params(file_path);
    tank = rpm.quadruple_tank(params);
    ```

Create the parent directory before exporting. Export errors use the prefix `quadruple_tank:`:

| Identifier suffix | Meaning |
| --- | --- |
| `TemplateFileNotFound` | The bundled YAML template is missing. |
| `ExportTargetExists` | A file or directory already exists at the target path. |
| `ExportFailed` | `copyfile` reports a copy failure. |

MATLAB argument validation or file-operation errors may also propagate.
