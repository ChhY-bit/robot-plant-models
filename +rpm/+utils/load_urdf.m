function urdf = load_urdf(file_path)
%LOAD_URDF Convert a URDF file to ordinary MATLAB structs.
%   URDF = rpm.utils.load_urdf(FILE_PATH) returns name, sourceFile, links,
%   joints, and rootLinkIndex. Checks that connections form one rooted tree.
%   No kinematics or physical validation is performed.
%   Optional elements are [], repeated elements are column struct arrays.
%   Requires base MATLAB with Java; no robotics toolbox is needed.
    arguments
        file_path (1,1) string
    end
    if strlength(file_path) == 0 || ~isfile(file_path)
        error('rpm:load_urdf:FileNotFound', 'URDF file not found: %s', file_path);
    end
    source = java.io.File(char(file_path));
    source_file = string(char(source.getCanonicalPath()));
    try
        document = xmlread(char(source_file));
    catch cause
        exception = MException('rpm:load_urdf:InvalidXML', ...
            'Cannot read URDF XML: %s', source_file);
        throw(addCause(exception, cause));
    end
    root = document.getDocumentElement();
    if ~strcmp(char(root.getNodeName()), 'robot')
        error('rpm:load_urdf:InvalidRoot', 'The root element must be robot.');
    end
    urdf = struct('name', string(char(root.getAttribute('name'))), ...
        'sourceFile', source_file, 'links', [], 'joints', []);
    materials = [];
    nodes = root.getChildNodes();
    for k = 0:nodes.getLength()-1
        node = nodes.item(k);
        if node.getNodeType() ~= 1, continue; end
        tag = char(node.getNodeName());
        switch tag
            case 'link'
                urdf.links = append_struct(urdf.links, parse_element(node));
            case 'joint'
                urdf.joints = append_struct(urdf.joints, parse_element(node));
            case 'material'
                materials = append_struct(materials, parse_element(node));
            case {'mujoco', 'gazebo'}
                % Simulator-specific extensions do not describe URDF data.
                continue;
            otherwise
                warning('rpm:load_urdf:UnsupportedElement', ...
                    'Ignoring robot-level element <%s>.', tag);
        end
    end
    urdf.rootLinkIndex = find_root(urdf.links, urdf.joints);
    % Resolve named global materials inside each visual.
    for i = 1:numel(urdf.links)
        for j = 1:numel(urdf.links(i).visual)
            material = urdf.links(i).visual(j).material;
            if isempty(material) || material.name == "", continue; end
            if ~isempty(material.color) || ~isempty(material.texture), continue; end
            for m = 1:numel(materials)
                if materials(m).name == material.name
                    urdf.links(i).visual(j).material = materials(m);
                    break;
                end
            end
        end
    end
end

function root_index = find_root(links, joints)
    if isempty(links)
        error('rpm:load_urdf:InvalidTopology', 'URDF must contain at least one link.');
    end
    names = [links.name];
    if any(strlength(strtrim(names)) == 0) || numel(unique(names)) ~= numel(names)
        error('rpm:load_urdf:InvalidTopology', 'Link names must be nonempty and unique.');
    end
    parent_indices = zeros(numel(links), 1);
    if ~isempty(joints)
        joint_names = [joints.name];
        if any(strlength(strtrim(joint_names)) == 0) || ...
                numel(unique(joint_names)) ~= numel(joint_names)
            error('rpm:load_urdf:InvalidTopology', 'Joint names must be nonempty and unique.');
        end
    end
    for i = 1:numel(joints)
        joint = joints(i);
        if isempty(joint.parent) || isempty(joint.child)
            error('rpm:load_urdf:InvalidTopology', ...
                'Joint %s must specify parent and child links.', joint.name);
        end
        parent = find(names == joint.parent);
        child = find(names == joint.child);
        if isempty(parent) || isempty(child)
            error('rpm:load_urdf:InvalidTopology', ...
                'Joint %s references an unknown parent or child link.', joint.name);
        end
        if parent == child || parent_indices(child) ~= 0
            error('rpm:load_urdf:InvalidTopology', ...
                'Joint %s forms a self-connection or gives link %s multiple parents.', ...
                joint.name, joint.child);
        end
        parent_indices(child) = parent;
    end
    root_index = find(parent_indices == 0);
    if numel(root_index) ~= 1
        error('rpm:load_urdf:InvalidTopology', ...
            'Expected one root link; found %d.', numel(root_index));
    end
    % A unique root alone does not exclude a disconnected cycle.
    visited = false(numel(links), 1);
    queue = zeros(numel(links), 1);
    queue(1) = root_index;
    tail = 1;
    head = 1;
    while head <= tail
        current = queue(head);
        visited(current) = true;
        children = find(parent_indices == current);
        queue(tail+1:tail+numel(children)) = children;
        tail = tail + numel(children);
        head = head + 1;
    end
    if ~all(visited)
        error('rpm:load_urdf:InvalidTopology', ...
            'Links must form one connected tree without cycles.');
    end
end

function value = parse_element(node)
    tag = char(node.getNodeName());
    value = template(tag);
    attributes = node.getAttributes();
    for i = 0:attributes.getLength()-1
        attribute = attributes.item(i);
        key = char(attribute.getNodeName());
        if ~isfield(value, key)
            warning('rpm:load_urdf:UnsupportedAttribute', ...
                'Ignoring attribute %s on <%s>.', key, tag);
            continue;
        end
        raw = string(char(attribute.getNodeValue()));
        if any(strcmp(key, {'name','type','filename','joint'}))
            value.(key) = raw;
        else
            value.(key) = parse_number(raw, tag, key);
        end
    end
    children = node.getChildNodes();
    for i = 0:children.getLength()-1
        child = children.item(i);
        if child.getNodeType() ~= 1, continue; end
        key = char(child.getNodeName());
        if any(strcmp(key, {'mujoco', 'gazebo'})), continue; end
        if ~isfield(value, key)
            warning('rpm:load_urdf:UnsupportedElement', ...
                'Ignoring <%s> inside <%s>.', key, tag);
            continue;
        end
        switch key
            case {'parent','child'}
                parsed = string(char(child.getAttribute('link')));
            case 'axis'
                parsed = parse_number(string(char(child.getAttribute('xyz'))), key, 'xyz');
            case 'mass'
                parsed = parse_number(string(char(child.getAttribute('value'))), key, 'value');
            otherwise
                parsed = parse_element(child);
        end
        if any(strcmp(key, {'visual','collision'}))
            value.(key) = append_struct(value.(key), parsed);
        else
            if ~isempty(value.(key))
                error('rpm:load_urdf:DuplicateElement', ...
                    'Repeated <%s> inside <%s>.', key, tag);
            end
            value.(key) = parsed;
        end
    end
end

function value = template(tag)
    switch tag
        case 'link', fields = {'name','inertial','visual','collision'};
        case 'joint', fields = {'name','type','parent','child','origin','axis','limit','dynamics','mimic','safety_controller','calibration'};
        case 'inertial', fields = {'origin','mass','inertia'};
        case 'origin', fields = {'xyz','rpy'};
        case 'inertia', fields = {'ixx','ixy','ixz','iyy','iyz','izz'};
        case 'visual', fields = {'name','origin','geometry','material'};
        case 'collision', fields = {'name','origin','geometry'};
        case 'geometry', fields = {'box','sphere','cylinder','mesh'};
        case 'box', fields = {'size'};
        case 'sphere', fields = {'radius'};
        case 'cylinder', fields = {'radius','length'};
        case 'mesh', fields = {'filename','scale'};
        case 'material', fields = {'name','color','texture'};
        case 'color', fields = {'rgba'};
        case 'texture', fields = {'filename'};
        case 'limit', fields = {'lower','upper','effort','velocity'};
        case 'dynamics', fields = {'damping','friction'};
        case 'mimic', fields = {'joint','multiplier','offset'};
        case 'safety_controller', fields = {'soft_lower_limit','soft_upper_limit','k_position','k_velocity'};
        case 'calibration', fields = {'rising','falling'};
        otherwise
            error('rpm:load_urdf:UnsupportedElement', 'Unsupported element <%s>.', tag);
    end
    value = cell2struct(repmat({[]}, size(fields)), fields, 2);
    for key = {'name','type','filename'}
        if isfield(value, key{1}), value.(key{1}) = ""; end
    end
    if strcmp(tag, 'mimic'), value.joint = ""; end
end

function value = parse_number(raw, tag, key)
    tokens = split(strtrim(raw));
    value = str2double(tokens);
    count = 1;
    if any(strcmp(key, {'xyz','rpy','size','scale'})), count = 3; end
    if strcmp(key, 'rgba'), count = 4; end
    if numel(value) ~= count || any(~isfinite(value)) || ~isreal(value)
        error('rpm:load_urdf:InvalidAttribute', ...
            '<%s> attribute %s must contain %d finite real number(s): %s', ...
            tag, key, count, raw);
    end
    value = value(:);
end

function array = append_struct(array, value)
    if isempty(array), array = value; else, array(end+1,1) = value; end
end

