classdef robotTree < handle
    %ROBOTTREE Build a connected link/joint tree from load_urdf output.
    %   tree = rpm.chain.robotTree(rpm.utils.load_urdf(file)) creates each node
    %   once and connects it using the URDF parent/child link names.
    %   Only baseLink is retained. Access descendants through childJoint /
    %   childLink, or search from the root with getLink / getJoint (BFS).
    %   Joint parameters (including mimic) are preserved without evaluating
    %   motion constraints. Construction builds topology; show_frames displays
    %   zero-displacement poses without updating the node state.
    properties (SetAccess = ?rpm.humanoid_robot)
        baseLink
    end

    methods
        function obj = robotTree(urdf)
            obj.validateInput(urdf);
            [parents, children] = obj.validateTopology(urdf);
            % Local construction containers are released on return.
            links = cell(numel(urdf.links), 1);
            joints = cell(numel(urdf.joints), 1);
            for k = 1:numel(links)
                links{k} = rpm.chain.linkNode(urdf.links(k));
            end
            for k = 1:numel(joints)
                joints{k} = rpm.chain.jointNode(urdf.joints(k));
            end
            for k = 1:numel(joints)
                joint = joints{k};
                parent = links{parents(k)};
                child = links{children(k)};
                joint.connect(parent, child);
                parent.addChildJoint(joint);
                child.setParentJoint(joint);
            end
            obj.baseLink = links{urdf.rootLinkIndex};
        end

        function node = getLink(obj, name)
            % Search links only, including the root.
            name = obj.nameKey(name);
            node = obj.search(name, true);
            if isempty(node)
                error('rpm:robotTree:UnknownLink', 'Unknown link: %s.', name);
            end
        end

        function joint = getJoint(obj, name)
            % Search joints only, independently of link names.
            name = obj.nameKey(name);
            joint = obj.search(name, false);
            if isempty(joint)
                error('rpm:robotTree:UnknownJoint', 'Unknown joint: %s.', name);
            end
        end

        function [fig, view] = show_tree(obj, visible)
            %SHOW_TREE Display the link/joint hierarchy using base MATLAB UI.
            %   obj.show_tree() opens an expanded, resizable tree window.
            %   [fig, view] = obj.show_tree() returns the UI handles.
            %   obj.show_tree("off") creates a hidden window for scripting.
            %   Each UI node's NodeData references the original robot node.
            arguments
                obj (1,1) rpm.chain.robotTree
                visible (1,1) string {mustBeMember(visible, ["on", "off"])} = "on"
            end
            fig = uifigure('Name', "Robot tree: " + obj.baseLink.name, ...
                'Position', [100, 100, 460, 620], 'Visible', 'off');
            layout = uigridlayout(fig, [1, 1]);
            view = uitree(layout);
            obj.addTreeNodes(view, obj.baseLink);
            expand(view, 'all');
            fig.Visible = visible;
        end

        function fig = show_frames(obj, startLink, fig)
            %SHOW_FRAMES Plot stored link and joint world_T coordinate frames.
            %   Call kinematic_update before displaying the tree.
            %   obj.show_frames() starts at baseLink.
            %   obj.show_frames(startLink, fig) plots a subtree; startLink is
            %   a link name or a linkNode in this tree. Pass [] for defaults.
            %   Reads world_T only; no poses are computed or modified.
            %   Existing plots/hold are preserved. Empty poses are errors.
            if nargin < 2 || isempty(startLink)
                startLink = obj.baseLink;
            elseif ischar(startLink) || isstring(startLink)
                startLink = obj.getLink(startLink);
            end
            if ~isa(startLink, 'rpm.chain.linkNode') || ~isscalar(startLink) || ...
                    obj.getLink(startLink.name) ~= startLink
                error('rpm:robotTree:InvalidLink', 'startLink must be a link in this tree.');
            end
            if nargin < 3, fig = []; end
            if ~isempty(fig) && (~isscalar(fig) || ~isgraphics(fig, 'figure'))
                error('rpm:robotTree:InvalidFigure', 'fig must be a valid scalar figure handle.');
            end
            % Temporary BFS queue avoids the recursion limit on long chains.
            queue = startLink;
            head = 1;
            tail = 1;
            while head <= tail
                link = queue(head);
                for k = 1:numel(link.childJoint)
                    joint = link.childJoint(k);
                    tail = tail + 1;
                    queue(tail, 1) = joint.childLink;
                end
                head = head + 1;
            end
            nodes = cell(2*tail-1, 1);
            nodes{1} = startLink;
            for k = 2:tail
                nodes{2*k-2} = queue(k).parentJoint;
                nodes{2*k-1} = queue(k);
            end
            poses = cell(numel(nodes), 1);
            for k = 1:numel(nodes)
                node = nodes{k};
                if isempty(node.world_T)
                    error('rpm:robotTree:UninitializedPose', ...
                        '%s %s has empty world_T. Run kinematic_update first.', ...
                        class(node), char(node.name));
                end
                validateattributes(node.world_T, {'numeric'}, ...
                    {'real', 'finite', 'size', [4, 4]}, mfilename, ...
                    char(node.name + ".world_T"));
                poses{k} = node.world_T;
            end
            transforms = cat(3, poses{:});
            % Read all poses before changing a user's figure.
            if isempty(fig), fig = figure(); end
            ax = get(fig, 'CurrentAxes');
            if isempty(ax), ax = axes('Parent', fig); end
            positions = reshape(transforms(1:3,4,:), 3, []);
            obj.draw_frames(ax, positions, transforms(1:3,1:3,:), 0.02);
        end
    end

    methods (Access = private)
        function addTreeNodes(obj, parent, link)
            % Traverse child references only; parent references lead upward.
            linkView = uitreenode(parent, ...
                'Text', link.name + " [link]", 'NodeData', link);
            for k = 1:numel(link.childJoint)
                joint = link.childJoint(k);
                jointView = uitreenode(linkView, ...
                    'Text', joint.name + " [joint: " + joint.type + "]", ...
                    'NodeData', joint);
                obj.addTreeNodes(jointView, joint.childLink);
            end
        end

        function result = search(obj, name, linksOnly)
            % A temporary FIFO follows child edges only; no persistent index.
            result = [];
            queue = obj.baseLink;
            head = 1;
            tail = 1;
            while head <= tail
                link = queue(head);
                if linksOnly && strcmp(link.description.name, name)
                    result = link;
                    return;
                end
                for k = 1:numel(link.childJoint)
                    joint = link.childJoint(k);
                    if ~linksOnly && strcmp(joint.description.name, name)
                        result = joint;
                        return;
                    end
                    tail = tail + 1;
                    queue(tail, 1) = joint.childLink;
                end
                head = head + 1;
            end
        end
    end

    methods (Static, Access = private)
        function transform = origin_to_transform(origin)
            xyz = zeros(3,1);
            rpy = zeros(3,1);
            if ~isempty(origin)
                if isfield(origin, 'xyz') && ~isempty(origin.xyz), xyz = origin.xyz; end
                if isfield(origin, 'rpy') && ~isempty(origin.rpy), rpy = origin.rpy; end
            end
            validateattributes(xyz, {'numeric'}, ...
                {'real', 'finite', 'vector', 'numel', 3}, mfilename, 'origin.xyz');
            transform = [rpm.utils.rpy2rot(rpy), double(xyz(:)); 0,0,0,1];
        end

        function validate_rotation(rotation)
            if norm(rotation.' * rotation - eye(3), 'fro') > 1e-6 || ...
                    abs(det(rotation)-1) > 1e-6
                error('rpm:robotTree:InvalidRotationMatrix', ...
                    'T0 must contain an orthogonal rotation with determinant +1.');
            end
        end

        function draw_frames(ax, positions, rotations, scale)
            wasHeld = ishold(ax);
            cleanup = onCleanup(@() rpm.chain.robotTree.restore_frame_hold(ax, wasHeld));
            hold(ax, 'on');
            colors = eye(3);
            for k = 1:3
                directions = scale * reshape(rotations(:,k,:), 3, []);
                quiver3(ax, positions(1,:), positions(2,:), positions(3,:), ...
                    directions(1,:), directions(2,:), directions(3,:), 0, ...
                    'Color', colors(k,:), 'LineWidth', 1.5, 'MaxHeadSize', 0.2, ...
                    'Tag', 'rpm.chain.robotTree.frame');
            end
            axis(ax, 'equal'); grid(ax, 'on'); view(ax, 3);
        end

        function restore_frame_hold(ax, wasHeld)
            if isgraphics(ax) && ~wasHeld, hold(ax, 'off'); end
        end

        function [parents, children] = validateTopology(urdf)
            count = numel(urdf.links);
            indices = containers.Map('KeyType', 'char', 'ValueType', 'double');
            for k = 1:count
                key = rpm.chain.robotTree.nameKey(urdf.links(k).name);
                if isKey(indices, key)
                    error('rpm:robotTree:InvalidTopology', 'Duplicate link name: %s.', key);
                end
                indices(key) = k;
            end
            jointNames = strings(numel(urdf.joints), 1);
            for k = 1:numel(jointNames)
                jointNames(k) = rpm.chain.robotTree.nameKey(urdf.joints(k).name);
            end
            if numel(unique(jointNames)) ~= numel(jointNames)
                error('rpm:robotTree:InvalidTopology', 'Joint names must be unique.');
            end
            parents = zeros(numel(urdf.joints), 1);
            children = zeros(numel(urdf.joints), 1);
            incoming = zeros(count, 1);
            adjacency = cell(count, 1);
            for k = 1:numel(urdf.joints)
                joint = urdf.joints(k);
                parentKey = rpm.chain.robotTree.nameKey(joint.parent);
                childKey = rpm.chain.robotTree.nameKey(joint.child);
                if ~isKey(indices, parentKey) || ~isKey(indices, childKey)
                    error('rpm:robotTree:InvalidTopology', ...
                        'Joint %s references an unknown link.', joint.name);
                end
                parent = indices(parentKey);
                child = indices(childKey);
                if parent == child || incoming(child) ~= 0
                    error('rpm:robotTree:InvalidTopology', ...
                        'Joint %s forms a self-connection or gives a link multiple parents.', ...
                        joint.name);
                end
                parents(k) = parent;
                children(k) = child;
                incoming(child) = parent;
                adjacency{parent}(end+1) = child;
            end
            roots = find(incoming == 0);
            if numel(roots) ~= 1 || roots ~= urdf.rootLinkIndex
                error('rpm:robotTree:InvalidTopology', ...
                    'Connections must have one root matching rootLinkIndex.');
            end
            order = zeros(count, 1);
            order(1) = roots;
            head = 1;
            tail = 1;
            while head <= tail
                next = adjacency{order(head)};
                order(tail+1:tail+numel(next)) = next;
                tail = tail + numel(next);
                head = head + 1;
            end
            if tail ~= count
                error('rpm:robotTree:InvalidTopology', ...
                    'Links must form one connected tree without cycles.');
            end
        end

        function validateInput(urdf)
            if ~isstruct(urdf) || ~isscalar(urdf) || ...
                    ~all(isfield(urdf, {'links', 'joints', 'rootLinkIndex'}))
                error('rpm:robotTree:InvalidInput', 'Expected a load_urdf output struct.');
            end
            if ~isstruct(urdf.links) || isempty(urdf.links) || ~isfield(urdf.links, 'name')
                error('rpm:robotTree:InvalidInput', 'links must be a nonempty struct array with names.');
            end
            if ~isempty(urdf.joints) && (~isstruct(urdf.joints) || ...
                    ~all(isfield(urdf.joints, {'name', 'type', 'parent', 'child'})))
                error('rpm:robotTree:InvalidInput', 'joints must have name, type, parent and child fields.');
            end
            root = urdf.rootLinkIndex;
            if ~isnumeric(root) || ~isreal(root) || ~isscalar(root) || ...
                    ~isfinite(root) || root ~= fix(root) || root < 1 || root > numel(urdf.links)
                error('rpm:robotTree:InvalidInput', 'rootLinkIndex must be a valid link index.');
            end
        end

        function key = nameKey(name)
            if ~((isstring(name) && isscalar(name)) || (ischar(name) && isrow(name)))
                error('rpm:robotTree:InvalidName', 'Names must be string scalars or character rows.');
            end
            name = string(name);
            if ismissing(name) || strlength(strtrim(name)) == 0
                error('rpm:robotTree:InvalidName', 'Names must be nonempty.');
            end
            key = char(name);
        end
    end
end
