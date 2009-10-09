classdef topsDataLogGUI < handle
    properties
        figure;
        isBusy = false;
        
        timeZero = 0;
        timeInterval = eps;
        
        replayStartTime = -inf;
        replayEndTime = inf;
    end
    
    properties(Hidden)
        mnemonicsNoTrig;
        mnemonicsGrid;
        mnemonics;
        
        accumulatorAxes;
        accumulatorCount = 0;
        
        dataLogAxes;
        dataLogReplayButton;
        
        dataLogTexts;
        dataLogCount = 0;
        
        replayStartSlider;
        replayEndSlider;
        replayAllButton;
        
        listeners = struct();
        
        title = 'Data Log Viewer';
        busyTitle = 'Data Log Viewer (busy...)';
        colors = spacedColors(61);
    end
    
    methods
        function self = topsDataLogGUI()
            self.createWidgets;
            %self.replayEntireLog;
            self.listenToDataLog;
        end
        
        function delete(self)
            if ~isempty(self.figure) && ishandle(self.figure);
                delete(self.figure);
            end
            delete(struct2array(self.listeners));
        end
        
        function set.isBusy(self, isBusy)
            self.isBusy = isBusy;
            if isBusy
                set(self.figure, 'Name', self.busyTitle);
            else
                set(self.figure, 'Name', self.title);
            end
            drawnow;
        end
        
        function c = hashColorForMnemonic(self, mnemonic)
            hash = 1 + mod(sum(mnemonic), size(self.colors,1));
            c = self.colors(hash, :);
        end
        
        function replayEntireLog(self)
            set(self.dataLogTexts, 'Visible', 'off');
            self.timeInterval = eps;
            self.dataLogCount = 0;
            self.accumulatorCount = 0;
            self.isBusy = true;
            
            % replay events within replay window
            theLog = topsDataLog.theDataLog;
            entireLogStruct = theLog.getAllDataSorted;
            t = [entireLogStruct.time];
            replayWindow = (t >= self.replayStartTime) & (t <= self.replayEndTime);
            ed = EventWithData;
            for ii = find(replayWindow);
                % look for new mnemonics as they come
                m = entireLogStruct(ii).mnemonic;
                if ~any(strcmp(self.mnemonics, m))
                    ed.UserData = m;
                    self.hearNewMnemonic(theLog, ed)
                end
                
                % read all data as they come
                ed.UserData = entireLogStruct(ii);
                self.hearNewData(theLog, ed);
            end
            self.isBusy = false;
        end
        
        function listenToDataLog(self)
            theLog = topsDataLog.theDataLog;
            self.timeZero = theLog.earliestTime;
            
            delete(struct2array(self.listeners))
            self.listeners.NewMnemonic = theLog.addlistener( ...
                'NewMnemonic', ...
                @(source, event) self.hearNewMnemonic(source, event));
            self.listeners.NewData = theLog.addlistener( ...
                'NewData', ...
                @(source, event) self.hearNewData(source, event));
            self.listeners.FlushedTheDataLog = theLog.addlistener( ...
                'FlushedTheDataLog', ...
                @(source, event) self.hearFlushedTheDataLog(source, event));
        end
        
        function hearNewMnemonic(self, theLog, event)
            mnemonic = event.UserData;
            self.mnemonics{end+1} = mnemonic;
            hashColor = self.hashColorForMnemonic(mnemonic);
            
            % a control for triggering, a control for hiding
            z = size(self.mnemonicsGrid.controls);
            h = self.mnemonicsGrid.newControlAtRowAndColumn( ...
                z(1)+1, 1, ...
                'Style', 'togglebutton', ...
                'String', mnemonic, ...
                'ForegroundColor', hashColor);
            h = self.mnemonicsGrid.newControlAtRowAndColumn( ...
                z(1)+1, 2, ...
                'Style', 'togglebutton', ...
                'String', 'hide', ...
                'ForegroundColor', hashColor);
        end
        
        function fixListSelectionsAfterInsert(self, list, insert)
            selected = get(list, 'Value');
            bump = selected >= insert;
            selected(bump) = selected(bump) + 1;
            set(list, 'Value', selected);
        end
        
        function hearNewData(self, theLog, eventData)
            logEntryStruct = eventData.UserData;
            
            % doing triggering or ignoring?
            z = size(self.mnemonicsGrid.controls);
            if z(1) == 1
                trig = logical(get(self.mnemonicsGrid.controls(1,1), 'Value'));
                ignore = logical(get(self.mnemonicsGrid.controls(1,2), 'Value'));
            elseif z(1) > 1
                allTrig = get(self.mnemonicsGrid.controls(:,1), 'Value');
                trig = logical([allTrig{:}]);
                allIgnore = get(self.mnemonicsGrid.controls(:,2), 'Value');
                ignore = logical([allIgnore{:}]);
            else
                trig = false;
                ignore = false;
            end
            
            if any(trig)
                if any(strcmp(self.mnemonics(trig), logEntryStruct.mnemonic))
                    % retrigger
                    self.trigger(logEntryStruct);
                end
            else
                if isfinite(self.replayStartTime)
                    self.timeZero = self.replayStartTime;
                else
                    self.timeZero = theLog.earliestTime;
                end
            end
            
            if ~any(ignore) || ~any(strcmp(self.mnemonics(ignore), logEntryStruct.mnemonic))
                self.plotLogEntry(logEntryStruct);
            end
        end
        
        function trigger(self, logEntryStruct)
            set(self.dataLogTexts(self.accumulatorCount+1:self.dataLogCount), ...
                'Parent', self.accumulatorAxes, ...
                'String', '---');
            self.accumulatorCount = self.dataLogCount;
            self.timeZero = logEntryStruct.time;
        end
        
        function clearAccumulator(self)
            set(self.dataLogTexts(1:self.accumulatorCount), ...
                'Visible', 'off');
        end
        
        function plotLogEntry(self, logEntryStruct)
            % adjust axes bounds for new data
            y = logEntryStruct.time - self.timeZero;
            if y > self.timeInterval
                self.timeInterval = 2*y;
                set([self.dataLogAxes self.accumulatorAxes], ...
                    'YLim', [0 self.timeInterval]);
            end
            
            summary = sprintf('--- %s', logEntryStruct.mnemonic);
            set(self.nextText, ...
                'Parent', self.dataLogAxes, ...
                'Color', self.hashColorForMnemonic(logEntryStruct.mnemonic), ...
                'Position', [0, y], ...
                'String', summary, ...
                'Visible', 'on');
        end
        
        function t = nextText(self)
            if self.dataLogCount >= length(self.dataLogTexts)
                n = max(100, self.dataLogCount);
                newTexts = text(zeros(1,n), zeros(1,n), '', ...
                    'Parent', self.dataLogAxes, ...
                    'Visible', 'off', ...
                    'EraseMode', 'background', ...
                    'FontName', 'Courier', ...
                    'HitTest', 'off', ...
                    'Interpreter', 'none', ...
                    'VerticalAlignment', 'middle', ...
                    'HorizontalAlignment', 'left');
                self.dataLogTexts = cat(1, self.dataLogTexts, newTexts);
            end
            n = self.dataLogCount + 1;
            t = self.dataLogTexts(n);
            self.dataLogCount = n;
        end
        
        function hearFlushedTheDataLog(self, theLog, eventData)
            self.replayEntireLog;
        end
        
        function createWidgets(self)
            self.setupFigure;
            
            self.mnemonics = {};
            self.timeInterval = eps;
            self.replayStartTime = -inf;
            self.replayEndTime = inf;
            
            self.dataLogTexts = [];
            self.dataLogCount = 0;
            self.accumulatorCount = 0;
            
            left = 0;
            right = 1;
            xDiv = .6;
            bottom = 0;
            top = 1;
            yDiv = .95;
            width = .05;
            self.accumulatorAxes = axes( ...
                'Parent', self.figure, ...
                'Box', 'on', ...
                'ButtonDownFcn', {@topsDataLogGUI.adjustReplayFromAxes, self}, ...
                'Color', [1 1 1], ...
                'DrawMode', 'fast', ...
                'HitTest', 'on', ...
                'Position', [left, bottom, width, top], ...
                'XTick', [], ...
                'XLim', [0 .1], ...
                'YTick', [], ...
                'YLim', [0 eps], ...
                'YDir', 'reverse');
            
            self.dataLogAxes = axes( ...
                'Parent', self.figure, ...
                'Box', 'off', ...
                'ButtonDownFcn', {@topsDataLogGUI.adjustReplayFromAxes, self}, ...
                'Color', [1 1 1], ...
                'DrawMode', 'fast', ...
                'HitTest', 'on', ...
                'Position', [width, bottom, xDiv-2*width, top], ...
                'XTick', [], ...
                'XLim', [0 1], ...
                'YTick', [], ...
                'YLim', [0 eps], ...
                'YDir', 'reverse');
            
            self.replayStartSlider = uicontrol( ...
                'Parent', self.figure, ...
                'Style', 'slider', ...
                'Units', 'normalized', ...
                'String', '', ...
                'Callback', {@topsDataLogGUI.adjustReplayFromSlider, self}, ...
                'Position', [xDiv-width, bottom, width/2, yDiv], ...
                'HorizontalAlignment', 'left', ...
                'Min', -1, ...
                'Max', 0, ...
                'Value', 0);
            
            self.replayEndSlider = uicontrol( ...
                'Parent', self.figure, ...
                'Style', 'slider', ...
                'Units', 'normalized', ...
                'String', '', ...
                'Callback', {@topsDataLogGUI.adjustReplayFromSlider, self}, ...
                'Position', [xDiv-width/2, bottom, width/2, yDiv], ...
                'HorizontalAlignment', 'left', ...
                'Min', -1, ...
                'Max', 0, ...
                'Value', -1);
            
            self.replayAllButton = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'all', ...
                'Callback', {@topsDataLogGUI.adjustReplayAll, self}, ...
                'Position', [xDiv-width, yDiv, width, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            % custom widget class, in tops/utilities
            self.mnemonicsGrid = ScrollingControlGrid( ...
                self.figure, [xDiv, bottom, right-xDiv, yDiv]);
            
            self.mnemonicsNoTrig = uicontrol( ...
                'Parent', self.figure, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'no trig', ...
                'Callback', @(obj, event) set(self.mnemonicsGrid.controls(:,1), 'Value', false), ...
                'Position', [xDiv+width, yDiv, width*2, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            self.dataLogReplayButton = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'replay', ...
                'Callback', @(obj, event) self.replayEntireLog, ...
                'Position', [right-2*width, yDiv, 2*width, top-yDiv], ...
                'HorizontalAlignment', 'left');
        end
        
        function setupFigure(self)
            if ~isempty(self.figure) && ishandle(self.figure)
                clf(self.figure)
            else
                self.figure = figure;
            end
            set(self.figure, ...
                'CloseRequestFcn', @(obj, event) delete(self), ...
                'Renderer', 'zbuffer', ...
                'HandleVisibility', 'on', ...
                'MenuBar', 'none', ...
                'Name', self.title, ...
                'NumberTitle', 'off', ...
                'ToolBar', 'none');
        end
    end
    
    methods(Static)
        function adjustReplayFromSlider(slider, event, self)
            frac = -get(slider, 'Value');
            theLog = topsDataLog.theDataLog;
            time = (1-frac)*theLog.earliestTime + frac*theLog.latestTime;
            
            if slider==self.replayStartSlider
                self.replayStartTime = time;
            elseif slider==self.replayEndSlider
                self.replayEndTime = time;
            end
        end
        
        function adjustReplayFromAxes(ax, event, self)
            point = get(ax, 'CurrentPoint');
            time = point(1,2) + self.timeZero;
            theLog = topsDataLog.theDataLog;
            frac = (time-theLog.earliestTime)/(theLog.latestTime-theLog.earliestTime);
            
            clickType = get(self.figure, 'SelectionType');
            if strcmp(clickType, 'normal')
                self.replayStartTime = time;
                set(self.replayStartSlider, 'Value', -frac);
            elseif strcmp(clickType, 'extend')
                self.replayEndTime = time;
                set(self.replayEndSlider, 'Value', -frac);
            end
        end
        
        function adjustReplayAll(button, event, self)
            self.replayStartTime = -inf;
            self.replayEndTime = inf;
            set(self.replayStartSlider, 'Value', 0);
            set(self.replayEndSlider, 'Value', -1);
        end
    end
end