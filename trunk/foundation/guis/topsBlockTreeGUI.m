classdef topsBlockTreeGUI < topsGUI
    % @class topsBlockTreeGUI
    % Visualize the tree structure of an experiment.
    % topsBlockTreeGUI shows you hiererchy of topsBlockTree "blocks" that
    % make up an experiment.
    % <br><br>
    % On the left it shows you a tree browser with several buttons that
    % represent individual blocks.  The topmost block is at the upper left
    % corner.  Its children are indented and displayed below.  Their
    % children are indented further, and so on.
    % <br><br>
    % You can click on an individual block to view it in detail, on the
    % right.  The name of the block is at the top and its proerties are
    % displayed below.  In particular, the blocks start, action, and end
    % functions are expanded to show each function handle and arguments.
    % <br><br>
    % At the top right, the "run block" button allows you to invoke the
    % run() method of the currently displayed block.  You should probably
    % only run the topmost block in this way.
    % <br><br>
    % You can launch topsBlockTreeGUI with the topsBlockTreeGUI()
    % constructor, or with the gui() method a topsBlockTreeGUI.
    % <br><br>
    % topsBlockTreeGUI uses listeners to detect changes to the blocks it's
    % showing.  This means that you can view your blocks as you work on
    % your experiment, and you don't have to reopen or refresh the GUI.
    % <br><br>
    % But beware that listeners can slow Matlab down.  So if you're in a
    % timing-critical situation, like running a real experiment, you might
    % wish to close the GUI, deleting its listeners.
    % @ingroup foundation
    
    properties
        % The highest-up block to visualize in the GUI.
        topLevelBlockTree;
        
        % The block whose details are currently displayed.
        currentBlockTree;
    end
    
    properties(Hidden)
        blocksGrid;
        blockDetailGrid;
        blockRunButton;
        blockTreeCount;
    end
    
    methods
        % Constructor takes one optional argument
        % @param topLevelBlock a block to visualize, with all its children
        % @details
        % Returns a handle to the new topsBlockTreeGUI.  If
        % @a topLevelBlock is missing, the GUI will launch but no
        % data will be shown.
        function self = topsBlockTreeGUI(topLevelBlock)
            self = self@topsGUI;
            self.title = 'Block Tree Viewer';
            self.createWidgets;
            
            if nargin
                self.topLevelBlockTree = topLevelBlock;
                self.repopulateBlocksGrid;
                self.displayDetailsForBlock(topLevelBlock);
            end
        end
        
        function createWidgets(self)
            left = 0;
            right = 1;
            bottom = 0;
            top = 1;
            xDiv = (1/3);
            xGap = .05;
            yDiv = .95;
            
            % custom widget class, in tops/utilities
            self.blocksGrid = ScrollingControlGrid( ...
                self.figure, [left, bottom, xDiv-left, yDiv-bottom]);
            self.addScrollableChild(self.blocksGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, self.blocksGrid});
            
            self.blockDetailGrid = ScrollingControlGrid( ...
                self.figure, [xDiv+xGap, bottom, right-xDiv-xGap, yDiv-bottom]);
            self.addScrollableChild(self.blockDetailGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, self.blockDetailGrid});
            self.blockDetailGrid.rowHeight = 1.2;
            
            w = .2;
            self.blockRunButton = uicontrol( ...
                'Parent', self.figure, ...
                'BackgroundColor', self.lightColor, ...
                'Callback', @(obj, event)self.runCurrentBlock, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'run block', ...
                'Position', [right-w, yDiv, w, top-yDiv], ...
                'HorizontalAlignment', 'left');
        end
        
        function displayDetailsForBlock(self, block, button)
            self.currentBlockTree = block;
            
            if nargin > 2
                obj = self.blocksGrid.controls;
                topsText.toggleOff(obj(ishandle(obj) & obj > 0));
                topsText.toggleOn(button);
            end
            
            self.blockDetailGrid.deleteAllControls;
            
            width = 20;
            row = 1;
            args = self.getDescriptiveUIControlArgsForValue(block.name);
            self.blockDetailGrid.newControlAtRowAndColumn( ...
                1, [1 width], args{:});
            
            row = row+2;
            args = self.getDescriptiveUIControlArgsForValue('iterations:');
            self.blockDetailGrid.newControlAtRowAndColumn( ...
                row, [1 4], args{:});
            
            
            args = self.getDescriptiveUIControlArgsForValue(block.iterations);
            self.blockDetailGrid.newControlAtRowAndColumn( ...
                row, [5 6], args{:}, 'HorizontalAlignment', 'center');
            
            args = self.getDescriptiveUIControlArgsForValue(block.iterationMethod);
            self.blockDetailGrid.newControlAtRowAndColumn( ...
                row, [7 width], args{:});
            
            props = {'blockStartFcn', 'blockActionFcn', 'blockEndFcn'};
            prefixes = {block.startString, block.actionString, block.endString};
            for ii = 1:length(props)
                % label the property
                row = row+2;
                label =  sprintf('%s:%s', block.name, prefixes{ii});
                args = self.getDescriptiveUIControlArgsForValue(label);
                self.blockDetailGrid.newControlAtRowAndColumn( ...
                    row, [1 width], args{:});
                
                fcn = block.(props{ii});
                for jj = 1:length(fcn)
                    % enumerate the function contents
                    row = row+1;
                    args = self.getInteractiveUIControlArgsForValue(fcn{jj});
                    self.blockDetailGrid.newControlAtRowAndColumn( ...
                        row, [2 width], args{:});
                end
            end
            
            row = row+2;
            args = self.getDescriptiveUIControlArgsForValue('userData:');
            self.blockDetailGrid.newControlAtRowAndColumn( ...
                row, [1 4], args{:});
            
            args = self.getInteractiveUIControlArgsForValue(block.userData);
            self.blockDetailGrid.newControlAtRowAndColumn( ...
                row, [5 width], args{:});
            
            self.blockDetailGrid.repositionControls;
        end
        
        % Invoke the run() method of the currently displayed block.
        % The "run block" button calls this method.  This method then calls
        % currentBlockTree.run();
        function runCurrentBlock(self)
            self.currentBlockTree.run;
        end
        
        function repopulateBlocksGrid(self)
            % delete all listeners and controls
            self.deleteListeners;
            self.blocksGrid.deleteAllControls;
            
            self.blockTreeCount = 1;
            depth = 1;
            self.addBlockAtDepth(self.topLevelBlockTree, depth);
            self.blocksGrid.repositionControls;
        end
        
        function addBlockAtDepth(self, block, depth);
            % add this block
            row = self.blockTreeCount;
            col = self.getColorForString(block.name);
            toggle = topsText.toggleText;
            h = self.blocksGrid.newControlAtRowAndColumn( ...
                row, [0 1]+depth, ...
                toggle{:}, ...
                'String', block.name, ...
                'Callback', @(obj, event) self.displayDetailsForBlock(block, obj), ...
                'BackgroundColor', self.lightColor, ...
                'ForegroundColor', col);
            
            % listen to this block
            self.listenToBlockTree(block);
            
            % recur on children
            for ii = 1:length(block.children)
                self.blockTreeCount = self.blockTreeCount + 1;
                self.addBlockAtDepth(block.children(ii), depth+1);
            end
        end
        
        function listenToBlockTree(self, block)
            props = properties(block);
            n = self.blockTreeCount;
            for ii = 1:length(props)
                self.listeners(n).(props{ii}) = block.addlistener( ...
                    props{ii}, 'PostSet', ...
                    @(source, event)self.hearBlockPropertyChange(source, event));
            end
            
            self.listeners(n).BlockStart = block.addlistener( ...
                'BlockStart', ...
                @(source, event)self.hearBlockStart(source, event));
        end
        
        function hearBlockPropertyChange(self, metaProp, event)
            % rebuild when tree structure or name changes
            if any(strcmp(metaProp.Name, {'children', 'parent', 'name'}))
                self.repopulateBlocksGrid;
            end
            
            % redraw for currently detailed block
            if event.AffectedObject == self.currentBlockTree
                self.displayDetailsForBlock(self.currentBlockTree);
            end
        end
        
        function hearBlockStart(self, block, event)
            self.displayDetailsForBlock(block);
        end
        
        function repondToResize(self, figure, event)
            % attempt to resize with characters, rather than normalized
            self.blocksGrid.repositionControls;
            self.blockDetailGrid.repositionControls;
        end
    end
end