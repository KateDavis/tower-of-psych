classdef topsStateMachine < handle
    % @class topsStateMachine
    % A state machine for controlling flow through e.g. trials.
    % @details
    % Here's some of my thinking behind topsStateMachine, and why I made it
    % different from dotsx
    %   - "standard" vocab from Wikipedia, like "input"
    %   - more function handles to hook on or ignore, like transitionFcn
    %   - automatic topsDataLog'ging
    %   - allStates struct should be guiable and oh, so graphable
    %       - State diagrams!  Think of the grant proposals!
    %   - states are not objects and don't readily modify themselves.
    %       - more states, then?  Lends to explanation and visualization.
    %   - may run() a full traversal, or step() through states concurrently
    %   with other behaviors.
    %
    % @ingroup foundataion
    
    properties (SetObservable)
        % a string name for this state machine
        name = '';
        
        % struct array of state data.  Each element represents a single
        % state.  See addState() for details about the struct fields and
        % state properties.
        allStates = struct([]);
        
        % a fevalable cell array to invoke when state traversal begins.
        % The function should expect as the first argument a struct of
        % information about the first state.  Any other arguments in the
        % cell array will be passed to the function starting at the second
        % place.  See addState() for details of the struct state
        % information.
        beginFcn = {};
        
        % a fevalable cell array to invoke during state transitions.
        % The function should expect as the first argument a 1x2 struct
        % array of information about the previous state and the next state,
        % with elements in that order. Any other arguments in the cell
        % array will be passed to the function starting at the second
        % place.  See addState() for details of the struct state
        % information.
        transitionFcn = {};
        
        % a fevalable cell array to invoke when state traversal ends.
        % The function should expect as the first argument a struct of
        % information about the last state.  Any other arguments in the
        % cell array will be passed to the function starting at the second
        % place.  See addState() for details of the struct state
        % information.
        endFcn = {};
        
        % true or false, whether to execute functions (false) or just
        % traverse states (true).
        preview = false;
        
        % any function that returns the current time as a number
        clockFcn = @topsTimer;
        
        % the time when state traversal began
        beginTime = [];
        
        % the time when state traversal ended
        endTime = [];
        
        % time when the current state was entered
        currentEntryTime = [];
        
        % time when the current state will reach its timeout
        currentTimeoutTime = [];
    end
    
    properties (Hidden)
        % allStates index of the current state
        currentIndex = [];
        
        % fevalable cell array, a copy of the current state's
        % inputFcn.
        currentInputFcn = [];
        
        % a containers.Map of state name -> allStates struct index.
        stateNameToIndex;
        
        beginString = 'begin';
        transitionString = 'transition';
        endString = 'end';
        entryString = 'enter';
        inputString = 'input';
        exitString = 'exit';
        previewString = '(preview)';
    end
    
    methods
        function self = topsStateMachine
            self.stateNameToIndex = containers.Map('a', 1, 'uniformValues', false);
            self.stateNameToIndex.remove(self.stateNameToIndex.keys);
        end
        
        % Create a new state and append it to allStates.
        % @prop name a string to identify the state
        % @prop timeout: time that may elapse before transitioning to the
        % @a next state, in units of clockFunction
        % @prop next: the @a name of the state to transition to once @a
        % timeout has elapsed
        % @prop entryFcn a fevalable cell array to invoke whenever
        % entering the state
        % @prop inputFcn: a fevalable cell array to invoke after entering
        % the state, during each call to step().  Expected to return the @a
        % name of a state, or ''
        % @prop exitFcn: a fevalable cell array to invoke whenever exiting
        % the state
        % .
        % @details
        % addState() argument names are identical to the fields of the
        % allStates struct array, and have the same meanings.
        % <br><br>
        % Each state must have its own @a name.  Other arguments may be
        % empty, but may not be omitted.
        % <br><br>
        % Returns the inedx into allStates of the struct that represnets
        % the new state.
        function allStateIndex = addState(self, name, timeout, next, entryFcn, inputFcn, exitFcn)
            % put args into struct form
            newState = struct();
            newState.name = name;
            newState.timeout = timeout;
            newState.next = next;
            newState.entryFcn = entryFcn;
            newState.inputFcn = inputFcn;
            newState.exitFcn = exitFcn;
            
            % append the new state to allStates
            %   add to lookup table
            n = length(self.allStates);
            if n < 1
                self.allStates = newState;
            else
                self.allStates(end+1) = newState;
            end
            self.stateNameToIndex(newState.name) = n+1;
            allStateIndex = n+1;
        end
        
        function [isState, allStateIndex] = isStateName(self, stateName)
            isState = self.stateNameToIndex.isKey(stateName);
            if isState
                allStateIndex = self.stateNameToIndex(stateName);
            else
                allStateIndex = [];
            end
        end
        
        function [stateInfo, allStateIndex] = getStateInfoByName(self, stateName)
            [isState, allStateIndex] = self.isStateName(stateName);
            if isState
                stateInfo = self.allStates(allStateIndex);
            else
                stateInfo = [];
            end
        end
        
        % Traverse states until reaching an end, without stopping.
        function run(self)
            self.begin;
            while isempty(self.endTime)
                self.step;
            end
        end
        
        % Prepare for state traversal.  Must call step() to continue
        % traversal.
        function begin(self)
            self.beginTime = feval(self.clockFcn);
            self.endTime = [];
            self.fevalInsertArgAndLog( ...
                self.allStates(1), ...
                self.beginFcn, ...
                self.beginString);
            self.enterStateAtIndex(1);
        end
        
        % Continue state traversal.  Check time and input for the current
        % state.  Transition states or end traversal as it comes up.
        % Useful for traversing states concurrently with other behaviors.
        function step(self)
            nowTime = feval(self.clockFcn);
            if nowTime >= self.currentTimeoutTime
                % timed out
                nextName = self.allStates(self.currentIndex).next;
                if isempty(nextName)
                    self.endTraversal;
                else
                    self.transitionToStateWithName(nextName);
                end
                
            else
                % poll for input
                nextName = feval(self.currentInputFcn{:});
                if self.isStateName(nextName)
                    self.transitionToStateWithName(nextName);
                else
                    return;
                end
            end
        end
    end
    
    methods (Access = private)
        % reset all the current* properties for the given state
        function enterStateAtIndex(self, allStateIndex)
            self.currentIndex = allStateIndex;
            
            currentState = self.allStates(self.currentIndex);
            self.currentInputFcn = currentState.inputFcn;
            self.currentEntryTime = feval(self.clockFcn);
            self.currentTimeoutTime = self.currentEntryTime + currentState.timeout;
            self.fevalForStateAndLog( ...
                currentState.name, ...
                currentState.entryFcn, ...
                self.entryString);
        end
        
        % clear current* properties
        %   but leave currentIndex so it's checkable
        function exitCurrentState(self)
            currentState = self.allStates(self.currentIndex);
            self.currentInputFcn = {};
            self.currentEntryTime = [];
            self.currentTimeoutTime = [];
            self.fevalForStateAndLog( ...
                currentState.name, ...
                currentState.exitFcn, ...
                self.exitString);
        end
        
        % call transitionFcn before exiting last and entering next state
        function transitionToStateWithName(self, nextName)
            nextIndex = self.stateNameToIndex(nextName);
            self.exitCurrentState;
            self.fevalInsertArgAndLog( ...
                self.allStates([self.currentIndex, nextIndex]), ...
                self.transitionFcn, ...
                self.transitionString);
            self.enterStateAtIndex(nextIndex);
        end
        
        % all done.  exit last state before calling endFcn
        function endTraversal(self)
            self.exitCurrentState;
            self.fevalInsertArgAndLog( ...
                self.allStates(self.currentIndex), ...
                self.endFcn, ...
                self.endString);
            self.endTime = feval(self.clockFcn);
        end
        
        function fevalInsertArgAndLog(self, insert, fcn, fcnName)
            if ~isempty(fcn)
                loggable = cell(1,2);
                loggable(1) = fcn(1);
                loggable{2} = insert;
                if self.preview
                    group = sprintf('%s:%s%s', ...
                        self.name, fcnName, self.previewString);
                    topsDataLog.logDataInGroup(loggable, group);
                    
                else
                    group = sprintf('%s:%s', self.name, fcnName);
                    topsDataLog.logDataInGroup(loggable, group);
                    feval(fcn{1}, insert, fcn{2:end});
                end
            end
        end
        
        function fevalForStateAndLog(self, stateName, fcn, fcnName)
            if ~isempty(fcn)
                if self.preview
                    group = sprintf('%s.%s:%s%s', ...
                        self.name, stateName, fcnName, self.previewString);
                    topsDataLog.logDataInGroup(fcn{1}, group);
                    
                else
                    group = sprintf('%s.%s:%s', ...
                        self.name, stateName, fcnName);
                    topsDataLog.logDataInGroup(fcn{1}, group);
                    feval(fcn{:});
                end
            end
        end
    end
end