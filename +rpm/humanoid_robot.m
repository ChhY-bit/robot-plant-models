classdef humanoid_robot < handle
    properties(Access=public)
        Metadata
    end
    properties(SetAccess = private)
        Tree
    end

    methods
        function obj = humanoid_robot(urdf)
            obj.Tree = rpm.chain.robotTree(urdf);
        end

        function kinematic_update(obj)
            obj.Tree.baseLink.world_T = eye(4);
            obj.kinematic_recurse(obj.Tree.baseLink)
        end
    end

    methods(Access=private)
        function kinematic_recurse(obj,link_node)
        % 前向更新所有位姿
            parent = link_node.parentJoint;
            if ~isempty(parent) % 有父joint
                T = eye(4);
                switch parent.description.type
                    case "fixed"
                    case {"revolute","continuous"}
                        T(1:3,1:3) = rpm.utils.axis2rot(parent.description.axis,parent.q);
                    case "prismatic" 
                        T(1:3,4) = parent.description.axis * parent.q;
                    otherwise
                        error("不支持该关节类型：%s",parent.description.type);
                end
                link_node.world_T = parent.world_T * T;     % 基于父joint系与关节变量
            end

            joint_node = link_node.childJoint;
            if isempty(joint_node)
                return    % 到达末端，递归出口
            end
            
            joint_num = size(joint_node,1);
            for i = 1:joint_num
                rpy = joint_node(i).description.origin.rpy;
                xyz = joint_node(i).description.origin.xyz;
                T0 = eye(4);
                T0(1:3,1:3) = rpm.utils.rpy2rot(rpy);
                T0(1:3,4) = xyz;
                joint_node(i).world_T = link_node.world_T*T0;   % 基于父link系与静态urdf
                obj.kinematic_recurse(joint_node(i).childLink)
            end

        end
    end
end
