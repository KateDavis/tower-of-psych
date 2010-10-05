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
        
        % uicontrol to select data groups by name
        groupsMenu;
        
        % uicontrol to select data groups by regular expression
        groupsRegexp;
        
        % ScrollingControlGrid to show and toggle selected data groups
        groupsGrid;
        
        % topsValuePanel to show details for a selected data point
        detailPanel;
        
        % uicontrol to edit tLim
        tLimControl;
        
        % uicontrol to display the data log's clockFunction
        clockFunctionControl;
    end
    
    properties (Hidden)
        % "meta group" to select all groups
        allGroups = 'all groups';
        
        % "meta group" to select no group
        noGroup = 'no group';
        
        % handles for data group labels
        groupTexts;
        
        % handles for data group lines
        groupLines;
    end
    
    methods
        function self = topsDataLogGUI()
            self = self@topsGUI;
            self.title = 'topsDataLog';
            
            self.createWidgets;
            
            log = topsDataLog.theDataLog;
            self.tLim = [log.earliestTime, log.latestTime];
            self.selectGroup(self.allGroups);
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
            
            width = .33;
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
            
            lookFeel = self.detailPanel.getLookAndFeelForValue(0);
            editArgs = topsText.editText;
            cb = @(obj,event)topsDataLogGUI.tLimCallback(obj,event,self);
            self.tLimControl = uicontrol( ...
                'Parent', self.figure, ...
                'Units', 'normalized', ...
                'Position', [xDiv, yDiv-yGap, width, height], ...
                'Callback', cb, ...
                lookFeel{:}, editArgs{:});
            
            lookFeel = self.detailPanel.getLookAndFeelForValue( ...
                log.clockFunction);
            labelArgs = topsText.staticText;
            self.clockFunctionControl = uicontrol( ...
                'Parent', self.figure, ...
                'Units', 'normalized', ...
                'Position', [right-width/2, yDiv-yGap, width/2, height], ...
                lookFeel{:}, labelArgs{:});
            
            cb = @(obj,event)topsDataLogGUI.groupsMenuCallback( ...
                obj, event, self);
            self.groupsMenu = uicontrol( ...
                'Parent', self.figure, ...
                'Units', 'normalized', ...
                'Position', [xDiv-width, yDiv-yGap, width, height], ...
                'Callback', cb, ...
                'Style', 'popupmenu', ...
                'String', {'groups'}, ...
                'HorizontalAlignment', 'left');
            
            lookFeel = self.detailPanel.getLookAndFeelForValue('regexp');
            editArgs = topsText.editText;
            cb = @(obj,event)topsDataLogGUI.groupsRegexpCallback( ...
                obj, event, self);
            self.groupsRegexp = uicontrol( ...
                'Parent', self.figure, ...
                'Units', 'normalized', ...
                'Position', [left, yDiv-yGap, width/2, height], ...
                'Callback', cb, ...
                lookFeel{:}, editArgs{:});
            
            self.groupsGrid = ScrollingControlGrid( ...
                self.figure, [left, bottom, xDiv-left, yDiv-yGap-bottom]);
            self.addScrollableChild( ...
                self.groupsGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, ...
                self.groupsGrid});
        end
        
        function plotRaster(self)
            h = [self.groupTexts, self.groupLines];
            delete(h(ishandle(h)));
            self.groupTexts = [];
            self.groupLines = [];
            
            if isempty(self.groupsGrid.controls)
                return
            end
            
            toggles = self.groupsGrid.controls(:,1);
            toggleValues = get(toggles, {'Value'});
            ignoreGroups = [toggleValues{:}];
            rasterGroups = self.selectedGroups(~ignoreGroups);
            
            n = numel(rasterGroups);
            if n > 0 && all(isfinite(self.tLim))
                log = topsDataLog.theDataLog;
                tLim = self.tLim;
                
                set(self.rasterAxes, ...
                    'XLim', tLim, ...
                    'YLim', [0, n*2+1]);
                set(self.rasterCursor, ...
                    'XData', 0, ...
                    'YData', -1);
                
                texts = zeros(1, n);
                lines = zeros(1, n);
                for ii = 1:n
                    row = 2*(n-ii+1);
                    
                    group = rasterGroups{ii};
                    groupColor = self.detailPanel.getColorForString(group);
                    texts(ii) = text(tLim(1), row, group, ...
                        'Parent', self.rasterAxes, ...
                        'Color', groupColor, ...
                        'FontSize', 9, ...
                        'HitTest', 'off');
                    
                    groupData = log.getAllItemsFromGroupAsStruct(group);
                    times = [groupData.mnemonic];
                    rows = (row-1)*ones(size(times));
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
                self.groupTexts = texts;
                self.groupLines = lines;
            end
        end
        
        function selectGroup(self, group)
            log = topsDataLog.theDataLog;
            
            if strcmp(group, self.allGroups)
                self.selectedGroups = log.groups;
                self.groupsGrid.deleteAllControls;
                for ii = 1:length(self.selectedGroups)
                    self.controlsForGroupAtRow(self.selectedGroups{ii}, ii);
                end
                
            else
                selector = strcmp(group, log.groups);
                if any(selector)
                    isSelected = any(strcmp(self.selectedGroups, group));
                    if ~isSelected
                        n = numel(self.selectedGroups);
                        self.selectedGroups{n+1} = group;
                        self.controlsForGroupAtRow(group, n+1);
                    end
                    
                else
                    self.groupsGrid.deleteAllControls;
                    self.selectedGroups = {};
                    group = self.noGroup;
                end
            end
            
            menu = cat(2, self.allGroups, self.noGroup, log.groups);
            value = find(strcmp(group, menu));
            set(self.groupsMenu, 'String', menu, 'Value', value);
            
            self.groupsGrid.repositionControls;
            self.plotRaster;
            drawnow;
        end
        
        function controlsForGroupAtRow(self, group, row)
            cb = @(obj,event)topsDataLogGUI.gridCallback(obj, event, self);
            toggle = topsText.toggleTextWithCallback(cb);
            lookFeel = self.detailPanel.getLookAndFeelForValue(group);
            self.groupsGrid.newControlAtRowAndColumn( ...
                row, [1 5], toggle{:}, lookFeel{:});
        end
        
        function set.tLim(self, tLim)
            if isnumeric(tLim) && numel(tLim) >= 2
                self.tLim = tLim([1,end]);
            else
                log = topsDataLog.theDataLog;
                self.tLim = [log.earliestTime, log.latestTime];
            end
            
            set(self.tLimControl, ...
                'String', summarizeValue(self.tLim, 30));
            
            
            if all(isfinite(self.tLim))
                set(self.rasterAxes, ...
                    'XLim', self.tLim);
                
                if ~isempty(self.groupTexts)
                    textPos = get(self.groupTexts, {'Position'});
                    textPosMatrix = cat(1, textPos{:});
                    textPosMatrix(:,1) = self.tLim(1);
                    newTextPos = num2cell(textPosMatrix, 2);
                    set(self.groupTexts, {'Position'}, newTextPos);
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
            catch err
                disp(sprintf('%s.tLim edit failed:', mfilename))
                disp(err)
                tLim = [];
            end
            self.tLim = tLim;
        end
        
        function groupsMenuCallback(obj, event, self)
            groups = get(obj, 'String');
            index = get(obj, 'Value');
            self.selectGroup(groups{index});
        end
        
        function groupsRegexpCallback(obj, event, self)
            exp = get(obj, 'String');
            log = topsDataLog.theDataLog;
            matches = log.getGroupNamesMatchingExpression(exp);
            for ii = 1:length(matches)
                self.selectGroup(matches{ii});
            end
        end
        
        function gridCallback(obj, event, self)
            self.plotRaster;
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