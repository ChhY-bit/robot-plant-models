# 人形机器人工具函数 {#humanoid-robot-utils}

这些 `rpm.utils` 命名空间中的公共函数用于读取机器人描述文件。使用前，应将项目根目录（`+rpm/` 的父目录）添加到 MATLAB 搜索路径。它们是独立函数，不是机器人对象的方法。

## 1. 读取 URDF {#1-load-urdf}

### `rpm.utils.load_urdf(file_path)` {#rpm-utils-load-urdf}

读取 URDF 文件，将连杆和关节描述转换为 MATLAB 结构体。显式传入的相对路径以当前工作目录为基准。函数使用基础 MATLAB 和 Java，不需要额外工具箱。

- **参数：**
    - `file_path`（必填）
        - 类型：`1x1 string`（也接受可转换为字符串标量的字符向量）
        - 含义：已有 URDF 文件的路径
- **返回值：**
    - `urdf`
        - 类型：包含下列五个字段的标量 `struct`
        - 含义：静态机器人描述；数值属性保存为 `double` 标量或列向量，名称和文件名保存为字符串
- **用法：**
    ```matlab
    urdf = rpm.utils.load_urdf("g1_23dof.urdf");
    name = urdf.name;
    mass = urdf.links(1).inertial.mass;
    parent = urdf.joints(1).parent;
    child = urdf.joints(1).child;
    root = urdf.links(urdf.rootLinkIndex);
    ```

| 字段 | 内容 |
| --- | --- |
| `name` | XML `<robot name="...">` 属性中的机器人名称，不是文件名。 |
| `sourceFile` | URDF 文件的绝对路径。 |
| `links` | 列结构体数组，包含 `name`、`inertial`、`visual` 和 `collision`。 |
| `joints` | 列结构体数组，包含 `name`、`type`、`parent`、`child`、`origin`、`axis`、`limit`、`dynamics`、`mimic`、`safety_controller` 和 `calibration`。 |
| `rootLinkIndex` | 根连杆在 `links` 中的索引，从 1 开始的标量。 |

根连杆是未被任何关节引用为子连杆的连杆，不一定是第一个声明的连杆。XML 注释不参与识别：G1 示例中，`world` 及其浮动关节被注释时，根为 `pelvis`；加入该连接后，根为 `world`。根节点识别不决定仿真基座是固定基还是浮动基。重新排列或删除连杆后，应重新计算索引。

连杆和关节保留声明顺序。关节的 `parent` 和 `child` 保存连杆名称。嵌套结构体遵循 URDF 层级，例如 `origin.xyz`、`origin.rpy`、`inertial.inertia.ixx` 和 `visual.geometry.mesh.filename`。每个连杆可包含多个视觉和碰撞元素。找到具名全局材质时，会将其解析到对应的视觉元素中。

缺失的元素和数值属性为 `[]`，缺失的字符串属性为空字符串，不会自动补默认值。XML 注释会被忽略，网格文件名原样保留而不加载对应文件，已知仿真器扩展（`mujoco` 和 `gazebo`）会被静默跳过。其他不支持的元素或属性会被跳过并发出警告。应传入展开后的 URDF，而不是 Xacro。

函数检查 XML 解析、数值转换以及连接是否构成一棵有根树。缺失或重复的连杆/关节名称、缺失或未知的父/子连杆引用、多父节点、环路和不连通的连杆均会被拒绝。允许没有关节的单个连杆。函数不计算坐标变换、校验物理参数或模拟机器人运动。

读取器的错误和警告标识符使用前缀 `rpm:load_urdf:`：

| 标识符后缀 | 含义 |
| --- | --- |
| `FileNotFound` | 输入路径为空或文件不存在。 |
| `InvalidXML` | 无法读取 XML 文件。 |
| `InvalidRoot` | 根元素不是 `robot`。 |
| `InvalidAttribute` | 数值属性的值或元素个数无效。 |
| `DuplicateElement` | 只能出现一次的子元素重复出现。 |
| `InvalidTopology` | 连杆/关节名称或连接无法构成一棵有根树。 |
| `UnsupportedElement` | 警告：跳过不支持的元素。 |
| `UnsupportedAttribute` | 警告：跳过不支持的属性。 |

MATLAB 参数校验和文件系统错误也可能直接传出。
