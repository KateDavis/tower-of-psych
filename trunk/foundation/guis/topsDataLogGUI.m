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
        % [minimum maximum] time to display in rasterAxes
        tLim;
        
        % names of data groups to display in rasterAxes
        selectedGroups;
        
        % axes to show raster of data event times
        rasterAxes;
        
        % line to select a pointin rasterAxes
        rasterCursor;
        
        % topsValuePanel to show details for a selected data point
        detailPanel;
        
        % uicontrol to edit tLim
        tLimControl;
        
        % uicontrol to display the data log's clockFunction
        clockFunctionControl;
        
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
            
            self.tLim = [log.earliestTime, log.latestTime];
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
            yGap = .1;
            xDiv = .5;
            
            width = .3;
            height = .05;
            
            self.rasterAxes = axes( ...
                'Parent', self.figure, ...
                'Units', 'normalized', ...
                'Position', [left, yDiv, right-left, top-yDiv], ...
                'Box', 'on', ...
                'XGrid', 'on', ...
                'XLim', [0 1], ...
                'YLim', [0 1], ...
                'YTick', [], ...
                'HitTest', 'off');
            
            self.rasterCursor = line(0, -1, ...
                'Parent', self.rasterAxes, ...
                'Color', [0 0 0], ...
                'LineStyle', 'none', ...
                'Marker', 'o', ...
                'HitTest', 'off');
            
            self.detailPanel = topsValuePanel( ...
                self, [xDiv, bottom, right-xDiv, yDiv-yGap-bottom]);
            self.detailPanel.stringSummaryLength = 40;
            
            editArgs = topsText.editText;
            cb = @(obj,event)topsDataLogGUI.tLimCallback(obj,event,self);
            self.tLimControl = uicontrol( ...
                'Parent', self.figure, ...
                'Units', 'normalized', ...
                'Position', [left, yDiv-yGap, width, height], ...
                'Callback', cb, ...
                'String', summarizeValue(self.tLim, 30), ...
                editArgs{:});
            
            labelArgs = topsText.staticText;
            self.clockFunctionControl = uicontrol( ...
                'Parent', self.figure, ...
                'Units', 'normalized', ...
                'Position', [left+width, yDiv-yGap, width, height], ...
                'String', summarizeValue(log.clockFunction), ...
                labelArgs{:});
            
            cb = @(obj,event)topsDataLogGUI.groupsCallback(obj,event,self);
            self.groupsControl = uicontrol( ...
                'Parent', self.figure, ...
                'Units', 'normalized', ...
                'Position', [right-width, yDiv-yGap, width, height], ...
                'Callback', cb, ...
                'Style', 'popupmenu', ...
                'String', {'groups'}, ...
                'HorizontalAlignment', 'left');
            
            self.groupsGrid = ScrollingControlGrid( ...
                self.figure, [left, bottom, xDiv-left, yDiv-yGap-bottom]);
        end
        
        function plotRaster(self)
            n = numel(self.selectedGroups);
            if n > 0 && all(isfinite(self.tLim))
                log = topsDataLog.theDataLog;
                tLim = self.tLim;
                
                cla(self.rasterAxes)
                set(self.rasterAxes, ...
                    'XLim', tLim, ...
                    'YLim', [0, n*2+1]);
                
                texts = zeros(1, n);
                lines = zeros(1, n);
                for ii = 1:n
                    group = self.selectedGroups{ii};
                    groupColor = self.detailPanel.getColorForString(group);
                    texts(ii) = text(tLim(1), 2*ii, group, ...
                        'Parent', self.rasterAxes, ...
                        'Color', groupColor, ...
                        'FontSize', 9, ...
                        'HitTest', 'off');
                    
                    groupData = log.getAllItemsFromGroupAsStruct(group);
                    times = [groupData.mnemonic];
                    rows = (ii*2-1)*ones(size(times));
                    cb = @(obj,event)topsDataLogGUI.lineCallback( ...
                        obj, event, self, group);
                    lines(ii) = line(times, rows, ...
                        'Parent', self.rasterAxes, ...
                        'Color', groupColor, ...
                        'LineStyle', 'none', ...
                        'Marker', '.', ...
                        'HitTest', 'on', ...
                        'ButtonDownFcn', cb);
                end
            end
        end
        
        % Let child panes resize themselves.
        function repondToResize(self, figure, event)
            self.detailPanel.repondToResize;
            self.groupsGrid.repositionControls;
        end
    end
    
    methods (Static)
        function tLimCallback(obj, event, self)
            try
                tLim = eval(get(obj, 'String'));
                self.tLim = tLim;
                
                % only for test!
                self.plotRaster
                
            catch err
                disp(sprintf('%s.tLim edit failed:', mfilename))
                disp(err)
            end
            set(obj, 'String', summarizeValue(self.tLim, 30));
        end
        
        function groupsCallback(obj, event, self)
            
        end
        
        function lineCallback(l, event, self, group)
            clickPoint = get(self.rasterAxes, 'CurrentPoint');
            clickTime = clickPoint(1,1);
            lineTimes = get(l, 'XData');
            [nearest, nearestIndex] = min(abs(lineTimes-clickTime));
            dataTime = lineTimes(nearestIndex);
            
            rows = get(l, 'YData');
            set(self.rasterCursor, ...
                'XData', dataTime, ...
                'YData', rows(1));
            
            log = topsDataLog.theDataLog;
            if log.containsMnemonicInGroup(dataTime, group);
                item = log.getItemFromGroupWithMnemonic(group, dataTime);
                self.detailPanel.populateWithValueDetails(item);
            end
        end
    end
end