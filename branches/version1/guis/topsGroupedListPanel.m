classdef topsGroupedListPanel < topsPanel
    % Browse a grouped list by group and mnemonic.
    % @details
    % topsGroupedListPanel shows all of the group names for a
    % topsGroupedList, and all the mnemonic names for one group at a time.
    % The user can view and select one group and one mnemonic.  Each
    % selection updates the "current item" of a Tower of Psych GUI.
    %
    % TODO:
    %   - add edit text field below browser columns to edit current item
    %   and refresh contents
    %   .
    %
    % @ingroup guis
    
    properties (SetAccess = protected)
        % the grouped list to browse
        groupedList;
        
        % the uitable for group names
        groupTable;
        
        % the uitable for mnemonic names
        mnemonicTable;
        
        % the value of the currently selected group
        currentGroup;
        
        % the value of the currently selected mnemonic
        currentMnemonic;
    end
    
    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsGroupedListPanel.  @a parentFigure must be a
        % topsFigure object, otherwise the panel won't display any content.
        % @details
        function self = topsGroupedListPanel(varargin)
            self = self@topsPanel(varargin{:});
            self.isLocked = true;
        end
        
        % Choose the grouped list to browse.
        % @param groupedList topsGroupedList object
        % @details
        % @a groupedList must be a topsGroupedList object.  The grouped
        % list panel will summarize the groups and mnemonics for @a
        % groupedList and allow the user to select a current item for the
        % GUI.
        function setGroupedList(self, groupedList)
            self.groupedList = groupedList;
            groups = self.groupedList.groups;
            if ~isempty(groups)
                self.currentGroup = groups{1};
            end
            self.updateContents();
        end
        
        % Set the current list group from a selected table cell.
        % @param table uitable object making the selection
        % @param event struct of data about the selection event
        % @details
        % Sets currentGroup and the current item for the parent figure,
        % based on the selected cell in a uitable.
        function selectGroup(self, table, event)
            % Only bother with single selections
            if size(event.Indices, 1) == 1
                % select one group
                row = event.Indices(1);
                groups = self.groupedList.groups();
                if row <= numel(groups)
                    self.currentGroup = groups{row};
                    self.populateMnemonicTable();
                    self.currentItemForGroupAndMnemonic();
                end
            end
        end
        
        % Set the current list mnemonic from a selected table cell.
        % @param table uitable object making the selection
        % @param event struct of data about the selection event
        % @details
        % Sets currentMnemonic and the current item for the parent figure,
        % based on the selected cell in a uitable.
        function selectMnemonic(self, table, event)
            % Only bother with single selections
            if size(event.Indices, 1) == 1
                % select one mnemonic
                row = event.Indices(1);
                mnemonics = ...
                    self.groupedList.getAllMnemonicsFromGroup( ...
                    self.currentGroup);
                if row <= numel(mnemonics)
                    self.currentMnemonic = mnemonics{row};
                end
                self.currentItemForGroupAndMnemonic();
            end
        end
    end
    
    methods (Access = protected)
        % Create and arrange fresh components.
        function initialize(self)
            self.initialize@topsPanel();
            
            % new table for groups
            self.groupTable = self.parentFigure.makeUITable( ...
                self.pan, ...
                @(table, event)self.selectGroup(table, event));
            set(self.groupTable, ...
                'Position', [0 0 0.5 1], ...
                'Data', {}, ...
                'ColumnName', {'group'});
            
            % new table for mnemonics
            self.mnemonicTable = self.parentFigure.makeUITable( ...
                self.pan, ...
                @(table, event)self.selectMnemonic(table, event));
            set(self.mnemonicTable, ...
                'Position', [0.5 0 0.5 1], ...
                'Data', {}, ...
                'ColumnName', {'group'})
            
            % update the tree to use groupedList
            self.updateContents();
        end
        
        % Refresh the group table's contents
        function populateGroupTable(self)
            % get the list of groups
            groups = self.groupedList.groups;
            groupSummary = topsGUIUtilities.makeTableForCellArray( ...
                groups(:), self.parentFigure.colors);
            
            % default or preserve the group selection
            if isempty(groups)
                self.currentGroup = [];
                
            elseif ~self.groupedList.containsGroup(self.currentGroup);
                self.currentGroup = groups{1};
            end

            % set the column width from the table width
            %   which is irritating
            set(self.groupTable, 'Units', 'pixels');
            pixelPosition = get(self.groupTable, 'Position');
            columnWidth = pixelPosition(3) - 5;
            set(self.groupTable, ...
                'Units', 'normalized', ...
                'ColumnWidth', {columnWidth}, ...
                'Data', groupSummary);
        end
        
        % Refresh the mnemonic table's contents
        function populateMnemonicTable(self)
            % get the list of group mnemonics
            if isempty(self.currentGroup)
                mnemonics = {};
            else
                mnemonics = self.groupedList.getAllMnemonicsFromGroup( ...
                    self.currentGroup);
            end
            mnemonicSummary = topsGUIUtilities.makeTableForCellArray( ...
                mnemonics(:), self.parentFigure.colors);
            
            % default or preserve the mnemonic selection
            if isempty(mnemonics)
                self.currentMnemonic = [];
                
            elseif ~self.groupedList.containsMnemonicInGroup( ...
                    self.currentMnemonic, self.currentGroup);
                self.currentMnemonic = mnemonics{1};
            end
            
            % set the column width from the table width
            %   which is irritating
            set(self.mnemonicTable, 'Units', 'pixels');
            pixelPosition = get(self.mnemonicTable, 'Position');
            columnWidth = pixelPosition(3) - 5;
            set(self.mnemonicTable, ...
                'Units', 'normalized', ...
                'ColumnWidth', {columnWidth}, ...
                'Data', mnemonicSummary);
        end
        
        % Refresh the panel's contents.
        function updateContents(self)
            if isobject(self.groupedList)
                % repopulate tables with groups and mnemonics
                self.populateGroupTable();
                self.populateMnemonicTable();
                
                % update the current item
                self.currentItemForGroupAndMnemonic();
            end
        end
        
        % Set the GUI current item from selected group and mnemonic.
        function currentItemForGroupAndMnemonic(self)
            if self.groupedList.containsMnemonicInGroup( ...
                    self.currentMnemonic, self.currentGroup)
                
                % get out the selected item
                item = self.groupedList.getItemFromGroupWithMnemonic( ...
                    self.currentGroup, self.currentMnemonic);
                
                % make up a name for the selected item
                if ischar(self.currentGroup)
                    groupName = self.currentGroup;
                else
                    groupName = num2str(self.currentGroup);
                end
                
                if ischar(self.currentGroup)
                    mnemonicName = self.currentMnemonic;
                else
                    mnemonicName = num2str(self.currentMnemonic);
                end
                name = sprintf('%s{%s}{%s}', ...
                    self.groupedList.name, groupName, mnemonicName);
                
                % report the current item to the parent figure
                self.parentFigure.setCurrentItem(item, name);
            end
        end
    end
end