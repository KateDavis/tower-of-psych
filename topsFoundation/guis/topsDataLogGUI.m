classdef topsDataLogGUI < topsGUI
    properties
        viewStart=0;
        viewLength=0;
        viewIsSliding;
        replayStartTime;
        replayEndTime;
    end
    
    properties(Hidden)
        mnemonics;
        
        dataLogTexts;
        accumulatorCount;
        dataLogCount;
        
        replayButton;
        replayStartInput;
        replayDelimiter;
        replayEndInput;
        replayAllButton;
        
        viewSlideToggle;
        viewLengthInput;
        viewAllToggle;
        viewStartSlider;
        
        mnemonicLabel;
        mnemonicNoTriggerButton;
        mnemonicPlotAllButton;
        
        accumulatorAxes;
        dataLogAxes;
        mnemonicsGrid;
        mnemonicsWidth=4;
        stickyPeg;
    end
    
    methods
        function self = topsDataLogGUI()
            self = self@topsGUI;
            self.title = 'Data Log Viewer';
            
            self.createWidgets;
            
            self.setReplayEntireLog;
            
            self.mnemonics = {};
            self.viewStart = 0;
            self.viewLength = self.biggerThanEps;
            self.viewIsSliding = false;
            self.stickyPeg = false;
            
            self.listenToDataLog;
        end
        
        function replayDataLog(self)
            set(self.dataLogTexts, 'Visible', 'off');
            
            self.dataLogCount = 0;
            self.accumulatorCount = 0;
            self.isBusy = true;
            
            self.stickyPeg = self.viewSliderIsPegged;
            
            % replay the log, within bounds
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
            
            self.stickyPeg = false;
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
            logEntry = eventData.UserData;
            
            % trigger and ignore selections
            z = size(self.mnemonicsGrid.controls);
            if z(1) > 1
                allTrig = get(self.mnemonicsGrid.controls(:,1), 'Value');
                trig = logical([allTrig{2:end}]);
                allIgnore = get(self.mnemonicsGrid.controls(:,self.mnemonicsWidth+1), 'Value');
                ignore = logical([allIgnore{2:end}]);
            else
                trig = false;
                ignore = false;
            end
            
            % what are the view start and length?
            %   they depend on sliding and triggering
            if self.viewIsSliding
                if any(trig)
                    if any(strcmp(self.mnemonics(trig), logEntry.mnemonic))
                        self.trigger(logEntry);
                        self.viewStart = logEntry.time;
                    end
                elseif self.viewSliderIsPegged
                    % keep sliding
                    self.viewStart = logEntry.time-self.viewLength;
                end
            else
                % get bounds from user inputs or the dataLog
                [self.viewStart, self.viewLength] = self.getFullReplaySize;
            end
            
            % plot this log entry?
            if ~any(ignore) || ~any(strcmp(self.mnemonics(ignore), logEntry.mnemonic))
                self.plotLogEntry(logEntry);
            end
        end
        
        function trigger(self, logEntry)
            textToMove = self.dataLogTexts(self.accumulatorCount+1:self.dataLogCount);
            if ~isempty(textToMove)
                if length(textToMove) == 1
                    p = get(textToMove, 'Position');
                    p(2) = p(2) - self.viewStart;
                    pCell = {p};
                elseif length(textToMove) > 1
                    pCell = get(textToMove, 'Position');
                    p = vertcat(pCell{:});
                    p(:,2) = p(:,2) - self.viewStart;
                    pCell = mat2cell(p, ones(1,size(p,1)));
                end
                set(textToMove, ...
                    'Parent', self.accumulatorAxes, ...
                    {'Position'}, pCell, ...
                    'String', '---');
                self.accumulatorCount = self.dataLogCount;
            end
        end
        
        function clearAccumulator(self)
            set(self.dataLogTexts(1:self.accumulatorCount), ...
                'Visible', 'off');
        end
        
        function plotLogEntry(self, logEntry)
            summary = sprintf('--- %s', logEntry.mnemonic);
            set(self.nextText, ...
                'Parent', self.dataLogAxes, ...
                'Color', self.getColorForString(logEntry.mnemonic), ...
                'Position', [0, logEntry.time], ...
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
            self.replayDataLog;
        end
        
        function createWidgets(self)
            self.setupFigure;
            
            self.dataLogTexts = [];
            self.dataLogCount = 0;
            self.accumulatorCount = 0;
            
            left = 0;
            right = 1;
            xDiv = .6;
            width = .025;
            
            bottom = 0.01;
            top = .99;
            yDiv = .85*(top-bottom);
            height = .05;
            
            % custom widget class, in tops/utilities
            self.mnemonicsGrid = ScrollingControlGrid( ...
                self.figure, [xDiv, bottom, right-xDiv, yDiv]);
            
            self.addScrollableChild(self.mnemonicsGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, self.mnemonicsGrid});
            
            self.mnemonicNoTriggerButton = self.mnemonicsGrid.newControlAtRowAndColumn( ...
                1, [1 self.mnemonicsWidth], ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', '(no trigger)', ...
                'Callback', @(obj, event)set(self.mnemonicsGrid.controls(:,1), 'Value', false), ...
                'HorizontalAlignment', 'left', ...
                'Value', false);
            
            self.mnemonicPlotAllButton = self.mnemonicsGrid.newControlAtRowAndColumn( ...
                1, self.mnemonicsWidth+1, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', '(none)', ...
                'Callback', @(obj, event)set(self.mnemonicsGrid.controls(:,self.mnemonicsWidth+1), 'Value', false), ...
                'HorizontalAlignment', 'left', ...
                'Value', false);
            
            % view controls for the axes
            h = height;
            y = top-height;
            w = 6*width;
            x = xDiv;
            self.viewSlideToggle = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'togglebutton', ...
                'Units', 'normalized', ...
                'String', 'Sliding view:', ...
                'Callback', {@topsDataLogGUI.viewIsSlidingFromTogle, self}, ...
                'Position', [x, y, w, h], ...
                'HorizontalAlignment', 'left');
            
            x = x + w;
            w = 4*width;
            self.viewLengthInput = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'edit', ...
                'BackgroundColor', [1 1 1], ...
                'Callback', {@topsDataLogGUI.valueFromInput, self}, ...
                'Units', 'normalized', ...
                'Position', [x, y, w, h], ...
                'HorizontalAlignment', 'left', ...
                'Enable', 'on');
            
            w = 4*width;
            x = right-w;
            self.viewAllToggle = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'togglebutton', ...
                'Units', 'normalized', ...
                'String', 'view all', ...
                'Callback', {@topsDataLogGUI.viewIsSlidingFromTogle, self}, ...
                'Position', [x, y, w, h], ...
                'HorizontalAlignment', 'left');
            
            
            % replay the data log into the GUI
            y = top - 2.5*height;
            x = xDiv;
            w = 4*width;
            self.replayButton = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'Replay:', ...
                'Callback', @(obj, event) self.replayDataLog, ...
                'Position', [x, y, w, h], ...
                'HorizontalAlignment', 'left');
            
            x = x + w;
            w = 4*width;
            self.replayStartInput = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'edit', ...
                'BackgroundColor', [1 1 1], ...
                'Callback', {@topsDataLogGUI.valueFromInput, self}, ...
                'Units', 'normalized', ...
                'Position', [x, y, w, h], ...
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
                'Position', [x, y, w, h], ...
                'HorizontalAlignment', 'center');
            
            x = x + w;
            w = 4*width;
            self.replayEndInput = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'edit', ...
                'BackgroundColor', [1 1 1], ...
                'Callback', {@topsDataLogGUI.valueFromInput, self}, ...
                'Units', 'normalized', ...
                'Position', [x, y, w, h], ...
                'HorizontalAlignment', 'left', ...
                'Enable', 'on');
            
            w = 2*width;
            x = right - w;
            self.replayAllButton = uicontrol ( ...
                'Parent', self.figure, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'all', ...
                'Callback', @(obj,event)self.setReplayEntireLog, ...
                'Position', [x, y, w, h], ...
                'HorizontalAlignment', 'left');
            
            
            % axes for viewing
            axesOptions = { ...
                'Color', [1 1 1], ...
                'DrawMode', 'fast', ...
                'HitTest', 'on', ...
                'XTick', [], ...
                'YTick', [], ...
                'YLim', [0 self.biggerThanEps], ...
                'YLimMode', 'manual', ...
                'YDir', 'reverse', ...
                'Projection', 'orthographic'};
            
            self.accumulatorAxes = axes( ...
                'Parent', self.figure, ...
                'Box', 'on', ...
                'Position', [left, bottom, 2*width, top-bottom], ...
                'XLim', [0 .1], ...
                axesOptions{:});
            
            
            self.dataLogAxes = axes( ...
                'Parent', self.figure, ...
                'ButtonDownFcn', {@topsDataLogGUI.adjustReplayFromAxes, self}, ...
                'Box', 'off', ...
                'Position', [2*width, bottom, xDiv-3*width, top-bottom], ...
                'XLim', [0 1], ...
                axesOptions{:});
            
            self.addScrollableChild(self.dataLogAxes, ...
                {@topsDataLogGUI.viewStartFromScrollOrSlider, self});
            
            self.viewStartSlider = uicontrol( ...
                'Parent', self.figure, ...
                'Style', 'slider', ...
                'Units', 'normalized', ...
                'String', '', ...
                'Callback', {@topsDataLogGUI.viewStartFromScrollOrSlider, self}, ...
                'Position', [xDiv-width, bottom, width, top-bottom], ...
                'HorizontalAlignment', 'left', ...
                'Min', -1, ...
                'Max', 0, ...
                'Value', -1);
        end
        
        function repondToResize(self, figure, event)
            % attempt to resize with characters, rather than normalized
            self.mnemonicsGrid.repositionControls;
        end
        
        function updateAxesForView(self)
            vals = [self.viewStart, self.viewLength];
            if length(vals) == 2 && all(isfinite(vals)) && vals(2) > 0
                set(self.dataLogAxes, 'YLim', [vals(1), vals(1)+vals(2)]);
                set(self.accumulatorAxes, 'YLim', [0, vals(2)]);
            end
        end
        
        function updateSliderForView(self)
            [start, length] = self.getFullReplaySize;
            frac = (self.viewStart - start) / (length - self.viewLength);
            set(self.viewStartSlider, 'Value', -max(min(frac,1),0));
        end
        
        function isPegged = viewSliderIsPegged(self)
            isPegged = self.stickyPeg || get(self.viewStartSlider, 'Value') + 1 < .01;
        end
        
        function setReplayEntireLog(self)
            theLog = topsDataLog.theDataLog;
            self.replayStartTime = max(-inf, theLog.earliestTime);
            self.replayEndTime = max(inf, theLog.latestTime);
        end
        
        function [start, length] = getFullReplaySize(self)
            theLog = topsDataLog.theDataLog;
            if isfinite(self.replayStartTime)
                start = self.replayStartTime;
            else
                start = theLog.earliestTime;
            end
            
            if isfinite(self.replayEndTime)
                length = self.replayEndTime - start;
            else
                length = theLog.latestTime - start + self.biggerThanEps;
            end
        end
        
        function set.viewStart(self, viewStart)
            self.viewStart = viewStart;
            self.updateAxesForView;
            self.updateSliderForView;
        end
        
        function set.viewLength(self, viewLength)
            self.viewLength = viewLength;
            set(self.viewLengthInput, 'String', num2str(viewLength));
            self.updateAxesForView;
            self.updateSliderForView;
        end
        
        function set.viewIsSliding(self, viewIsSliding)
            self.viewIsSliding = viewIsSliding;
            enables = [self.viewStartSlider, self.viewLengthInput];
            if viewIsSliding
                set(self.viewAllToggle, 'Value', false);
                set(self.viewSlideToggle, 'Value', true);
                set(self.viewStartSlider, 'Value', -1);
                set(enables, 'Enable', 'on');
            else
                set(self.viewAllToggle, 'Value', true);
                set(self.viewSlideToggle, 'Value', false);
                set(enables, 'Enable', 'off');
            end
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
        function valueFromInput(input, event, self)
            value = str2num(get(input, 'String'));
            switch input
                case self.replayStartInput
                    self.replayStartTime = value;
                case self.replayEndInput
                    self.replayEndTime = value;
                case self.viewLengthInput
                    self.viewLength = value;
            end
        end
        
        function adjustReplayFromAxes(ax, event, self)
            point = get(ax, 'CurrentPoint');
            time = point(1,2);
            switch get(self.figure, 'SelectionType');
                case 'normal'
                    self.replayStartTime = time;
                case'extend'
                    self.replayEndTime = time;
            end
        end
        
        function viewStartFromScrollOrSlider(obj, event, self)
            frac = -get(self.viewStartSlider, 'Value');
            if isfield(event, 'VerticalScrollCount')
                % mouse scroll event
                scroll = .01*event.VerticalScrollCount;
                frac = max(min(frac + scroll, 1), 0);
            end
            [start, length] = self.getFullReplaySize;
            self.viewStart = frac*(length-self.viewLength) + start;
        end
        
        function viewIsSlidingFromTogle(toggle, event, self)
            value = get(toggle, 'Value');
            switch toggle
                case self.viewAllToggle
                    self.viewIsSliding = ~value;
                case self.viewSlideToggle
                    self.viewIsSliding = value;
            end
        end
    end
end