classdef jointNode < handle
    %JOINTNODE URDF joint connecting one parent link to one child link.
    % All URDF parameters are retained in description. q and dq start at zero;
    % world_T remains empty until the kinematics layer computes it.
    % Publicly readable; updates are controlled by humanoid_robot.
    % Axis-based joints store a normalized column axis in description.
    properties (SetAccess = ?rpm.humanoid_robot)
        description
        parentLink = []
        childLink = []
        world_T = []
        q = 0
        dq = 0
    end

    properties (Dependent, SetAccess = private)
        name  % Read from description; no separate stored value.
        type
    end

    methods
        function obj = jointNode(description)
            if any(strcmp(description.type, {'revolute','continuous','prismatic','planar'}))
                if ~isfield(description, 'axis') || isempty(description.axis)
                    description.axis = [1;0;0];
                end
                validateattributes(description.axis, {'numeric'}, ...
                    {'real', 'finite', 'vector', 'numel', 3}, mfilename, 'description.axis');
                axis = double(description.axis(:));
                scale = max(abs(axis));
                if scale == 0
                    error('rpm:jointNode:InvalidAxis', '关节轴必须为非零向量。');
                end
                % Scaling prevents overflow/underflow during normalization.
                axis = axis / scale;
                description.axis = axis / norm(axis);
            end
            obj.description = description;
        end
        % ---------- 别名访问 ----------
        function name = get.name(obj)
            name = string(obj.description.name);
        end

        function type = get.type(obj)
            type = string(obj.description.type);
        end
        % ------------------------------
    end

    methods (Access = ?rpm.chain.robotTree)
        function connect(obj, parent, child)
            obj.parentLink = parent;
            obj.childLink = child;
        end
    end
end
