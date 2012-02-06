classdef topsGroupedListPanel < topsDetailPanel
    % @class topsGroupedListPanel
    % Resuable 3-column view for topsGroupedLists in topsGUI interfaces.
    % @details
    % Many interface classes, not just topsGroupedListGUI, need to present
    % controls for interacting with topsGroupedList objects.
    % topsGroupedListPanel supports topsGroupedList interactions as a
    % uipanel within any topsGUI subclass.
    % @ingroup foundataion
    
    properties
        % topsGroupedList to interact with
        groupedList;
        
        % string or number identifying the currently selected group
        currentGroup;
        
        % string or number identifying the currently selected mnemonic
        currentMnemonic;
    end
    
    properties (Hidden)
        % string title for the "groups" column at left
        groupString = 'group:';
        
        % uicontrol label for the "groups" column at left
        groupLabel;
        
        % ScrollingControlGrid for the "groups" column at left
        groupsGrid;
        
        % string title for the "mnemonics" column in the middle
        mnemonicString = 'mnemonic:';
        
        % uicontrol label for the "mnemonics" column in the middle
        mnemonicLabel;
        
        % ScrollingControlGrid for the "mnemonics" column in the middle
        mnemonicsGrid;
        
        % string title for the "item" column at right
        itemString = 'item:';
        
        % uicontrol label for the "item" column at right
        itemLabel;
        
        % uicontrol button to send the current item to the base workspace
        itemToWorkspaceButton;
        
        % topsValuePanel for the "item" column at right
        itemDetailPanel;
        
        % uicontrol checkbox to select editable mode
        itemEditableControl;
        
        % index of event listener added to parentGUI
        listenerIndex;
    end
    
    methods
        % Constructor takes one optional argument.
        % @param parentGUI a topsGUI to contains this panel
        % @param position normalized [x y w h] where to locate the new
        % panel in @a parentGUI
        % @details
        % Returns a handle to the new topsGroupedListPanel.  If
        % @a parentGUI is missing, the panel will be empty.
        function self = topsGroupedListPanel(varargin)
            self = self@topsDetailPanel(varargin{:});
        end
        
        % Populate this panel with the contents of a topsGroupedList.
        % @param groupedList a topsGroupedList object to interact with
        % @details
        % Fills in this panel's controls  with data from the given @a
        % groupedList, and binds the controls to interact with @a
        % groupedList.  If this panel's itemsAreEditable is true, the
        % controls will allow editing of items in @a groupedList.
        function populateWithGroupedList(self, groupedList)
            self.groupedList = groupedList;
            self.listenToGroupedList(groupedList);
            self.repopulateGroupsGrid;
        end
        
        % Sync detailsAreEditable with detail panel and "edit" button.
        function setEditable(self, isEditable)
            self.setEditable@topsDetailPanel(isEditable);
            self.itemDetailPanel.setEditable(isEditable);
            set(self.itemEditableControl, 'Value', isEditable);
        end
        
        % Unpopulate this panel so that it uses no topsGroupedList
        % @details
        % Clears this panel's controls of data and unbinds them from the
        % current groupedList.  This allows the groupedList to be deleted,
        % and possibly swapped with another using
        % populateWithGroupedList(), without causing an error for the panel
        % controls
        function unpopulate(self)
            self.groupedList = [];
            if ~isempty(self.listenerIndex)
                self.parentGUI.deleteListenerWithNameAndIndex( ...
                    'NewAddition', self.listenerIndex);
            end
            self.createWidgets;
        end
        
        % Create a new ui panel and add unpopulated controls to it.
        function createWidgets(self)
            self.createWidgets@topsDetailPanel;
            
            left = 0;
            right = 1;
            bottom = 0;
            top = 1;
            yDiv = .95;
            width = (1/3);
            self.groupLabel = uicontrol( ...
                'Parent', self.panel, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', self.groupString, ...
                'Position', [left, yDiv, width, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            if ~isempty(self.groupsGrid)
                self.parentGUI.removeScrollableChild( ...
                    self.groupsGrid.panel);
            end
            self.groupsGrid = ScrollingControlGrid( ...
                self.panel, [left, bottom, width, yDiv-bottom]);
            self.parentGUI.addScrollableChild(self.groupsGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, ...
                self.groupsGrid});
            
            self.mnemonicLabel = uicontrol( ...
                'Parent', self.panel, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', self.mnemonicString, ...
                'Position', [width, yDiv, width, top-yDiv], ...
                'HorizontalAlignment', 'left');

            if ~isempty(self.mnemonicsGrid)
                self.parentGUI.removeScrollableChild( ...
                    self.mnemonicsGrid.panel);
            end
            self.mnemonicsGrid = ScrollingControlGrid( ...
                self.panel, [width, bottom, width, yDiv-bottom]);
            self.parentGUI.addScrollableChild(self.mnemonicsGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, ...
                self.mnemonicsGrid});
            
            itemToBase = @(obj, event)self.currentItemToBaseWorkspace;
            self.itemToWorkspaceButton = uicontrol( ...
                'Parent', self.panel, ...
                'Callback', itemToBase, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'to workspace', ...
                'Position', [right-width-width/2, yDiv, width/2, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            self.itemLabel = uicontrol( ...
                'Parent', self.panel, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', self.itemString, ...
                'Position', [right-width, yDiv, width/2, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            self.itemDetailPanel = topsValuePanel( ...
                self.parentGUI, [right-width, bottom, width, yDiv-bottom]);
            self.itemDetailPanel.getterFunction = ...
                @topsGroupedListPanel.getValueOfListItem;
            self.itemDetailPanel.setterFunction = ...
                @topsGroupedListPanel.setValueOfListItem;
            self.itemDetailPanel.getSetContext = self;
            
            setEditable = ...
                @(obj, event)setEditable(self, (get(obj, 'Value')));
            self.itemEditableControl = uicontrol( ...
                'Parent', self.panel, ...
                'Callback', setEditable, ...
                'Value', self.detailsAreEditable, ...
                'Style', 'togglebutton', ...
                'Units', 'normalized', ...
                'String', 'edit', ...
                'Position', [right-width/2, yDiv, width/2, top-yDiv], ...
                'HorizontalAlignment', 'left');
        end
        
        % Update the displayed group column name.
        function set.groupString(self, groupString)
            self.groupString = groupString;
            set(self.groupLabel, 'String', groupString);
        end
        
        % Update the displayed mnemonic column name.
        function set.mnemonicString(self, mnemonicString)
            self.mnemonicString = mnemonicString;
            set(self.mnemonicLabel, 'String', mnemonicString);
        end
        
        % Update the displayed item column name.
        function set.itemString(self, itemString)
            self.itemString = itemString;
            set(self.itemLabel, 'String', itemString);
        end
        
        % Display mnemonics for a list group.
        function setCurrentGroup(self, group, button)
            self.currentGroup = group;
            self.repopulateMnemonicsGrid;
            if nargin > 2
                topsText.toggleOff(self.groupsGrid.controls);
                topsText.toggleOn(button);
                drawnow;
            end
        end
        
        % Display details for an item with a given mnemonic.
        function setCurrentMnemonic(self, mnemonic, button)
            self.currentMnemonic = mnemonic;
            
            value = self.groupedList.getItemFromGroupWithMnemonic( ...
                self.currentGroup, self.currentMnemonic);
            self.itemDetailPanel.populateWithValueDetails(value);
            
            if nargin > 2
                topsText.toggleOff(self.mnemonicsGrid.controls);
                topsText.toggleOn(button);
                drawnow;
            end
        end
        
        % Update the diplayed list groups.
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
        
        % Update the displayed group mnemonics.
        function repopulateMnemonicsGrid(self)
            mnemonics = self.groupedList.getAllMnemonicsFromGroup( ...
                self.currentGroup);
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
        
        % Add a control to the groups, mnemonics, or item detail column.
        function addGridButton(self, grid, row, name, callback)
            toggle = topsText.toggleTextWithCallback(callback);
            lookFeel = self.getLookAndFeelForValue(name);
            grid.newControlAtRowAndColumn( ...
                row, 1, ...
                toggle{:}, ...
                lookFeel{:});
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
            if isobject(self.groupedList)
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
        end
        
        % Register to receive notifications from groupedList.
        function listenToGroupedList(self, groupedList)
            listener = groupedList.addlistener('NewAddition', ...
                @(source, event)self.hearNewAddition(source, event));
            ii = self.parentGUI.addListenerWithName(listener, 'NewAddition');
            self.listenerIndex = ii;
        end
        
        % Respond when an item is added to groupedList.
        function hearNewAddition(self, groupedList, event)
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
            
            if isequal(self.currentMnemonic, mnemonic)
                value = self.groupedList.getItemFromGroupWithMnemonic( ...
                    self.currentGroup, self.currentMnemonic);
                self.itemDetailPanel.populateWithValueDetails(value);
                
            else
                row = 1 + size(self.mnemonicsGrid.controls, 1);
                cb = @(obj, event)self.setCurrentMnemonic(mnemonic, obj);
                self.addGridButton( ...
                    self.mnemonicsGrid, row, mnemonic, cb);
                self.mnemonicsGrid.repositionControls;
            end
        end
        
        % Resize the groups, mnemonics, and item detail columns.
        function repondToResize(self, figure, event)
            self.groupsGrid.repositionControls;
            self.mnemonicsGrid.repositionControls;
            self.itemDetailPanel.repondToResize;
        end
    end
    
    methods (Static)
        % Set a value to an item in groupedList using subsasgn().
        % @details
        % Expects the topsGroupedListPanel (self) as getSetContext.
        function setValueOfListItem(value, object, subs, self)
            list = self.groupedList;
            group = self.currentGroup;
            mnemonic = self.currentMnemonic;
            
            if isempty(subs)
                item = value;
            else
                item = list.getItemFromGroupWithMnemonic(group, mnemonic);
                item = subsasgn(item, subs, value);
            end
            list.addItemToGroupWithMnemonic(item, group, mnemonic);
        end
        
        % Get a value from an item in groupedList using subsref().
        % @details
        % Expects the topsGroupedListPanel (self) as getSetContext.
        function value = getValueOfListItem(object, subs, self)
            list = self.groupedList;
            group = self.currentGroup;
            mnemonic = self.currentMnemonic;
            
            if isempty(subs)
                value = list.getItemFromGroupWithMnemonic(group, mnemonic);
            else
                item = list.getItemFromGroupWithMnemonic(group, mnemonic);
                value = subsref(item, subs);
            end
        end
    end
end