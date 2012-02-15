classdef topsDataLogPanel < topsPanel
    % Browse the Tower of Psych data log.
    % @details
    % topsDataLogPanel shows an overview of data stored in topsDataLog.  It
    % has a "raster" plot which plots data timestamp vs. data groups.
    % Users can select indivitual points in the raster plot to set the
    % "current item" of a Tower of Psych GUI.  The panel also has controls
    % for selecting which groups and the time range for the raster plot.
    %
    % @ingroup guis
    
    properties (SetAccess = protected)
        % axes for raster data summary
        rasterAxes;
        
        % the uitable for group names
        groupTable;
        
        % logical selector for groups to plot in the raster
        isPlotGroup;
        
        % button for plotting full data time range
        fullRangeButton;
        
        % text edit field for for plotting a custom data time range
        chooseRangeField;
        
        % button for selecting all data groups
        allGroupsButton;

        % button for selecting no data groups
        noGroupsButton;

        % text edit field for for selecting groups by regular expression
        regexpGroupsField;
    end
    
    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsDataLogPanel.  @a parentFigure must be a
        % topsFigure object, otherwise the panel won't display any content.
        % @details
        function self = topsDataLogPanel(varargin)
            self = self@topsPanel(varargin{:});
            self.isLocked = true;
        end
        
        % Set the GUI current item group from a clicked-on raster point.
        % @param line line object that was clicked
        % @param event struct of data about the selection event
        % @details
        % Sets the current item for the parent figure, based on the
        % selected line in a raster plot.
        function selectItem(self, line, event)
            
        end

        % Set which data groups are selected from uitable checkboxes.
        % @param table uitable object editing checkboxes
        % @param event struct of data about the edit event
        % @details
        % Updates which data groups are selected, when a user clicks a
        % uitable checkbox.
        function editGroupSelection(self, table, event)
            
        end
        
        % Select all groups to plot in the raster.
        function selectAllGroups(self)
            
        end

        % Select no groups to plot in the raster.
        function selectNoGroups(self)
            
        end

        % Select groups to plot in the raster that match an expression.
        % @param expression string regular expression to match group names
        % @details
        % Adds data groups that match the given @a expresssion to the
        % groups that are ploted in the raster. 
        function selectMatchingGroups(self, expression)
            
        end
    end
    
    methods (Access = protected)
        % Create and arrange fresh components.
        function initialize(self)
            self.initialize@topsPanel();
            
            % how to split up the panel real estate
            yDiv = 0.4;
            xDiv = 0.3;
            
            % how big to make buttons and text fields
            w = xDiv/2;
            h = yDiv/6;
            
            % axes for data raster overview
            axPadding = [0.01 0.05 -0.02 -0.06];
            self.rasterAxes = self.parentFigure.makeAxes(self.pan);
            set(self.rasterAxes, ...
                'Position', [0 yDiv 1 1-yDiv] + axPadding, ...
                'YTick', [], ...
                'XTick', [0 1]);
            
            % table for groups
            self.groupTable = self.parentFigure.makeUITable( ...
                self.pan, ...
                @(table, event)self.editGroupSelection(table, event));
            set(self.groupTable, ...
                'Position', [xDiv 0 1-xDiv yDiv], ...
                'ColumnName', {'plot', 'group'}, ...
                'ColumnEditable', [true, false], ...
                'Data', {true, 'cheese'});

            % button to select no groups
            self.noGroupsButton = self.parentFigure.makeButton( ...
                self.pan, ...
                @(button, event)self.selectNoGroups());
            set(self.noGroupsButton, ...
                'String', 'plot none', ...
                'Position', [0 yDiv-h w, h]);
            
            % button to select all groups
            self.allGroupsButton = self.parentFigure.makeButton( ...
                self.pan, ...
                @(button, event)self.selectAllGroups());
            set(self.allGroupsButton, ...
                'String', 'plot all', ...
                'Position', [w yDiv-h w, h]);

            % field to select groups by regular expression matching
            self.regexpGroupsField = self.parentFigure.makeEditField( ...
                self.pan, ...
                @(field, event)self.selectMatchingGroups( ...
                get(field, 'String')));
            set(self.regexpGroupsField, ...
                'String', 'plot matching regexp', ...
                'Position', [0 yDiv-2*h xDiv h]);
            
            % button for plotting all data times
            self.fullRangeButton = self.parentFigure.makeButton( ...
                self.pan, ...
                @(button, event)self.fullTimeRange());
            set(self.fullRangeButton, ...
                'String', 'full range', ...
                'Position', [0 h xDiv, h]);

            % field for choosing a custom time range
            self.chooseRangeField = self.parentFigure.makeEditField( ...
                self.pan, ...
                @(field, event)self.chooseTimeRange( ...
                get(field, 'String')));
            set(self.chooseRangeField, ...
                'String', 'choose range', ...
                'Position', [0 0 xDiv h]);
            
            % go get the data log
            log = topsDataLog.theDataLog();
            if isempty(log.name)
                name = class(log);
            else
                name = log.name;
            end
            self.setBaseItem(log, name);
            
            % update the groups and raster plot
            self.updateContents();
        end
        
        % Refresh the group table's contents
        function populateGroupTable(self)
            % get the list of groups
            groups = self.baseItem.groups;
            groupSummary = topsGUIUtilities.makeTableForCellArray( ...
                groups(:), self.parentFigure.colors);
            
            % by default, plot all groups
            self.isPlotGroup = true(size(groupSummary));
            tableData = cat(2, num2cell(self.isPlotGroup), groupSummary);
            
            % set the column width from the table width
            %   which is irritating
            set(self.groupTable, 'Units', 'pixels');
            pixelPosition = get(self.groupTable, 'Position');
            columnWidth = [0.15 0.85]*pixelPosition(3) - 2;
            set(self.groupTable, ...
                'Units', 'normalized', ...
                'ColumnWidth', num2cell(columnWidth), ...
                'Data', tableData);
        end
        
        % Refresh the panel's contents.
        function updateContents(self)
            if isobject(self.baseItem)
                % repopulate tables with groups and mnemonics
                self.populateGroupTable();
            end
        end
    end
end