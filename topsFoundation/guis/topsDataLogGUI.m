classdef topsDataLogGUI < topsGUI
    properties
        intervalStart = 0;
        intervalLength = 1;
        replayStartTime = -inf;
        replayEndTime = inf;
    end
    
    properties(Hidden)
        mnemonics;
        mnemonicsWidth=4;
        
        intervalSliding;
        intervalGrowing;
        
        dataLogTexts;
        accumulatorCount;
        dataLogCount;
        
        replayButton;
        replayStartInput;
        replayDelimiter;
        replayEndInput;
        replayAllButton;
        
        intervalLabel;
        intervalLengthInput;
        intervalAutoButton;
        intervalStartSlider;
        
        mnemonicNoTriggerButton;
        mnemonicShowAllButton;
        
        accumulatorAxes;
        dataLogAxes;
        mnemonicsGrid;
    end
    
    methods
        function self = topsDataLogGUI()
            self = self@topsGUI;
            self.title = 'Data Log Viewer';
            self.createWidgets;
            self.listenToDataLog;
        end
        
        function replayEntireLog(self)
            set(self.dataLogTexts, 'Visible', 'off');
            
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
            
            self.deleteListeners;
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
            col = self.getColorForString(mnemonic);
            
            % a control for triggering, a control for hiding
            z = size(self.mnemonicsGrid.controls);
            h = self.mnemonicsGrid.newControlAtRowAndColumn( ...
                z(1)+1, [1 self.mnemonicsWidth], ...
                'Style', 'togglebutton', ...
                'String', mnemonic, ...
                'ForegroundColor', col);
            h = self.mnemonicsGrid.newControlAtRowAndColumn( ...
                z(1)+1, self.mnemonicsWidth+1, ...
                'Style', 'togglebutton', ...
                'String', 'hide', ...
                'ForegroundColor', col);
        end
        
        function hearNewData(self, theLog, eventData)
            logEntryStruct = eventData.UserData;
            
            % trigger and ignore selections
            z = size(self.mnemonicsGrid.controls);
            if z(1) == 1
                trig = logical(get(self.mnemonicsGrid.controls(1,1), 'Value'));
                ignore = logical(get(self.mnemonicsGrid.controls(1,self.mnemonicsWidth+1), 'Value'));
            elseif z(1) > 1
                allTrig = get(self.mnemonicsGrid.controls(:,1), 'Value');
                trig = logical([allTrig{:}]);
                allIgnore = get(self.mnemonicsGrid.controls(:,self.mnemonicsWidth+1), 'Value');
                ignore = logical([allIgnore{:}]);
            else
                trig = false;
                ignore = false;
            end
            
            % intervalStart and intervalLength depend on mode of operation:
            % intervalStart is either
            %   the time of the last triggering log entry
            %   left as is
            %   sliding, to accomodate all incoming log entries
            % intervalLength is either
            %   left as is
            %   doubled as needed to accomodate all incoming entries
            % there's a conflict between sliding the start vs. growing the
            % length.  Let sliding win.
            if any(trig)
                if any(strcmp(self.mnemonics(trig), logEntryStruct.mnemonic))
                    self.trigger(logEntryStruct);
                    self.intervalStart = logEntryStruct.time;
                end
            elseif self.intervalSliding
                self.intervalStart = logEntryStruct.time - self.intervalLength;
            end
            
            if self.intervalGrowing
                if logEntryStruct.time > (self.intervalStart + self.intervalLength)
                    self.intervalLength = self.intervalLength * 2;
                end
            end
            
            % ignore this log entry?
            if ~any(ignore) || ~any(strcmp(self.mnemonics(ignore), logEntryStruct.mnemonic))
                self.plotLogEntry(logEntryStruct);
            end
        end
        
        function trigger(self, logEntryStruct)
            textToMove = self.dataLogTexts(self.accumulatorCount+1:self.dataLogCount);
            if length(textToMove) == 1
                p = get(textToMove, 'Position');
                p(1) = p(1) - self.intervalStart;
                pCell = {p};
            elseif length(textToMove) > 1
                pCell = get(textToMove, 'Position');
                p = vertcat(pCell{:});
                p(:,1) = p(:,1) - self.intervalStart;
                pCell = mat2cell(p, ones(1,size(p,1)));
            end
            set(textToMove, ...
                'Parent', self.accumulatorAxes, ...
                {'Position'}, pCell, ...
                'String', '---');
            self.accumulatorCount = self.dataLogCount;
        end
        
        function clearAccumulator(self)
            set(self.dataLogTexts(1:self.accumulatorCount), ...
                'Visible', 'off');
        end
        
        function plotLogEntry(self, logEntryStruct)
            summary = sprintf('--- %s', logEntryStruct.mnemonic);
            set(self.nextText, ...
                'Parent', self.dataLogAxes, ...
                'Color', self.getColorForString(logEntryStruct.mnemonic), ...
                'Position', [0, logEntryStruct.time], ...
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
            
            self.dataLogTexts = [];
            self.dataLogCount = 0;
            self.accumulatorCount = 0;
            
            left = 0;
            right = 1;
            xDiv = .6;
            width = .025;
            
            bottom = 0;
            top = 1;
            yDiv = .95;
            
            x = left;
            w = 4*width;
            self.replayButton = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'Replay:', ...
                'Callback', @(obj, event) self.replayEntireLog, ...
                'Position', [x, yDiv, w, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            x = x + w;
            w = 3*width;
            self.replayStartInput = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'edit', ...
                'BackgroundColor', [1 1 1], ...
                'Callback', {@topsDataLogGUI.adjustReplayFromInput, self}, ...
                'Units', 'normalized', ...
                'Position', [x, yDiv, w, top-yDiv], ...
                'HorizontalAlignment', 'left', ...
                'Enable', 'on');
            
            x = x + w;
            w = 2*width;
            self.replayDelimiter = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'text', ...
                'BackgroundColor', get(self.figure, 'Color'), ...
                'Units', 'normalized', ...
                'String', 'thru', ...
                'Position', [x, yDiv, w, top-yDiv], ...
                'HorizontalAlignment', 'center');
            
            x = x + w;
            w = 3*width;
            self.replayEndInput = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'edit', ...
                'BackgroundColor', [1 1 1], ...
                'Callback', {@topsDataLogGUI.adjustReplayFromInput, self}, ...
                'Units', 'normalized', ...
                'Position', [x, yDiv, w, top-yDiv], ...
                'HorizontalAlignment', 'left', ...
                'Enable', 'on');
            
            x = x + w;
            w = 2*width;
            self.replayAllButton = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'all', ...
                'Callback', {@topsDataLogGUI.adjustReplayAll, self}, ...
                'Position', [x, yDiv, w, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            
            w = 3*width;
            x = xDiv-w;
            self.intervalLengthInput = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'edit', ...
                'BackgroundColor', [1 1 1], ...
                'Callback', {@topsDataLogGUI.intervalLengthFromInput, self}, ...
                'Units', 'normalized', ...
                'Position', [x, yDiv, w, top-yDiv], ...
                'HorizontalAlignment', 'left', ...
                'Enable', 'off');
            
            w = 4*width;
            x = x - w;
            self.intervalAutoButton = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'togglebutton', ...
                'Units', 'normalized', ...
                'String', 'View:', ...
                'Callback', {@topsDataLogGUI.intervalGrowingFromToggle, self}, ...
                'Position', [x, yDiv, w, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            
            w = 5*width;
            x = right-w;
            self.mnemonicShowAllButton = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'show all', ...
                'Callback', @(obj, event)set(self.mnemonicsGrid.controls(:,self.mnemonicsWidth+1), 'Value', false), ...
                'Position', [x, yDiv, w, top-yDiv], ...
                'HorizontalAlignment', 'center');
            
            x = xDiv + 3*width;
            w = 5*width;
            self.mnemonicNoTriggerButton = uicontrol( ...
                'Parent', self.figure, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'no trigger', ...
                'Callback', @(obj, event)set(self.mnemonicsGrid.controls(:,1), 'Value', false), ...
                'Position', [x, yDiv, w, top-yDiv], ...
                'HorizontalAlignment', 'left');
            
            
            self.accumulatorAxes = axes( ...
                'Parent', self.figure, ...
                'Box', 'on', ...
                'ButtonDownFcn', {@topsDataLogGUI.adjustReplayFromAxes, self}, ...
                'Color', [1 1 1], ...
                'DrawMode', 'fast', ...
                'HitTest', 'on', ...
                'Position', [left, bottom, 2*width, yDiv], ...
                'XTick', [], ...
                'XLim', [0 .1], ...
                'YTick', [], ...
                'YLim', [0 1], ...
                'YDir', 'reverse');
            
            self.dataLogAxes = axes( ...
                'Parent', self.figure, ...
                'Box', 'off', ...
                'ButtonDownFcn', {@topsDataLogGUI.adjustReplayFromAxes, self}, ...
                'Color', [1 1 1], ...
                'DrawMode', 'fast', ...
                'HitTest', 'on', ...
                'Position', [2*width, bottom, xDiv-3*width, yDiv], ...
                'XTick', [], ...
                'XLim', [0 1], ...
                'YTick', [], ...
                'YLim', [0 1], ...
                'YDir', 'reverse');
            
            self.intervalStartSlider = uicontrol( ...
                'Parent', self.figure, ...
                'Style', 'slider', ...
                'Units', 'normalized', ...
                'String', '', ...
                'Callback', {@topsDataLogGUI.intervalStartFromSlider, self}, ...
                'Position', [xDiv-width, bottom, width, yDiv], ...
                'HorizontalAlignment', 'left', ...
                'Min', -1, ...
                'Max', 0, ...
                'Value', -1);
            
            % custom widget class, in tops/utilities
            self.mnemonicsGrid = ScrollingControlGrid( ...
                self.figure, [xDiv, bottom, right-xDiv, yDiv]);
            
            % trigger mutators to update new controls
            theLog = topsDataLog.theDataLog;
            self.intervalStart = theLog.earliestTime;
            self.intervalLength = theLog.latestTime;
            self.replayStartTime = -inf;
            self.replayEndTime = inf;
        end
        
        function repondToResize(self, figure, event)
            % attempt to resize with characters, rather than normalized
            self.mnemonicsGrid.repositionControls;
        end
        
        function limitAxesToInterval(self)
            interval = [0 self.intervalLength];
            set(self.dataLogAxes, 'YLim', interval + self.intervalStart);
            set(self.accumulatorAxes, 'YLim', interval);
        end
        
        function set.intervalStart(self, intervalStart)
            self.intervalStart = intervalStart;
            theLog = topsDataLog.theDataLog;
            self.limitAxesToInterval;

            frac = (intervalStart - theLog.earliestTime) / (theLog.latestTime - theLog.earliestTime);
            if isfinite(frac)
                set(self.intervalStartSlider, 'Value', -frac);
            end
        end
        
        function set.intervalLength(self, intervalLength)
            self.intervalLength = intervalLength;
            set(self.intervalLengthInput, 'String', num2str(intervalLength));
            self.limitAxesToInterval;
        end
        
        function set.replayStartTime(self, replayStartTime)
            self.replayStartTime = replayStartTime;
            set(self.replayStartInput, 'String', num2str(replayStartTime));
        end
        
        function set.replayEndTime(self, replayEndTime)
            self.replayEndTime = replayEndTime;
            set(self.replayEndInput, 'String', num2str(replayEndTime));
        end
    end
    
    methods(Static)
        function adjustReplayFromInput(input, event, self)
            value = str2num(get(input, 'String'));
            switch input
                case self.replayStartInput
                    self.replayStartTime = value;
                case self.replayEndInput
                    self.replayEndTime = value;
            end
        end
        
        function adjustReplayFromAxes(ax, event, self)
            point = get(ax, 'CurrentPoint');
            time = point(1,2) + self.intervalStart;
            switch get(self.figure, 'SelectionType');
                case 'normal'
                    self.replayStartTime = time;
                case'extend'
                    self.replayEndTime = time;
            end
        end
        
        function adjustReplayAll(button, event, self)
            self.replayStartTime = -inf;
            self.replayEndTime = inf;
        end
        
        function intervalStartFromSlider(slider, event, self)
            frac = -get(slider, 'Value');
            theLog = topsDataLog.theDataLog;
            start = (1-frac)*theLog.earliestTime + frac*theLog.latestTime;
            if isfinite(start)
                self.intervalStart = start;
            end
            
            % slide the axes view this slider is at the bottom
            self.intervalSliding = frac == 1;
        end
        
        function intervalGrowingFromToggle(toggle, event, self)
            if get(toggle, 'Value')
                set(self.intervalLengthInput, 'Enable', 'on');
                self.intervalLength = str2num(get(self.intervalLengthInput, 'String'));
                self.intervalGrowing = false;
            else
                set(self.intervalLengthInput, 'Enable', 'off');
                self.intervalGrowing = true;
            end
        end
        
        function intervalLengthFromInput(input, event, self)
            self.intervalLength = str2num(get(input, 'String'));
        end
    end
end