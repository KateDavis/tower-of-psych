classdef topsBlockTreeGUI < topsGUI
    properties
        topLevelBlockTree;
        currentBlockTree;
    end
    
    properties(Hidden)
        blocksGrid;
        blockDetailGrid;
        blockRunButton;
        blockTreeCount;
    end
    
    methods
        function self = topsBlockTreeGUI(topLevelTree)
            self = self@topsGUI;
            self.title = 'Block Tree Viewer';
            self.createWidgets;
            
            if nargin
                self.topLevelBlockTree = topLevelTree;
                self.repopulateBlocksGrid;
                self.displayDetailsForBlock(topLevelTree);
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
                self.figure, [left, bottom, xDiv-left, top-bottom]);
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
        
        function displayDetailsForBlock(self, block)
            self.currentBlockTree = block;
            
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
            
            props = {'blockBeginFcn', 'blockActionFcn', 'blockEndFcn'};
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
            h = self.blocksGrid.newControlAtRowAndColumn( ...
                row, [0 1]+depth, ...
                'Style', 'pushbutton', ...
                'String', block.name, ...
                'Callback', @(obj, event) self.displayDetailsForBlock(block), ...
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
            
            self.listeners(n).BlockBegin = block.addlistener( ...
                'BlockBegin', ...
                @(source, event)self.hearBlockBegin(source, event));
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
        
        function hearBlockBegin(self, block, event)
            self.displayDetailsForBlock(block);
        end
        
        function repondToResize(self, figure, event)
            % attempt to resize with characters, rather than normalized
            self.blocksGrid.repositionControls;
            self.blockDetailGrid.repositionControls;
        end
    end
end