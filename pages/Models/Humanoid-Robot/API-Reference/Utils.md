# Humanoid-Robot Utils

These public functions in the `rpm.utils` namespace read robot description files. Call them with the project root (the parent of `+rpm/`) on the MATLAB search path. They are standalone functions, not robot object methods.

## 1. Load URDF {#1-load-urdf}

### `rpm.utils.load_urdf(file_path)` {#rpm-utils-load-urdf}

Read a URDF file and convert its link and joint descriptions to MATLAB structs. An explicit relative path is resolved from the current working directory. The function uses base MATLAB with Java and does not require additional toolboxes.

- **Argument:**
    - `file_path` (required)
        - type: `1x1 string` (character vectors convertible to a string scalar are also accepted)
        - meaning: path to an existing URDF file
- **Return:**
    - `urdf`
        - type: scalar `struct` with the five fields below
        - meaning: static robot description; numeric attributes are stored as `double` scalars or column vectors, and names and filenames as strings
- **Usage:**
    ```matlab
    urdf = rpm.utils.load_urdf("g1_23dof.urdf");
    name = urdf.name;
    mass = urdf.links(1).inertial.mass;
    parent = urdf.joints(1).parent;
    child = urdf.joints(1).child;
    root = urdf.links(urdf.rootLinkIndex);
    ```

| Field | Content |
| --- | --- |
| `name` | Robot name from the XML `<robot name="...">` attribute, not the filename. |
| `sourceFile` | Absolute path to the URDF file. |
| `links` | Column struct array with `name`, `inertial`, `visual`, and `collision`. |
| `joints` | Column struct array with `name`, `type`, `parent`, `child`, `origin`, `axis`, `limit`, `dynamics`, `mimic`, `safety_controller`, and `calibration`. |
| `rootLinkIndex` | One-based scalar index of the root link in `links`. |

The root is the link not referenced as any joint's child. It need not be the first declared link. XML comments do not participate: in the G1 example, the root is `pelvis` while `world` and its floating joint are commented out; including that connection makes `world` the root. Root identification does not determine whether the simulation base is fixed or floating. Recompute the index if links are reordered or removed.

Links and joints retain their declaration order. Joint `parent` and `child` store link names. Nested structs follow the URDF hierarchy: for example, `origin.xyz`, `origin.rpy`, `inertial.inertia.ixx`, and `visual.geometry.mesh.filename`. Each link can contain multiple visuals and collisions. Named global materials are resolved into the corresponding visual when found.

Missing elements and numeric attributes are `[]`; missing string attributes are empty strings. No defaults are inserted. XML comments are ignored, mesh filenames are preserved without loading their files, and known simulator extensions (`mujoco` and `gazebo`) are silently skipped. Other unsupported elements or attributes are skipped with warnings. Supply an expanded URDF rather than Xacro.

The function checks XML parsing, numeric conversion, and that connections form one rooted tree. It rejects missing or duplicate link/joint names, missing or unknown parent/child references, multiple parents, cycles, and disconnected links. A single link without joints is allowed. It does not compute coordinate transformations, validate physical parameters, or simulate robot motion.

The loader's error and warning identifiers use the prefix `rpm:load_urdf:`:

| Identifier suffix | Meaning |
| --- | --- |
| `FileNotFound` | The input path is empty or the file does not exist. |
| `InvalidXML` | The XML file cannot be read. |
| `InvalidRoot` | The root element is not `robot`. |
| `InvalidAttribute` | A numeric attribute has invalid values or element count. |
| `DuplicateElement` | A singleton child element is repeated. |
| `InvalidTopology` | Link/joint names or connections do not form one rooted tree. |
| `UnsupportedElement` | Warning: an unsupported element is skipped. |
| `UnsupportedAttribute` | Warning: an unsupported attribute is skipped. |

MATLAB argument validation and filesystem errors may also propagate.

