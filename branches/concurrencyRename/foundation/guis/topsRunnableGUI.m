classdef topsRunnableGUI < topsGUI
    % @class topsRunnableGUI
    % Visualize the structure of topsRunnable objects.
    % topsRunnableGUI shows you hiererchy of topsRunnable objects that
    % make up an experiment, especially topsRunnableComposite objects,
    % which form a tree structure.
    % @details
    % On the left it shows you a browser with a button for each
    % topsRunnable object.  The topmost runnable appears at the upper left
    % corner.  If it's a composite runnable, its children are indented and
    % displayed below it.  Likewise, their children may be indented
    % further, and so on.
    % @details
    % You can click on an individual button to view a runnable in detail,
    % on the right.
    % @details
    % At the top right, the "run" button allows you to invoke the
    % run() method of the currently displayed runnable.  It might only make
    % sense to invoke run() on the topmost runnable.
    % @details
    % You can launch topsRunnableGUI with the topsRunnableGUI()
    % constructor, or with the gui() method any topsRunnable object.
    % @details
    % topsRunnableGUI uses listeners to detect changes to the objects it's
    % showing.  This means that you can view your objects as you work on
    % your experiment, and you don't have to reopen or refresh the GUI.
    % @details
    % But beware that listeners can slow Matlab down.  So if you're in a
    % timing-critical situation, like running a real experiment, you might
    % wish to close the GUI, deleting its listeners.
    % @ingroup foundation
    
    properties
        % The topmost topsRunnable object to visualize in the GUI.
        topLevelRunnable;
        
        % The topsRunnable object whose details are currently displayed.
        currentRunnable;
    end
    
    properties(Hidden)
        heirarchyGrid;
        detailsPanel;
        runButton;
        runnablesCount;
        structuralProps = {'children', 'name'};
    end
    
    methods
        % Constructor takes one optional argument
        % @param topLevelRunnable a topsRunnable object to visualize, along
        % with any children
        % @details
        % Returns a handle to the new topsRunnableGUI.  If
        % @a topLevelRunnable is missing, the GUI will launch but no
        % data will be shown.
        function self = topsRunnableGUI(topLevelRunnable)
            self = self@topsGUI;
            self.title = 'Runnables GUI';
            self.createWidgets;
            
            if nargin
                self.topLevelRunnable = topLevelRunnable;
                self.repopulateHeirarchyGrid;
                self.detailsForRunnable(topLevelRunnable);
            end
        end
        
        function createWidgets(self)
            left = 0;
            right = 1;
            bottom = 0;
            top = 1;
            xDiv = .4;
            xGap = .05;
            yDiv = .95;
            
            % custom widget class, in tops/utilities
            self.heirarchyGrid = ScrollingControlGrid( ...
                self.figure, [left, bottom, xDiv-left, yDiv-bottom]);
            self.addScrollableChild(self.heirarchyGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, ...
                self.heirarchyGrid});
            
            self.detailsPanel = topsValuePanel(self, ...
                [xDiv+xGap, bottom, right-xDiv-xGap, yDiv-bottom]);
            self.detailsPanel.stringSummaryLength = 40;
            
            w = .2;
            self.runButton = uicontrol( ...
                'Parent', self.figure, ...
                'Callback', @(obj, event)self.runCurrentRunnable, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'run()', ...
                'Position', [right-w, yDiv, w, top-yDiv], ...
                'HorizontalAlignment', 'center');
        end
        
        function detailsForRunnable(self, runnable, button)
            self.currentRunnable = runnable;
            
            if nargin > 2
                obj = self.heirarchyGrid.controls;
                topsText.toggleOff(obj(ishandle(obj) & obj > 0));
                topsText.toggleOn(button);
            end
            
            self.detailsPanel.populateWithValueDetails(runnable);
        end
        
        % Invoke the run() method of the current runnable.
        function runCurrentRunnable(self)
            self.currentRunnable.run;
        end
        
        function repopulateHeirarchyGrid(self)
            % delete all listeners and controls
            self.deleteListeners;
            self.heirarchyGrid.deleteAllControls;
            
            self.runnablesCount = 0;
            depth = 1;
            self.addRunnableAtDepth(self.topLevelRunnable, depth);
            self.heirarchyGrid.repositionControls;
        end
        
        function addRunnableAtDepth(self, runnable, depth, format)
            if nargin < 4 || isempty(format)
                format = '%s';
            end
            
            self.runnablesCount = self.runnablesCount + 1;
            
            if isa(runnable, 'topsRunnable')
                % add this runnable
                toggle = topsText.toggleText;
                lookFeel = self.detailsPanel.getLookAndFeelForValue( ...
                    runnable.name);
                self.heirarchyGrid.newControlAtRowAndColumn( ...
                    self.runnablesCount, [0 5]+depth, ...
                    toggle{:}, ...
                    lookFeel{:}, ...
                    'String', sprintf(format, runnable.name), ...
                    'Callback', @(obj, event) self.detailsForRunnable(runnable, obj));
                self.listenToRunnable(runnable);

                % recur on its children?
                if isa(runnable, 'topsRunnableComposite')
                    
                    % show concurrently run children in parentheses
                    if isa(runnable, 'topsConcurrentComposite')
                        format = '(%s)';
                    end

                    for ii = 1:length(runnable.children)
                        self.addRunnableAtDepth( ...
                            runnable.children{ii}, depth+1, format);
                    end
                end
            
            else
                % A bogus value?  Just describe it.
                description = ...
                    self.detailsPanel.getDescriptiveUIControlArgsForValue( ...
                    runnable);
                self.heirarchyGrid.newControlAtRowAndColumn( ...
                    self.runnablesCount, [0 1]+depth, ...
                    descriptive{:});
            end
        end
        
        function listenToRunnable(self, runnable)
            props = intersect(self.structuralProps, properties(runnable));
            for ii = 1:length(props)
                listener = runnable.addlistener(props{ii}, 'PostSet', ...
                    @(source, event)self.hearRunnablePropertyChange( ...
                    source, event));
                self.addListenerWithName(listener, props{ii});
            end
            
            listener = runnable.addlistener('RunStart', ...
                @(source, event)self.hearRunStart(source, event));
            self.addListenerWithName(listener, 'RunStart');
        end
        
        function hearRunnablePropertyChange(self, metaProp, event)
            self.repopulateHeirarchyGrid;
            
            % redraw for currently detailed runnable
            if event.AffectedObject == self.currentRunnable
                self.detailsForRunnable(self.currentRunnable);
            end
        end
        
        function hearRunStart(self, runnable, event)
            self.detailsForRunnable(runnable);
        end
        
        function repondToResize(self, figure, event)
            self.heirarchyGrid.repositionControls;
            self.detailsPanel.repondToResize;
        end
    end
end