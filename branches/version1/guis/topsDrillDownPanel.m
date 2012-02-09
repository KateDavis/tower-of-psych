classdef topsDrillDownPanel < topsPanel
    % Show an item and sub elements, fields, and properties as a tree.
    % @details
    % topsDrillDownPanel shows tree that can drill down into a given "base
    % item".  The user can view and select struct fields, object
    % properties, and cell array elements, to arbitrary depth.  Each
    % selection updates the "current item" of a Tower of Psych GUI.
    %
    % @ingroup guis
    
    properties (SetAccess = protected)
        % the item to drill down into
        baseItem;
        
        % name for the bass item
        baseItemName;
        
        % the uitree for displaying drill down sub-items
        drillDownTree;
        
        % the graphical container of the drillDownTree
        drillDownContainer;
    end
    
    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsDrillDownPanel.  @a parentFigure must be a
        % topsFigure object, otherwise the panel won't display any content.
        % @details
        function self = topsDrillDownPanel(varargin)
            self = self@topsPanel(varargin{:});
            self.isLocked = true;
        end
        
        % Choose the item to drill down into.
        % @param baseItem any item to drill down into
        % @param baseItemName string name for @a baseItem
        % @details
        % @a bassItem may be any item.  The drill down panel will
        % summarize the item with its sub-items, including fields,
        % properties, and array elements.  @a bassItemName is a name to
        % display for the bass item.
        function setBaseItem(self, baseItem, baseItemName)
            self.baseItem = baseItem;
            self.baseItemName = baseItemName;
            self.updateContents();
        end
        
        % Set the GUI current item from a selected node.
        % @param tree uitree object or a "peer" object
        % @param event event object related to the selection
        % @details
        % Sets the value of the current item for the parent figure, based
        % on the selected node.
        function currentItemForSelect(self, tree, event)
            % node value contains a drill-down path for the expanding node
            node = event.getCurrentNode();
            drillPath = node.getValue();
            item = self.itemFromDrillDownPath(drillPath);
            name = sprintf('%s%s', self.baseItemName, drillPath);
            self.parentFigure.setCurrentItem(item, name);
        end
        
        % Create new child nodes for an expanded node.
        % @param tree uitree object or a "peer" object
        % @param value value associated with the expanding node
        % @details
        % Creates new uitreenode objects for a node that is currently
        % expanding, based on the value of baseItem, the drill down path
        % for any parent nodes, and any sup-items beneath the drill down
        % path.
        function nodes = childNodesForExpand(self, tree, value)
            % value contains a drill-down path for the expanding node
            drillPath = value;
            item = self.itemFromDrillDownPath(drillPath);
            
            % drill into the sub-item based on its class and size
            if isstruct(item)
                if numel(item) > 1
                    % for a struct array, break out each element
                    nodes = self.nodesForElements(item, drillPath);
                else
                    % for a struct, break out each field
                    nodes = self.nodesForNamedFields(item, drillPath);
                end
                
            elseif isobject(item)
                if numel(item) > 1
                    % for an object array, break out each element
                    nodes = self.nodesForElements(item, drillPath);
                else
                    % for an object, break out each property
                    nodes = self.nodesForNamedFields(item, drillPath);
                end
                
            elseif iscell(item)
                % for a cell array, break out each element
                nodes = self.nodesForCellElements(item, drillPath);
                
            else
                % for a primitive, make a leaf node
                nodes = self.leafNodeForItem(item, drillPath);
            end
        end
    end
    
    methods (Access = protected)
        % Create and arrange fresh components.
        function initialize(self)
            self.initialize@topsPanel();
            
            % a placeholder root node for uitree creation to succeed
            rootNode = self.leafNodeForItem([], '');
            
            % the new tree gets wired up to call panel methods
            [self.drillDownTree, self.drillDownContainer] =...
                self.parentFigure.makeUITree( ...
                self.pan, ...
                rootNode, ...
                @(tree, event)self.childNodesForExpand(tree, event), ...
                @(tree, event)self.currentItemForSelect(tree, event));
            
            % update the tree to use baseItem
            self.updateContents();
        end
        
        % Refresh the panel's contents.
        function updateContents(self)
            % represent baseItem at the uitree root
            rootNode = self.nodeForItem(self.baseItem, ...
                self.baseItemName, '');
            self.drillDownTree.setRoot(rootNode);
            
            % show the first child nodes right away
            self.drillDownTree.expand(rootNode);
        end
        
        % Resolve a dill-down path string from baseItem.
        function item = itemFromDrillDownPath(self, drillPath)
            absolutePath = sprintf('self.baseItem%s', drillPath);
            item = eval(absolutePath);
        end
        
        % Make uitreenode nodes for a scalar struct or object.
        function nodes = nodesForNamedFields(self, item, itemPath)
            % get named sub-fields
            if isstruct(item)
                fields = fieldnames(item);
            else
                fields = properties(item);
            end
            
            % build a node for each named field
            %   and append the drill-down path
            nNodes = numel(fields);
            nodeCell = cell(1, nNodes);
            for ii = 1:nNodes
                subItem = item.(fields{ii});
                subPath = sprintf('.%s', fields{ii});
                drillPath = [itemPath subPath];
                nodeCell{ii} = self.nodeForItem( ...
                    subItem, subPath, drillPath);
            end
            nodes = [nodeCell{:}];
        end
        
        % Make uitreenode nodes for an array.
        function nodes = nodesForElements(self, item, itemPath)
            % build a node for each indexed element
            %   and append the drill-down path
            nNodes = numel(item);
            nodeCell = cell(1, nNodes);
            for ii = 1:nNodes
                subItem = item(ii);
                subPath = sprintf('(%d)', ii);
                drillPath = [itemPath subPath];
                nodeCell{ii} = self.nodeForItem( ...
                    subItem, subPath, drillPath);
            end
            nodes = [nodeCell{:}];
        end
        
        % Make uitreenode nodes for a cell array.
        function nodes = nodesForCellElements(self, item, itemPath)
            % build a node for each indexed cell element
            %   and append the drill-down path
            nNodes = numel(item);
            nodeCell = cell(1, nNodes);
            for ii = 1:nNodes
                subItem = item{ii};
                subPath = sprintf('{%d}', ii);
                drillPath = [itemPath subPath];
                nodeCell{ii} = self.nodeForItem( ...
                    subItem, subPath, drillPath);
            end
            nodes = [nodeCell{:}];
        end
        
        % Make a new tree node to represent the given item.
        % @param item any item
        % @param name string name for the item
        % @param drillPath string drill down path from a parent node
        % @details
        % Makes a new uitreenode to represent the given @a item.  @a
        % drillPath must be a string to pass to eval, which drills down
        % from a parent item to this item.  For example, if the item is
        % located in a struct field names 'data', drillPath should be
        % '.data'.
        function node = nodeForItem(self, item, name, drillPath)
            % display a summary of the item
            name = topsGUIUtilities.makeTitleForItem(item, name, ...
                self.parentFigure.midgroundColor);
            name = sprintf('<HTML>%s</HTML>', name);
            node = uitreenode('v0', drillPath, name, [], false);
        end
        
        % Make a uitreenode node for a basic item.
        function node = leafNodeForItem(self, item, drillPath)
            name = topsGUIUtilities.makeSummaryForItem( ...
                item, self.parentFigure.colors);
            name = sprintf('<HTML>%s</HTML>', name);
            node = uitreenode('v0', drillPath, name, [], true);
        end
    end
end