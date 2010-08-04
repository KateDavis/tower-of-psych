classdef topsDataLogGUI < topsGUI
    % @class topsDataLogGUI
    % Visualize data sorted by time.
    % topsDataLogGUI plots a summary of data event times from the current
    % topsDataLog, as a raster over time.  You can show and hide different
    % data groups.  You can view different time ranges.
    % @details
    % There will be more to come, as I reimagine this GUI...
    % @ingroup foundation
    
    properties
        % minimum time to display in rasterAxes
        tMin;
        
        % length of time to display in rasterAxes
        tLength;
        
        % names of data groups to display in rasterAxes
        selectedGroups;
        
        % axes to show raster of data event times
        rasterAxes;
        
        % topsValuePanel to show details for a selected data point
        detailPanel;
        
        % uicontrol to edit the minimum displayed time
        tMinControl;
        
        % uicontrol to edit the length of displayed time
        tLengthControl;
        
        % uicontrol to select data groups by name
        groupsControl;
        
        % ScrollingControlGrid to show and toggle selected data groups
        groupsGrid;
    end
    
    methods
        function self = topsDataLogGUI()
            self = self@topsGUI;
            self.title = 'topsDataLog';
            
            log = topsDataLog.theDataLog;
            
            self.tMin = log.earliestTime;
            self.tLength = log.latestTime - log.earliestTime;
            self.selectedGroups = log.groups;
            
            self.createWidgets;
            self.plotRaster;
        end
        
        
        function createWidgets(self)
            self.setupFigure;
            log = topsDataLog.theDataLog;
            
            left = .01;
            right = .99;
            top = .99;
            bottom = .01;
            
            yDiv = .5;
            xDiv = .5;
            
            self.rasterAxes = axes( ...
                'Parent', self.figure, ...
                'Position', [left, yDiv, right-left, top-yDiv], ...
                'Box', 'on', ...
                'XGrid', 'on', ...
                'YTick', [], ...
                'HitTest', 'off');
            xlabel(self.rasterAxes, summarizeValue(log.clockFunction));;
            
            self.detailPanel = topsValuePanel( ...
                self, [xDiv, bottom, right-xDiv, yDiv-bottom]);
            
            self.tMinControl;
            
            self.tLengthControl;
            
            self.groupsControl;
            
            self.groupsGrid = ScrollingControlGrid( ...
                self.figure, [left, bottom, xDiv-left, yDiv-bottom]);
        end
        
        function plotRaster(self)
            log = topsDataLog.theDataLog;
            if ~isnan(self.tMin) && ~isnan(self.tLength)
                set(self.rasterAxes, ...
                    'XLim', self.tMin + [0, self.tLength]);
            end
            
            n = numel(self.selectedGroups);
            if n > 0
                set(self.rasterAxes, ...
                    'YLim', [0, n*2+1])
            end
        end
        
        % Let child panes resize themselves.
        function repondToResize(self, figure, event)
            self.detailPanel.repondToResize;
            self.groupsGrid.repositionControls;
        end
    end
end