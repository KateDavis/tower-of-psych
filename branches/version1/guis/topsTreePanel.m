classdef topsTreePanel < topsPanel
    % Show an collection of items with a tree browser.
    % @details
    % topsTreePanel shows tree that can browse items connected to baseItem.
    % The user can select individual nodes of the tree to set the
    % currentItem for a Tower of Psych GUI.
    %
    % @ingroup guis
    
    properties (SetAccess = protected)
        % the uitree for displaying items connected to baseItem
        tree;
        
        % the graphical container of the tree
        treeContainer;
    end
    
    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsTreePanel.  @a parentFigure must be a
        % topsFigure object, otherwise the panel won't display any content.
        % @details
        function self = topsTreePanel(varargin)
            self = self@topsPanel(varargin{:});
            self.isLocked = true;
        end
        
        % Set the GUI current item from a selected node.
        % @param tree uitree object or a "peer" object
        % @param event event object related to the selection
        % @details
        % Sets the value of the current item for the parent figure, based
        % on the selected node.
        function selectItem(self, tree, event)
            % the current node's value contains a sub-path path 
            %   from baseItem to the expanding node
            node = event.getCurrentNode();
            subPath = node.getValue();
            item = self.subItemFromPath(subPath);
            name = sprintf('%s%s', self.baseItemName, subPath);
            self.parentFigure.setCurrentItem(item, name);
        end
        
        % Create new child nodes for an expanded node.
        % @param tree uitree object or a "peer" object
        % @param value value associated with the expanding node
        % @details
        % Must create new uitreenode objects for a node that is currently
        % expanding, based on the value of baseItem, and the sub-path
        % contained by the expanding node.
        function nodes = childNodesForExpand(self, tree, value)
            nodes = [];
        end
    end
    
    methods (Access = protected)
        % Create and arrange fresh components.
        function initialize(self)
            self.initialize@topsPanel();
            
            % a placeholder root node for uitree creation to succeed
            rootNode = uitreenode('v0', '', 'root', [], true);
            
            % the new tree gets wired up to call panel methods
            [self.tree, self.treeContainer] =...
                self.parentFigure.makeUITree( ...
                self.pan, ...
                rootNode, ...
                @(tree, event)self.childNodesForExpand(tree, event), ...
                @(tree, event)self.selectItem(tree, event));
            
            % update the tree to use baseItem
            self.updateContents();
        end
        
        % Refresh the panel's contents.
        function updateContents(self)
            % represent baseItem at the uitree root
            rootNode = self.nodeForItem(self.baseItem, ...
                self.baseItemName, '');
            self.tree.setRoot(rootNode);
            
            % show the first child nodes right away
            self.tree.expand(rootNode);
        end
        
        % Make a new tree node to represent the given item.
        % @param item any item
        % @param name string name for the item
        % @param subPath string drill down path from a parent node
        % @details
        % Makes a new uitreenode to represent the given @a item.  @a
        % subPath must be a string to pass to eval, which drills down
        % from a parent item to this item.  For example, if the item is
        % located in a struct field names 'data', subPath should be
        % '.data'.
        function node = nodeForItem(self, item, name, subPath)
            % display a summary of the item
            name = topsGUIUtilities.makeTitleForItem(item, name, ...
                self.parentFigure.midgroundColor);
            name = sprintf('<HTML>%s</HTML>', name);
            node = uitreenode('v0', subPath, name, [], false);
        end
    end
end