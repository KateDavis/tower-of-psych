classdef topsTablePanel < topsPanel
    % Browse a cell, struct, or object array with a 2D table.
    % @details
    % topsTablePanel summarizes a cell array, struct array, or object
    % array with a 2D table.  The user can view and select a table cell to
    % updatee the "current item" of a Tower of Psych GUI.
    %
    % @ingroup guis
    
    properties (SetAccess = protected)
        % the uitable for cell, struct, or object array data
        table;
        
        % map from table cells back to baseItem elements
        tableMap;
    end
    
    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsTablePanel.  @a parentFigure must be a
        % topsFigure object, otherwise the panel won't display any content.
        % @details
        function self = topsTablePanel(varargin)
            self = self@topsPanel(varargin{:});
            self.isLocked = true;
        end
        
        % Set the GUI current item from a table cell selection
        % @param table uitable object making the selection
        % @param event struct of data about the selection event
        % @details
        % Follows tableMap to get a single value out of baseItem and
        % updates the parent figure's current item with this value.
        function selectItem(self, table, event)
            % Only bother with single selections
            if size(event.Indices, 1) == 1
                % resolve the selected item
                row = event.Indices(1);
                column = event.Indices(2);
                mapPath = self.tableMap{row, column};
                item = self.subItemFromPath(mapPath);
                name = sprintf('%s%s', self.baseItemName, mapPath);
                self.parentFigure.setCurrentItem(item, name);
            end
        end
    end
    
    methods (Access = protected)
        % Create and arrange fresh components.
        function initialize(self)
            self.initialize@topsPanel();
            
            % new table for summarizing baseItem
            self.table = self.parentFigure.makeUITable( ...
                self.pan, ...
                @(table, event)self.selectItem(table, event));
            set(self.table, ...
                'Data', {}, ...
                'ColumnName', {}, ...
                'RowName', 'numbered');
            
            % update table with baseItem data
            self.updateContents();
        end
        
        % Refresh the panel's contents.
        function updateContents(self)
            if isobject(self.baseItem) || isstruct(self.baseItem)
                % struct array summary with named columns
                [tableData, self.tableMap, columnNames] = ...
                    topsGUIUtilities.makeTableForStructArray( ...
                    self.baseItem, self.parentFigure.colors);
                set(self.table, ...
                    'Data', tableData, ...
                    'ColumnName', columnNames);
                
            elseif iscell(self.baseItem)
                % cell array summary with numbered columns
                [tableData, self.tableMap] = ...
                    topsGUIUtilities.makeTableForCellArray( ...
                    self.baseItem, self.parentFigure.colors);
                set(self.table, ...
                    'Data', tableData, ...
                    'ColumnName', 'numbered');
            end
        end
    end
end