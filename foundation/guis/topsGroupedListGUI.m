classdef topsGroupedListGUI < topsGUI
    % @class topsGroupedListGUI
    % Visualize the items stored in a grouped list.
    % topsGroupedListGUI shows you a three-column view of a
    % topsGroupedList (or subclass).
    % @details
    % The left column shows all the groups in the list.  The middle column
    % shows all the mnemonics in the currently selected group.  The right
    % column shows details for the item that has the currently selected
    % mnemonic.
    % @details
    % Simple items like numbers and strings are shown by their value.
    % Strings are color-coded with a color scheme that's standard for Tower
    % of Psych GUIS.
    % @details
    % Complex items like cell arrays, structs, and objects are expanded
    % into multiple rows that show their elements, fields, and properties.
    % Field and property names and are left-aligned and their values are
    % right-aligned on the next row.  Again strings, including field and
    % property names, are color-codded.
    % @details
    % Struct arrays and object arrays are expanded even further, with a
    % group of rows for each element of the array.  In this case rows may
    % extend beneath the visible part of the column and a slider bar will
    % appear to bring these rows into view.
    % @details
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
    % @details
    % You can launch topsGroupedListGUI with the topsGroupedListGUI()
    % constructor, or with the gui() method a topsGroupedList or subclass.
    % @details
    % topsGroupedListGUI uses listeners to detect changes to the list its
    % showing.  This means that you can view a list as you work on your
    % experiment, and you don't have to reopen or refresh the GUI.
    % @details
    % Beware that listeners can slow Matlab down.  So if you're in a
    % timing-critical situation, like some experiments, you might wish to
    % close the GUI, deleting its listeners.
    % @ingroup foundation
    
    properties
        % topsGroupedList interact with
        groupedList;
        
        % string or number identifying the currently selected group
        currentGroup;
        
        % string or number identifying the currently selected mnemonic
        currentMnemonic;
    end
    
    properties(Hidden)
        groupString = 'group:';
        groupLabel;
        groupsGrid;
        
        mnemonicString = 'mnemonic:';
        mnemonicLabel;
        mnemonicsGrid;
        
        itemString = 'item:';
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
                'String', self.groupString, ...
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
                'String', self.mnemonicString, ...
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
                'String', self.itemString, ...
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
            self.itemDetailGrid.rowHeight = 1.5;
        end
        
        function setCurrentGroup(self, group, button)
            self.currentGroup = group;
            self.repopulateMnemonicsGrid;
            if nargin > 2
                topsText.toggleOff(self.groupsGrid.controls);
                topsText.toggleOn(button);
                drawnow;
            end
        end
        
        function setCurrentMnemonic(self, mnemonic, button)
            self.currentMnemonic = mnemonic;
            self.showDetailsForCurrentItem;
            if nargin > 2
                topsText.toggleOff(self.mnemonicsGrid.controls);
                topsText.toggleOn(button);
                drawnow;
            end
        end
        
        function repopulateGroupsGrid(self)
            groups = self.groupedList.groups;
            self.groupsGrid.deleteAllControls;
            for ii = 1:length(groups)
                cb = @(obj, event)self.setCurrentGroup(groups{ii}, obj);
                self.addGridButton( ...
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
                self.addGridButton( ...
                    self.mnemonicsGrid, ii, mnemonics{ii}, cb);
            end
            self.mnemonicsGrid.repositionControls;
            if ~isempty(mnemonics)
                button = self.mnemonicsGrid.controls(1,1);
                self.setCurrentMnemonic(mnemonics{1}, button);
            end
        end
        
        function addGridButton(self, grid, row, name, callback)
            toggle = topsText.toggleText;
            lookFeel = self.getLookAndFeelForValue(name);
            interactive = {'Callback', callback};
            grid.newControlAtRowAndColumn( ...
                row, 1, ...
                toggle{:}, ...
                lookFeel{:}, ...
                interactive{:});
        end
        
        function showDetailsForCurrentItem(self)
            group = self.currentGroup;
            mnemonic = self.currentMnemonic;
            item = self.groupedList.getItemFromGroupWithMnemonic( ...
                group, mnemonic);
            
            self.itemDetailGrid.deleteAllControls;
            width = 10;
            
            % shallow look at any item
            %args = self.getInteractiveUIControlArgsForValue(item);
            args = self.getEditableUIControlArgsForListItem( ...
                group, mnemonic, []);
            
            self.itemDetailGrid.newControlAtRowAndColumn(1, [1 width], args{:});
            
            % deeper look at deep items
            subsPath = {};
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
                    subsPath(1:2) = {'()',{ii}};
                    delimiter = sprintf('(%d of %d)', ii, n);
                    
                    args = self.getInteractiveUIControlArgsForValue(item(ii));
                    
                    self.itemDetailGrid.newControlAtRowAndColumn( ...
                        row, [1 4], args{:}, 'String', delimiter);
                    
                    for jj = 1:length(fn)
                        % field name and value
                        row = row+1;
                        subsPath(3:4) = {'.',fn{jj}};
                        args = self.getDescriptiveUIControlArgsForValue(fn{jj});
                        self.itemDetailGrid.newControlAtRowAndColumn( ...
                            row, [2 width], args{:});
                        
                        row = row+1;
                        %args = self.getInteractiveUIControlArgsForValue(item(ii).(fn{jj}));
                        args = self.getEditableUIControlArgsForListItem( ...
                            group, mnemonic, subsPath);
                        self.itemDetailGrid.newControlAtRowAndColumn( ...
                            row, [2 width], args{:}, 'HorizontalAlignment', 'right');
                    end
                end
                
            elseif iscell(item)
                for ii = 1:numel(item)
                    row = ii + 1;
                    subsPath(1:2) = {'{}',{ii}};
                    %args = self.getInteractiveUIControlArgsForValue(item{ii});
                    args = self.getEditableUIControlArgsForListItem( ...
                        group, mnemonic, subsPath);
                    self.itemDetailGrid.newControlAtRowAndColumn(row, [2 width], args{:});
                end
            end
            self.itemDetailGrid.repositionControls;
        end
        
        % Present standard controls for editing list items.
        function args = getEditableUIControlArgsForListItem(self, group, mnemonic, subsPath)
            if nargin < 4 || isempty(subsPath)
                subs = [];
            else
                subs = substruct(subsPath{:});
            end
            
            getter = {@topsGroupedListGUI.getValueOfListItem, ...
                self.groupedList, group, mnemonic, subs};
            setter = {@topsGroupedListGUI.setValueOfListItem, ...
                self.groupedList, group, mnemonic, subs};
            
            args = self.getEditableUIControlArgsWithGetterAndSetter( ...
                getter, setter);
        end
        
        % Send the currently displayed item to the base workspace.
        % The "to workspace" button calls this method.  This method then
        % uses Matlab's built-in assignin() to put the currently shown item
        % in the base workspace (i.e. the Command Window).
        % @details
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
            self.listPanel.repondToResize(figure, event);
        end
        
        function listenToGroupedList(self, groupedList)
            self.deleteListeners;
            self.listeners.NewAddition = ...
                groupedList.addlistener('NewAddition', ...
                @(source, event)self.hearNewListAddition(source, event));
        end
        
        function hearNewListAddition(self, groupedList, event)
            logEntry = event.userData;
            group = logEntry.group;
            mnemonic = logEntry.mnemonic;
            
            if logEntry.groupIsNew
                row = 1 + size(self.groupsGrid.controls, 1);
                cb = @(obj, event)self.setCurrentGroup(group, obj);
                self.addGridButton( ...
                    self.groupsGrid, row, group, cb);
                self.groupsGrid.repositionControls;
            end
            
            if ~isequal(self.currentMnemonic, mnemonic)
                row = 1 + size(self.mnemonicsGrid.controls, 1);
                cb = @(obj, event)self.setCurrentMnemonic(mnemonic, obj);
                self.addGridButton( ...
                    self.mnemonicsGrid, row, mnemonic, cb);
                self.mnemonicsGrid.repositionControls;
            end
        end
    end
    
    methods (Static)
        % Set a value from a GUI control (a callback).
        % @param value a new value to set
        % @param list topsGroupedList that contains the value
        % @param group list group that contains the value
        % @param mnemonic list group mnemonic for the value
        % @param subs substruct-style struct to index the list item
        % (optional)
        % @details
        % Replaces the item in @a list indicated by @a group and @a
        % mnemonic with the given @a value.  If @a subs is not empty,
        % replaces the referenced element or field of the indicated item,
        % rather than the item itself.
        % @details
        % setValueOfListItem() is suitable as a topsText "setter" callback.
        function setValueOfListItem(value, list, group, mnemonic, subs)
            if isempty(subs)
                item = value;
            else
                item = list.getItemFromGroupWithMnemonic(group, mnemonic);
                item = subsasgn(item, subs, value);
            end
            list.addItemToGroupWithMnemonic(item, group, mnemonic);
        end
        
        % Get a value for a GUI control (a callback).
        % @param list topsGroupedList that contains the value
        % @param group list group that contains the value
        % @param mnemonic list group mnemonic for the value
        % @param subs substruct-style struct to index the list item
        % (optional)
        % @details
        % Returns the item in @a list indicated by @a group and @a
        % mnemonic.  If @a subs is not empty, returns the referenced
        % element or field of the indicated item, rather than the item
        % itself.
        % @details
        % getValueOfListItem() is suitable as a topsText "getter" callback.
        function value = getValueOfListItem(list, group, mnemonic, subs)
            if isempty(subs)
                value = list.getItemFromGroupWithMnemonic(group, mnemonic);
            else
                item = list.getItemFromGroupWithMnemonic(group, mnemonic);
                value = subsref(item, subs);
            end
        end
    end
end