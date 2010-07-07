classdef topsTreeNodeGUI < topsGUI
    % @class topsTreeNodeGUI
    % Visualize the tree structure of an experiment.
    % topsTreeNodeGUI shows you hiererchy of topsTreeNode objects that
    % make up an experiment.
    % @details
    % On the left it shows you a tree browser with several buttons that
    % represent individual nodes.  The topmost node is at the upper left
    % corner.  Its children are indented and displayed below.  Their
    % children are indented further, and so on.
    % @details
    % You can click on an individual node to view it in detail, on the
    % right.  The name of the node is at the top and its proerties are
    % displayed below.  In particular, the node's start, and finish
    % fevalables are expanded to show each function handle and its
    % arguments.
    % @details
    % At the top right, the "run" button allows you to invoke the
    % run() method of the currently displayed node.  You should probably
    % only run the topmost node in this way.
    % @details
    % You can launch topsTreeNodeGUI with the topsTreeNodeGUI()
    % constructor, or with the gui() method a topsTreeNodeGUI.
    % @details
    % topsTreeNodeGUI uses listeners to detect changes to the nodes it's
    % showing.  This means that you can view your nodes as you work on
    % your experiment, and you don't have to reopen or refresh the GUI.
    % @details
    % But beware that listeners can slow Matlab down.  So if you're in a
    % timing-critical situation, like running a real experiment, you might
    % wish to close the GUI, deleting its listeners.
    % @ingroup foundation
    
    properties
        % The highest-up node to visualize in the GUI.
        topLevelNode;
        
        % The node whose details are currently displayed.
        currentNode;
    end
    
    properties(Hidden)
        nodesGrid;
        nodeDetailGrid;
        nodeRunButton;
        nodeCount;
        structuralProps = {'parent', 'children', 'name'};
    end
    
    methods
        % Constructor takes one optional argument
        % @param topLevelNode a tree node to visualize, with all its
        % children
        % @details
        % Returns a handle to the new topsTreeNodeGUI.  If
        % @a topLevelNode is missing, the GUI will launch but no
        % data will be shown.
        function self = topsTreeNodeGUI(topLevelNode)
            self = self@topsGUI;
            self.title = 'Tops Tree Viewer';
            self.createWidgets;
            
            if nargin
                self.topLevelNode = topLevelNode;
                self.repopulateNodesGrid;
                self.displayDetailsForNode(topLevelNode);
            end
        end
        
        function createWidgets(self)
            left = 0;
            right = 1;
            bottom = 0;
            top = 1;
            xDiv = .4;
            xGap = .05;
            yDiv = .95;
            
            % custom widget class, in tops/utilities
            self.nodesGrid = ScrollingControlGrid( ...
                self.figure, [left, bottom, xDiv-left, yDiv-bottom]);
            self.addScrollableChild(self.nodesGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, self.nodesGrid});
            
            self.nodeDetailGrid = ScrollingControlGrid( ...
                self.figure, [xDiv+xGap, bottom, right-xDiv-xGap, yDiv-bottom]);
            self.addScrollableChild(self.nodeDetailGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, self.nodeDetailGrid});
            self.nodeDetailGrid.rowHeight = 1.2;
            
            w = .2;
            self.nodeRunButton = uicontrol( ...
                'Parent', self.figure, ...
                'BackgroundColor', self.lightColor, ...
                'Callback', @(obj, event)self.runCurrentNode, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'run', ...
                'Position', [right-w, yDiv, w, top-yDiv], ...
                'HorizontalAlignment', 'left');
        end
        
        function displayDetailsForNode(self, node, button)
            self.currentNode = node;
            
            if nargin > 2
                obj = self.nodesGrid.controls;
                topsText.toggleOff(obj(ishandle(obj) & obj > 0));
                topsText.toggleOn(button);
            end
            
            self.nodeDetailGrid.deleteAllControls;
            
            width = 20;
            row = 1;
            args = self.getDescriptiveUIControlArgsForValue(node.name);
            self.nodeDetailGrid.newControlAtRowAndColumn( ...
                1, [1 width], args{:});
            
            row = row+2;
            args = self.getDescriptiveUIControlArgsForValue('iterations:');
            self.nodeDetailGrid.newControlAtRowAndColumn( ...
                row, [1 4], args{:});
            
            args = self.getDescriptiveUIControlArgsForValue(node.iterations);
            self.nodeDetailGrid.newControlAtRowAndColumn( ...
                row, [5 6], args{:}, 'HorizontalAlignment', 'center');
            
            args = self.getDescriptiveUIControlArgsForValue(node.iterationMethod);
            self.nodeDetailGrid.newControlAtRowAndColumn( ...
                row, [7 width], args{:});
            
            props = {'startFevalable', 'finishFevalable'};
            prefixes = {node.startString, node.finishString};
            for ii = 1:length(props)
                % label the property
                row = row+2;
                label =  sprintf('%s:%s', node.name, prefixes{ii});
                args = self.getDescriptiveUIControlArgsForValue(label);
                self.nodeDetailGrid.newControlAtRowAndColumn( ...
                    row, [1 width], args{:});
                
                fcn = node.(props{ii});
                for jj = 1:length(fcn)
                    % enumerate the function contents
                    row = row+1;
                    args = self.getInteractiveUIControlArgsForValue(fcn{jj});
                    self.nodeDetailGrid.newControlAtRowAndColumn( ...
                        row, [2 width], args{:});
                end
            end
            
            self.nodeDetailGrid.repositionControls;
        end
        
        % Invoke the run() method of the currently displayed node.
        function runCurrentNode(self)
            self.currentNode.run;
        end
        
        function repopulateNodesGrid(self)
            % delete all listeners and controls
            self.deleteListeners;
            self.nodesGrid.deleteAllControls;
            
            self.nodeCount = 1;
            depth = 1;
            self.addNodeAtDepth(self.topLevelNode, depth);
            self.nodesGrid.repositionControls;
        end
        
        function addNodeAtDepth(self, node, depth)
            row = self.nodeCount;
            col = self.getColorForString(node.name);
            
            if isa(node, 'topsTreeNode')
                % add this node
                toggle = topsText.toggleText;
                self.nodesGrid.newControlAtRowAndColumn( ...
                    row, [0 1]+depth, ...
                    toggle{:}, ...
                    'String', node.name, ...
                    'Callback', @(obj, event) self.displayDetailsForNode(node, obj), ...
                    'BackgroundColor', self.lightColor, ...
                    'ForegroundColor', col);
                
                % listen to this node
                self.listenToNode(node);
                
                % recur on children
                children = node.children.allItems;
                for ii = 1:length(children)
                    self.nodeCount = self.nodeCount + 1;
                    self.addNodeAtDepth(children{ii}, depth+1);
                end
                
            else
                static = topsText.staticText;
                self.nodesGrid.newControlAtRowAndColumn( ...
                    row, [0 1]+depth, ...
                    static{:}, ...
                    'String', node.name, ...
                    'BackgroundColor', self.lightColor, ...
                    'ForegroundColor', col);
            end
        end
        
        function listenToNode(self, node)
            props = self.structuralProps;
            for ii = 1:length(props)
                listener = node.addlistener(props{ii}, 'PostSet', ...
                    @(source, event)self.hearNodePropertyChange(source, event));
                self.addListenerWithName(listener, props{ii});
            end
            
            listener = node.addlistener('RunStart', ...
                @(source, event)self.hearRunStart(source, event));
            self.addListenerWithName(listener, 'RunStart');
        end
        
        function hearNodePropertyChange(self, metaProp, event)
            self.repopulateNodesGrid;
            
            % redraw for currently detailed node
            if event.AffectedObject == self.currentNode
                self.displayDetailsForNode(self.currentNode);
            end
        end
        
        function hearRunStart(self, node, event)
            self.displayDetailsForNode(node);
        end
        
        function repondToResize(self, figure, event)
            % attempt to resize with characters, rather than normalized
            self.nodesGrid.repositionControls;
            self.nodeDetailGrid.repositionControls;
        end
    end
end