classdef topsGroupedListGUI < topsGUI
    % @class topsGroupedListGUI
    % Visualize the items stored in a grouped list.
    % topsGroupedListGUI shows you a three-column view of a
    % topsGroupedList (or subclass).
    % <br><br>
    % The left column shows all the groups in the list.  The middle column
    % shows all the mnemonics in the currently selected group.  The right
    % column shows details for the item that has the currently selected
    % mnemonic.
    % <br><br>
    % Simple items like numbers and strings are shown by their value.
    % Strings are color-coded with a color scheme that's standard for Tower
    % of Psych GUIS.
    % <br><br>
    % Complex items like cell arrays, structs, and objects are expanded
    % into multiple rows that show their elements, fields, and properties.
    % Field and property names and are left-aligned and their values are
    % right-aligned on the next row.  Again strings, including field and
    % property names, are color-codded.
    % <br><br>
    % Struct arrays and object arrays are expanded even further, with a
    % group of rows for each element of the array.  In this case rows may
    % extend beneath the visible part of the column and a slider bar will
    % appear to bring these rows into view.
    % <br><br>
    % Some items, elements, field values, and property values will appear
    % in bold:
    %   - strings or function handles that can be found on Matlab's path
    %   can be clicked to open them in Matlab's m-file editor.
    %   - instances of Towe of Psych foundation classes can be clicked to
    %   open their respective Towe of Psych GUIs.
    %   .
    % The "to workspace" button in the top right corner of the GUI lets you
    % send the currently displayed item to Matlab's base workspace (i.e.
    % the Command Window).  If the menmonic for the current item is a valid
    % variable name, the GUI will create or overwrite a variable with that
    % name.  Otherwise, the GUI will create or overwrite a variable with
    % the name "item".
    % <br><br>
    % You can launch topsGroupedListGUI with the topsGroupedListGUI()
    % constructor, or with the gui() method a topsGroupedList or subclass.
    % <br><br>
    % topsGroupedListGUI uses listeners to detect changes to the list its
    % showing.  This means that you can view a list as you work on your
    % experiment, and you don't have to reopen or refresh the GUI.
    % <br><br>
    % Beware that listeners can slow Matlab down.  So if you're in a
    % timing-critical situation, like some experiments, you might wish to
    % close the GUI, deleting its listeners.
    % @ingroup foundation
    
    properties
        % The topsGroupedList or subclass to visualize in the GUI.
        groupedList;
        
        % The string or number of the currently selected group
        currentGroup;
        
        % The string or number of the curently selected mnemonic
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
        % Constructor takes one optional argument
        % @param groupedList a list to visualize
        % @details
        % Returns a handle to the new topsGroupedListGUI.  If
        % @a groupedList is missing, the GUI will launch but no
        % data will be shown.
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

        % Send the currently displayed item to the base workspace.
        % The "to workspace" button calls this method.  This method then
        % uses Matlab's built-in assignin() to put the currently shown item
        % in the base workspace (i.e. the Command Window).
        % <br><br>
        % When the currently selected mnemonic is a valid variable name,
        % creates or overwrites a variable with that name.  Otherwise,
        % creates or overwrites a variable named "item".  Prints a message
        % about which name was used.
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
            self.itemDetailGrid.repositionControls;
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