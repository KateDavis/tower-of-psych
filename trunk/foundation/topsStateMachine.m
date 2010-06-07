classdef topsStateMachine < topsFoundation
    % @class topsStateMachine
    % A state machine for controlling flow through e.g. trials.
    %
    % @ingroup foundataion
    
    properties (SetObservable)
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
        beginFevalable = {};
        
        % a fevalable cell array to invoke during state transitions.
        % The function should expect as the first argument a 1x2 struct
        % array of information about the previous state and the next state,
        % with elements in that order. Any other arguments in the cell
        % array will be passed to the function starting at the second
        % place.  See addState() for details of the struct state
        % information.
        transitionFevalable = {};
        
        % a fevalable cell array to invoke when state traversal ends.
        % The function should expect as the first argument a struct of
        % information about the last state.  Any other arguments in the
        % cell array will be passed to the function starting at the second
        % place.  See addState() for details of the struct state
        % information.
        endFevalable = {};
        
        % true or false, whether to execute functions (false) or just
        % traverse states (true).
        preview = false;
        
        % any function that returns the current time as a number
        clockFunction = @topsClock;
        
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
        
        % cell array of strings, names given to functions which are invoked
        % whenever entering any state.  sharedEntryFevalableNames are parallel to
        % sharedEntryFevalables.  See addSharedFcn() for details about shared
        % entry and exit funcions.
        sharedEntryFevalableNames = {};
        
        % cell array of fevalable cell arrays which are invoked whenever
        % entering any state.  sharedEntryFevalableNames are parallel to
        % sharedEntryFevalables.  See addSharedFcn() for details about shared
        % entry and exit funcions.
        sharedEntryFevalables = {};
        
        % cell array of strings, names given to functions which are invoked
        % whenever exiting any state.  sharedexitFevalableNames are parallel to
        % sharedexitFevalables.  See addSharedFcn() for details about shared
        % entry and exit funcions.
        sharedexitFevalableNames = {};
        
        % cell array of fevalable cell arrays which are invoked whenever
        % exiting any state.  sharedexitFevalableNames are parallel to
        % sharedexitFevalables.  See addSharedFcn() for details about shared
        % entry and exit funcions.
        sharedexitFevalables = {};
    end
    
    properties (Hidden)
        % allStates index of the current state
        currentIndex = [];
        
        % fevalable cell array, a copy of the current state's
        % input.
        currentInputFevalable = [];
        
        % a containers.Map of state name -> allStates struct index.
        stateNameToIndex;
        
        beginString = 'begin';
        transitionString = 'transition';
        endString = 'end';
        entryString = 'enter';
        inputString = 'input';
        exitString = 'exit';
        previewString = '(preview)';
        
        stateFields = {'name', 'next', 'timeout', ...
            'entry', 'input', 'exit'};
        stateDefaults = {'', '', 0, {}, {}, {}};
    end
    
    methods
        function self = topsStateMachine
            self.stateNameToIndex = containers.Map('a', 1, 'uniformValues', false);
            self.stateNameToIndex.remove(self.stateNameToIndex.keys);
        end
        
        % Add multiple states to the state machine.
        % @param statesInfo a cell array with information defining multiple
        % states.
        % @details
        % @a statesInfo should resemble a table, with a row for each new
        % state a column for each state field.
        % @details
        % The first row of @a statesInfo shoud contain field names that
        % correspond to the fields of allStates.  See addState() for
        % field descriptions.  Only the @b name field is mandatory.  Fields
        % may appear in any order.
        % @details
        % Each additional row of @a statesInfo shoud contain values aligned
        % with the field names in the first row.  A new state will be added
        % using each row of values.  Default values will be used where
        % fields are omitted.  The @b name field is mandatory.
        % @details
        % The values in the @b name column should be unique with respect to
        % each other and any existing states.  When names collide, new
        % states will replace existing states.
        % @details
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
        % @param stateInfo a struct with information defining a state.
        % @details
        % @a stateInfo should have the same fields as allStates:
        % 	- @b name a string to identify the state
        % 	- @b timeout time that may elapse before transitioning to the
        % @b next state, in units of clockFunction
        % 	- @b next the @b name of the state to transition to once @b
        % timeout has elapsed
        % 	- @b entry a fevalable cell array to invoke whenever
        % entering the state
        % 	- @b input: a fevalable cell array to invoke after entering
        % the state, during each call to step().  Expected to return a
        % single value, which may be the @b name of a state, in which case
        % the state machine will transition to that state immediately.  @b
        % timeout must be nonzero for @b input to be invoked.
        % 	- @b exit: a fevalable cell array to invoke whenever exiting
        % the state
        %   .
        % @details
        % Each state must have a unique @b name.  If @a stateInfo has the
        % same @b name as an existing state, @a stateInfo will replace the
        % existing state.
        % @details
        % Other fields of @a stateInfo may be omitted, in which case
        % default values will be used.
        % @details
        % Fields of stateInfo may correspond to one of the names in
        % sharedEntryFevalableNames or sharedexitFevalableNames.  Values in these
        % fields will be passed as state-specific arguments to the shared
        % function.
        % @details
        % Returns the index into allStates where the new state was appended
        % or inserted.
        function allStateIndex = addState(self, stateInfo)
            % combine official state field names and default values with
            % shared entry and exit functions.
            allowedFields = cat(2, self.stateFields, ...
                self.sharedEntryFevalableNames, ...
                self.sharedexitFevalableNames);
            allowedDefaults = cat(2, self.stateDefaults, ...
                cell(size(self.sharedEntryFevalableNames)), ...
                cell(size(self.sharedexitFevalableNames)));
            
            % pick stateInfo fields that match allowed fields
            infoFields = fieldnames(stateInfo);
            infoValues = struct2cell(stateInfo);
            [validFields, validIndices, defaultIndices] = ...
                intersect(infoFields, allowedFields);
            
            % merge valid stateInfo and defaults into new struct
            mergedValues = allowedDefaults;
            mergedValues(defaultIndices) = infoValues(validIndices);
            newState = cell2struct(mergedValues, allowedFields, 2);
            
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
        
        % Add a function to be invoked during every state.
        % @param fcn a fevalable cell array to invoke during every state
        % @param name string name to give to @a fcn
        % @param when the string 'entry' or 'exit' specifying when to
        % invoke @a fcn.  For 'entry', @a fcn will be invoked just after
        % each state's own entry.  For 'exit', @a fcn will be invoked
        % just before each state's own exit.  If omitted, defaults to
        % 'entry'.
        % @details
        % Adds @a fcn to the state machine's sharedEntryFevalables or
        % sharedexitFevalables.  These functions are called for every state, in
        % addition to each state's own entry and exit.
        % @details
        % Each state may specify additional arguments to pass to @a fcn.
        % These may be specified like other state data, using @a name as
        % the state field.  See addState() and addMultipleStates() for
        % details on specifying state data.
        % @details
        % @a name must be unique with respect to other shared entry or exit
        % functions.  If @a name matches the name of an existing shared
        % function, @a fcn will replace the existing function.
        function addSharedFevalableWithName(self, fcn, name, when)
            if nargin < 4
                when = 'entry';
            end
            
            switch when
                case 'entry'
                    existing = strcmp(self.sharedEntryFevalableNames, name);
                    if any(existing)
                        index = find(existing, 1);
                    else
                        index = length(self.sharedEntryFevalableNames) + 1;
                    end
                    self.sharedEntryFevalableNames{index} = name;
                    self.sharedEntryFevalables{index} = fcn;
                    
                case 'exit'
                    existing = strcmp(self.sharedexitFevalableNames, name);
                    if any(existing)
                        index = find(existing, 1);
                    else
                        index = length(self.sharedexitFevalableNames) + 1;
                    end
                    self.sharedexitFevalableNames{index} = name;
                    self.sharedexitFevalables{index} = fcn;
            end
            
            if ~isempty(self.allStates) && ~isfield(self.allStates, name)
                [self.allStates.(name)] = deal({});
            end
        end
        
        % Check whether a string is the name of a state.
        function [isState, allStateIndex] = isStateName(self, stateName)
            isState = self.stateNameToIndex.isKey(stateName);
            if isState
                allStateIndex = self.stateNameToIndex(stateName);
            else
                allStateIndex = [];
            end
        end
        
        % Get a struct of info about a state with a given name.
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
            self.beginTime = feval(self.clockFunction);
            self.endTime = [];
            self.fevalInsertArgAndLog( ...
                self.allStates(1), ...
                self.beginFevalable, ...
                self.beginString);
            self.enterStateAtIndex(1);
        end
        
        % Continue state traversal.  Check time and input for the current
        % state.  Transition states or end traversal as it comes up.
        % Useful for traversing states concurrently with other behaviors.
        function step(self)
            % poll for input
            if ~isempty(self.currentInputFevalable)
                nextName = feval(self.currentInputFevalable{:});
                if self.isStateName(nextName)
                    self.transitionToStateWithName(nextName);
                    return;
                end
            end

            % poll for state timed out
            if feval(self.clockFunction) >= self.currentTimeoutTime
                nextName = self.allStates(self.currentIndex).next;
                if isempty(nextName)
                    self.endTraversal;
                else
                    self.transitionToStateWithName(nextName);
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
    
    methods (Access = protected)
        % reset all the current* properties for the given state
        function enterStateAtIndex(self, allStateIndex)
            self.currentIndex = allStateIndex;
            
            currentState = self.allStates(self.currentIndex);
            self.currentInputFevalable = currentState.input;
            self.currentEntryTime = feval(self.clockFunction);
            self.currentTimeoutTime = self.currentEntryTime + currentState.timeout;
            self.fevalForStateAndLog( ...
                currentState.name, ...
                currentState.entry, ...
                self.entryString);
            
            if ~isempty(self.sharedEntryFevalableNames)
                self.fevalSharedAndLog(currentState, ...
                    self.sharedEntryFevalableNames, ...
                    self.sharedEntryFevalables);
            end
            
            % transition immediately, if possible
            %self.step;
        end
        
        % clear current* properties
        %   but leave currentIndex so it's checkable
        function exitCurrentState(self)
            currentState = self.allStates(self.currentIndex);
            self.currentInputFevalable = {};
            self.currentEntryTime = [];
            self.currentTimeoutTime = [];
            
            if ~isempty(self.sharedexitFevalableNames)
                self.fevalSharedAndLog(currentState, ...
                    self.sharedexitFevalableNames, ...
                    self.sharedexitFevalables);
            end
            
            self.fevalForStateAndLog( ...
                currentState.name, ...
                currentState.exit, ...
                self.exitString);
        end
        
        % call transitionFevalable before exiting last and entering next state
        function transitionToStateWithName(self, nextName)
            nextIndex = self.stateNameToIndex(nextName);
            self.exitCurrentState;
            self.fevalInsertArgAndLog( ...
                self.allStates([self.currentIndex, nextIndex]), ...
                self.transitionFevalable, ...
                self.transitionString);
            self.enterStateAtIndex(nextIndex);
        end
        
        % all done.  exit last state before calling endFevalable
        function endTraversal(self)
            self.endState = self.allStates(self.currentIndex);
            self.exitCurrentState;
            self.fevalInsertArgAndLog( ...
                self.allStates(self.currentIndex), ...
                self.endFevalable, ...
                self.endString);
            self.endTime = feval(self.clockFunction);
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
        
        function fevalSharedAndLog(self, state, fcnNames, fcns)
            for ii = 1:length(fcnNames)
                stateArgs = state.(fcnNames{ii});
                stateFcn = cat(2, fcns{ii}, stateArgs);
                self.fevalForStateAndLog(state.name, stateFcn, fcnNames{ii});
            end
        end
    end
end