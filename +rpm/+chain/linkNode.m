classdef linkNode < handle
    %LINKNODE URDF link with references to its incident joints.
    % childJoint is a column jointNode array, including for zero or one child.
    % world_T is reserved for kinematics and is empty until computed.
    % Publicly readable; updates are controlled by humanoid_robot.
    properties (SetAccess = ?rpm.humanoid_robot)
        description
        parentJoint = []
        childJoint = rpm.chain.jointNode.empty(0, 1)
        world_T = []
    end

    properties (Dependent, SetAccess = private)
        name  % Read from description; no separate stored value.
    end

    methods
        function obj = linkNode(description)
            obj.description = description;
        end
        % ---------- 别名访问 ----------
        function name = get.name(obj)
            name = string(obj.description.name);
        end

        % ------------------------------
    end

    methods (Access = ?rpm.chain.robotTree)
        function setParentJoint(obj, joint)
            obj.parentJoint = joint;
        end

        function addChildJoint(obj, joint)
            obj.childJoint(end+1, 1) = joint;
        end
    end
end
