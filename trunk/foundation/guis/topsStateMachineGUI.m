classdef topsStateMachineGUI < topsGUI
    % @class topsStateMachineGUI
    % Overview the states of a state machine.
    % topsStateMachineGUI lists all the states and their properties for a
    % topsStateMachine, in a grid view.
    % @details
    % At the top right, the "run states" button allows you to invoke the
    % run() method of the state machine.
    % @details
    % You can launch topsStateMachineGUI with the topsStateMachineGUI()
    % constructor, or with the gui() method a topsStateMachine.
    % @details
    % topsStateMachineGUI uses listeners to detect changes to the state
    % machine it's showing.  This means that you can view your state
    % machine as you work on it, and you don't have to reopen or refresh
    % the GUI.
    % @details
    % But beware that listeners can slow Matlab down.  So if you're in a
    % timing-critical situation, like running a real experiment, you might
    % wish to close the GUI, deleting its listeners.
    % @ingroup foundation
    
    properties
        % an instance of topsStateMachine to view.
        stateMachine;
        machineGrid;
        machineRunButton;
        statesGrid;
    end
    
    properties(Hidden)
        machineProps = {'beginFevalable', 'transitionFevalable', 'endFevalable', 'preview'};
        statesProp = 'allStates';
    end
    
    methods
        % Constructor takes one optional argument
        % @param stateMachine a dotsStateMachine to visualize
        % @details
        % Returns a handle to the new topsStateMachineGUI.  If
        % @a stateMachine is missing, the GUI will launch but no
        % data will be shown.
        function self = topsStateMachineGUI(stateMachine)
            self = self@topsGUI;
            self.title = 'State Machine Viewer';
            self.createWidgets;
            
            if nargin
                self.stateMachine = stateMachine;
                self.listenToStateMachine;
                self.repopulateMachineGrid;
                self.repopulateStatesGrid;
                self.title = sprintf('State Machine "%s"', self.stateMachine.name);
            end
        end
        
        function createWidgets(self)
            left = .01;
            right = .99;
            bottom = .01;
            top = .99;
            yDiv = .75;
            xDiv = .8;

            self.statesGrid = ScrollingControlGrid( ...
                self.figure, [left, bottom, right-left, yDiv-bottom]);
            self.addScrollableChild(self.statesGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, self.statesGrid});
            self.statesGrid.rowHeight = 1.2;

            self.machineGrid = ScrollingControlGrid( ...
                self.figure, [left, yDiv, xDiv-left, top-yDiv]);
            self.addScrollableChild(self.machineGrid.panel, ...
                {@ScrollingControlGrid.respondToSliderOrScroll, self.machineGrid});
            self.machineGrid.rowHeight = 1.5;
            
            self.machineRunButton = uicontrol( ...
                'Parent', self.figure, ...
                'BackgroundColor', self.lightColor, ...
                'Callback', @(obj, event)self.runMachine, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', 'run', ...
                'Position', [xDiv, yDiv, right-xDiv, top-yDiv], ...
                'HorizontalAlignment', 'left');
        end
        
        function repopulateMachineGrid(self)
            self.machineGrid.deleteAllControls;
            
            % add a row of widgets for each state machine property
            for ii = 1:length(self.machineProps)
                args = self.getDescriptiveUIControlArgsForValue(self.machineProps{ii});
                self.machineGrid.newControlAtRowAndColumn( ...
                    ii, 1, args{:});
                
                val = self.stateMachine.(self.machineProps{ii});
                args = self.getDescriptiveUIControlArgsForValue(val);
                self.machineGrid.newControlAtRowAndColumn( ...
                    ii, [2 4], args{:});
            end

            % update the grid graphics all at once
            self.machineGrid.repositionControls;
        end
        
        function repopulateStatesGrid(self)
            self.statesGrid.deleteAllControls;
            
            % add a column of widgets for each state property
            %   with each state on its own row
            s = self.stateMachine.allStates;
            fn = fieldnames(s);
            for ii = 1:length(fn)
                row = 1;
                args = self.getDescriptiveUIControlArgsForValue(fn{ii});
                self.statesGrid.newControlAtRowAndColumn( ...
                    row, ii, args{:});

                for jj = 1:length(s)
                    row = row + 1;
                    val = s(jj).(fn{ii});
                    args = self.getDescriptiveUIControlArgsForValue(val);
                    self.statesGrid.newControlAtRowAndColumn( ...
                        row, ii, args{:});
                end
            end
            
            % update the grid graphics all at once
            self.statesGrid.repositionControls;
        end
        
        function listenToStateMachine(self)
            
            for ii = 1:length(self.machineProps)
                listener = self.stateMachine.addlistener( ...
                    self.machineProps{ii}, 'PostSet', ...
                    @(source, event)self.hearMachinePropertyChange(source, event));

                self.addListenerWithName(listener, self.machineProps{ii});
            end

            listener = self.stateMachine.addlistener( ...
                self.statesProp, 'PostSet', ...
                @(source, event)self.hearStatesPropertyChange(source, event));
            self.addListenerWithName(listener, self.statesProp);
        end
        
        function hearMachinePropertyChange(self, metaProp, event)
            % rebuild when machine data change
            self.repopulateMachineGrid;
        end
        
        function hearStatesPropertyChange(self, metaProp, event)
            % rebuild when state data change
            self.repopulateStatesGrid;
        end
        
        function runMachine(self)
            self.stateMachine.run;
        end
        
        function hearMachineRun(self, machine, event)
            % somehow trace state traversal
            %   when to drawnow?
            %   print a list of states?
        end
        
        function repondToResize(self, figure, event)
            % attempt to resize with characters, rather than normalized
            self.statesGrid.repositionControls;
        end
    end
end