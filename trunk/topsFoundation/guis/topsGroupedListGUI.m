classdef topsGroupedListGUI < topsGUI
    properties
        groupedList;
        currentGroup;
        currentMnemonic;
    end
    
    properties(Hidden)
        groupLabel;
        groupsGrid;
        
        mnemonicLabel;
        mnemonicsGrid;
        
        itemLabel;
        itemToWorkspaceButton;
        itemDetailGrid;
    end
    
    methods
        function self = topsGroupedListGUI(groupedList)
            self = self@topsGUI;
            self.title = 'Grouped List Viewer';
            self.createWidgets;
            
            if nargin
                self.groupedList = groupedList;
                self.listenToGroupedList(groupedList);
                self.repopulateGroupsGrid;
            end
        end
        
        function createWidgets(self)
            left = 0;
            right = 1;
            bottom = 0;
            top = 1;
            yDiv = .95;
            width = (1/3);
            
            self.groupLabel = uicontrol( ...
                'Parent', self.figure, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', 'group:', ...
                'Position', [left, yDiv, width, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            % custom widget class, in tops/utilities
            self.groupsGrid = ScrollingControlGrid( ...
                self.figure, [left, bottom, width, yDiv-bottom]);
            self.addScrollableChild(self.groupsGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, self.groupsGrid});
            
            self.mnemonicLabel = uicontrol( ...
                'Parent', self.figure, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', 'mnemonic:', ...
                'Position', [width, yDiv, width, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            self.mnemonicsGrid = ScrollingControlGrid( ...
                self.figure, [width, bottom, width, yDiv-bottom]);
            self.addScrollableChild(self.mnemonicsGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, self.mnemonicsGrid});
            
            self.itemLabel = uicontrol( ...
                'Parent', self.figure, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', 'item:', ...
                'Position', [right-width, yDiv, width/2, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            self.itemToWorkspaceButton = uicontrol( ...
                'Parent', self.figure, ...
                'Callback', @(obj, event)self.currentItemToBaseWorkspace, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'to workspace', ...
                'Position', [right-width/2, yDiv, width/2, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            self.itemDetailGrid = ScrollingControlGrid( ...
                self.figure, [right-width, bottom, width, yDiv-bottom]);
            self.addScrollableChild(self.itemDetailGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, self.itemDetailGrid});
            self.itemDetailGrid.rowHeight = 1.2;
        end
        
        function setCurrentGroup(self, group, button)
            self.currentGroup = group;
            self.repopulateMnemonicsGrid;
            if nargin > 2
                set(self.groupsGrid.controls, 'Value', false);
                set(button, 'Value', true);
                drawnow;
            end
        end
        
        function setCurrentMnemonic(self, mnemonic, button)
            self.currentMnemonic = mnemonic;
            self.showDetailsForCurrentItem;
            if nargin > 2
                set(self.mnemonicsGrid.controls, 'Value', false);
                set(button, 'Value', true);
                drawnow;
            end
        end
        
        function repopulateGroupsGrid(self)
            groups = self.groupedList.groups;
            self.groupsGrid.deleteAllControls;
            for ii = 1:length(groups)
                cb = @(obj, event)self.setCurrentGroup(groups{ii}, obj);
                self.addBrowserButtonToGridRowWithNameAndCallback( ...
                    self.groupsGrid, ii, groups{ii}, cb);
            end
            self.groupsGrid.repositionControls;
            if ~isempty(groups)
                button = self.groupsGrid.controls(1,1);
                self.setCurrentGroup(groups{1}, button);
            end
        end
        
        function repopulateMnemonicsGrid(self)
            mnemonics = self.groupedList.getAllMnemonicsFromGroup(self.currentGroup);
            self.mnemonicsGrid.deleteAllControls;
            for ii = 1:length(mnemonics)
                cb = @(obj, event)self.setCurrentMnemonic(mnemonics{ii}, obj);
                self.addBrowserButtonToGridRowWithNameAndCallback( ...
                    self.mnemonicsGrid, ii, mnemonics{ii}, cb);
            end
            self.mnemonicsGrid.repositionControls;
            if ~isempty(mnemonics)
                button = self.mnemonicsGrid.controls(1,1);
                self.setCurrentMnemonic(mnemonics{1}, button);
            end
        end
        
        function addBrowserButtonToGridRowWithNameAndCallback(self, grid, row, name, callback)
            if ischar(name)
                string = name;
                col = self.getColorForString(string);
            else
                string = num2str(name);
                col = [0 0 0];
            end
            grid.newControlAtRowAndColumn( ...
                row, 1, ...
                'Style', 'toggle', ...
                'String', string, ...
                'Callback', callback, ...
                'ForegroundColor', col);
        end
        
        function showDetailsForCurrentItem(self)
            item = self.groupedList.getItemFromGroupWithMnemonic( ...
                self.currentGroup, self.currentMnemonic);
            
            self.itemDetailGrid.deleteAllControls;
            width = 10;
            
            % shallow look at any item
            args = self.getInteractiveUIControlArgsForValue(item);
            self.itemDetailGrid.newControlAtRowAndColumn(1, [1 width], args{:});
            
            % deeper look at deep items
            if isstruct(item) || isobject(item)
                if isstruct(item)
                    fn = fieldnames(item);
                else
                    fn = properties(item);
                end
                
                row = 1;
                n = numel(item);
                bg = get(self.figure, 'Color');
                for ii = 1:n
                    % delimiter for each array element
                    row = row+1;
                    delimiter = sprintf('(%d of %d)', ii, n);
                    args = self.getInteractiveUIControlArgsForValue(item(ii));
                    self.itemDetailGrid.newControlAtRowAndColumn( ...
                        row, [1 4], args{:}, 'String', delimiter);
                    
                    for jj = 1:length(fn)
                        % field name and value
                        row = row+1;
                        args = self.getDescriptiveUIControlArgsForValue(fn{jj});
                        self.itemDetailGrid.newControlAtRowAndColumn( ...
                            row, [2 width], args{:});
                        
                        row = row+1;
                        args = self.getInteractiveUIControlArgsForValue(item(ii).(fn{jj}));
                        self.itemDetailGrid.newControlAtRowAndColumn( ...
                            row, [2 width], args{:}, 'HorizontalAlignment', 'right');
                    end
                end
                
            elseif iscell(item)
                for ii = 1:numel(item)
                    row = ii + 1;
                    args = self.getInteractiveUIControlArgsForValue(item{ii});
                    self.itemDetailGrid.newControlAtRowAndColumn(row, [2 width], args{:});
                end
            end
            self.itemDetailGrid.repositionControls;
        end
        
        function currentItemToBaseWorkspace(self)
            item = self.groupedList.getItemFromGroupWithMnemonic( ...
                self.currentGroup, self.currentMnemonic);
            if isvarname(self.currentMnemonic)
                name = self.currentMnemonic;
            else
                name = 'item';
            end
            assignin('base', name, item);
            disp(sprintf('sent "%s" to base workspace', name));
        end
        
        function repondToResize(self, figure, event)
            self.groupsGrid.repositionControls;
            self.mnemonicsGrid.repositionControls;
        end
        
        function listenToGroupedList(self, groupedList)
            self.listeners.NewGroup = groupedList.addlistener( ...
                'NewGroup', ...
                @(source, event)self.hearNewListGroup(source, event));
            self.listeners.NewMnemonic = groupedList.addlistener( ...
                'NewMnemonic', ...
                @(source, event)self.hearNewListMnemonic(source, event));
        end
        
        function hearNewListGroup(self, groupedList, event)
            group = event.userData;
            row = 1 + size(self.groupsGrid.controls, 1);
            cb = @(obj, event)self.setCurrentGroup(group, obj);
            self.addBrowserButtonToGridRowWithNameAndCallback( ...
                self.groupsGrid, row, group, cb);
            self.groupsGrid.repositionControls;
        end
        
        function hearNewListMnemonic(self, groupedList, event)
            if isequal(self.currentGroup, event.userData.group)
                mnemonic = event.userData.mnemonic;
                row = 1 + size(self.mnemonicsGrid.controls, 1);
                cb = @(obj, event)self.setCurrentMnemonic(mnemonic, obj);
                self.addBrowserButtonToGridRowWithNameAndCallback( ...
                    self.mnemonicsGrid, row, mnemonic, cb);
                self.mnemonicsGrid.repositionControls;
            end
        end
    end
end