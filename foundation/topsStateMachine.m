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
        
        % struct of information about the last state encountered during
        % traversal.  See addState() for details of the struct state
        % information.
        endState = struct([]);
        
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
        
        stateFields = {'name', 'entryFcn', 'inputFcn', ...
            'timeout', 'exitFcn', 'next'};
        stateDefaults = {'', {}, {}, 0, {}, ''};
    end
    
    methods
        function self = topsStateMachine
            self.stateNameToIndex = containers.Map('a', 1, 'uniformValues', false);
            self.stateNameToIndex.remove(self.stateNameToIndex.keys);
        end
        
        % Add multiple states to the state machine.
        % @param statesInfo a cell array with information defining multiple
        % new states.
        % @details
        % @a statesInfo should resemble a table, with a row for each new
        % state a column for each state field.
        % <br><br>
        % The first row of @a statesInfo shoud contain field names that
        % correspond to the fields of allStates.  See addState() for
        % field descriptions.  Only the @b name field is mandatory.  Fields
        % may appear in any order.
        % <br><br>
        % Each additional row of @a statesInfo shoud contain values aligned
        % with the field names in the first row.  A new state will be added
        % using each row of values.  Default values will be used where
        % fields are omitted.  The @b name field is mandatory.
        % <br><br>
        % The values in the @b name column should be unique with respect to
        % each other and any existing states.  When names collide, new
        % states will replace existing states.
        % <br><br>
        % Returns an array of indexes into allStates where the new states
        % were appended or inserted.
        function allStateIndexes = addMultipleStates(self, statesInfo)
            % build a stateInfo struct for each row of values
            %   let addState validate fields and fill in defaults
            sz = size(statesInfo);
            allStateIndexes = zeros(1,sz(1)-1);
            for ii = 2:sz(1)
                newState = cell2struct(statesInfo(ii,:), statesInfo(1,:), 2);
                allStateIndexes(ii-1) = self.addState(newState);
            end
        end
        
        % Add a new state to the state machine.
        % @param stateInfo a struct with information defining a new
        % state.
        % @details
        % @a stateInfo must have the same fiels as allStates:
        % 	- @b name a string to identify the state
        % 	- @b timeout time that may elapse before transitioning to the
        % @b next state, in units of clockFunction
        % 	- @b next the @b name of the state to transition to once @b
        % timeout has elapsed
        % 	- @b entryFcn a fevalable cell array to invoke whenever
        % entering the state
        % 	- @b inputFcn: a fevalable cell array to invoke after entering
        % the state, during each call to step().  Expected to return a
        % single value, which may be the @b name of a state, in which case
        % the state machine will transition to that state immediately.  @b
        % timeout must be nonzero for @b inputFcn to be invoked.
        % 	- @b exitFcn: a fevalable cell array to invoke whenever exiting
        % the state
        %   .
        % @details
        % Each state must have a unique @b name.  If @a stateInfo has the
        % same @b name as an existing state, @a stateInfo will replace the
        % existing state.
        % <br><br>
        % Other fields of @a stateInfo may be omitted, in which case
        % default values will be used.
        % <br><br>
        % Returns the inedx into allStates where the new state was appended
        % or inserted.
        function allStateIndex = addState(self, stateInfo)
            % pick stateInfo fields that match official fields
            infoFields = fieldnames(stateInfo);
            infoValues = struct2cell(stateInfo);
            [validFields, validIndices, defaultIndices] = ...
                intersect(infoFields, self.stateFields);

            % merge valid stateInfo and defaults into new struct
            mergedValues = self.stateDefaults;
            mergedValues(defaultIndices) = infoValues(validIndices);
            newState = cell2struct(mergedValues, self.stateFields, 2);
            
            % append the new state to allStates
            %   add to lookup table
            if isempty(self.allStates)
                allStateIndex = 1;
                self.allStates = newState;
            else
                [isState, allStateIndex] = self.isStateName(newState.name);
                if ~isState
                    allStateIndex = length(self.allStates) + 1;
                end
                self.allStates(allStateIndex) = newState;
            end
            self.stateNameToIndex(newState.name) = allStateIndex;
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
                if ~isempty(self.currentInputFcn)
                    nextName = feval(self.currentInputFcn{:});
                    if self.isStateName(nextName)
                        self.transitionToStateWithName(nextName);
                    end
                end
            end
        end
        
        % true or false, whether state machine is currently stepping
        % through states
        function isTrav = isTraversing(self)
            isTrav = ~isempty(self.beginTime) && isempty(self.endTime);
        end
        
        function g = gui(self)
            g = topsStateMachineGUI(self);
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
            self.endState = self.allStates(self.currentIndex);
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