classdef topsStateMachine < topsConcurrent
    % @class topsStateMachine
    % A state machine for controlling flow through predefined states.
    % @details
    % topsStateMachine may contain arbitrary states to be traversed when it
    % run()s.  Each state may invoke functions and transition to other
    % states with specified timing.  State traversal may be deterministic,
    % or may be conditional and branching based on an arbitrary functions.
    %
    % @ingroup foundataion
    
    properties (SetObservable)
        % struct array of data for each state
        % @details
        % Each element of allStates represents a single state.  See
        % addState() for details about the struct fields and state
        % properties.
        allStates = struct([]);
        
        % optional fevalable cell array to invoke during state transitions
        % @details
        % The function should expect as the first argument a 1x2 struct
        % array of information about the previous state and the next state,
        % with elements in that order. Any other arguments in the cell
        % array will be passed to the function starting at the second
        % place.  See addState() for details of the struct state
        % information.
        transitionFevalable = {};
        
        % any function that returns the current time as a number
        clockFunction = @topsClock;
        
        % the time when state traversal began
        startTime = [];
        
        % the time when state traversal ended
        finishTime = [];
        
        % struct of information about the last state encountered during
        % traversal.
        % @details
        % See addState() for details of the struct state information.
        finishState = struct([]);
        
        % time when the current state was entered
        currentEntryTime = [];
        
        % time when the current state will reach its timeout
        currentTimeoutTime = [];
        
        % cell array of string names given to functions which are invoked
        % whenever entering any state.
        % @details
        % sharedEntryFevalableNames are parallel to sharedEntryFevalables.
        % See addSharedFcn() for details about shared entry and exit
        % funcions.
        sharedEntryFevalableNames = {};
        
        % cell array of fevalable cell arrays which are invoked whenever
        % entering any state.
        % @details
        % sharedEntryFevalableNames are parallel to sharedEntryFevalables.
        % See addSharedFcn() for details about shared entry and exit
        % funcions.
        sharedEntryFevalables = {};
        
        % cell array of strings, names given to functions which are invoked
        % whenever exiting any state.
        % @details
        % sharedExitFevalableNames are parallel to sharedExitFevalables.
        % See addSharedFcn() for details about shared entry and exit
        % funcions.
        sharedExitFevalableNames = {};
        
        % cell array of fevalable cell arrays which are invoked whenever
        % exiting any state.
        % @details
        % sharedExitFevalableNames are parallel to sharedExitFevalables.
        % See addSharedFcn() for details about shared entry and exit
        % funcions.
        sharedExitFevalables = {};
    end
    
    properties (Hidden)
        % allStates array index for the current state
        currentIndex = [];
        
        % copy of the current state's input fevalable
        currentInputFevalable = [];
        
        % containers.Map of state name -> allStates array index.
        stateNameToIndex;
        
        % string used for topsDataLog entry for transitionFevalable
        transitionString = 'transition';
        
        % string used for topsDataLog entry during state entry
        entryString = 'enter';
        
        % string used for topsDataLog entry during state exit
        exitString = 'exit';
        
        % field names of allStates struct array, defining state behaviors
        stateFields = {'name', 'next', 'timeout', ...
            'entry', 'input', 'exit'};
        
        % default values of allStates struct array fields
        stateDefaults = {'', '', 0, {}, {}, {}};
    end
    
    methods
        % Constructor takes no arguments.
        function self = topsStateMachine
            self.stateNameToIndex = containers.Map( ...
                'a', 1, 'uniformValues', false);
            self.stateNameToIndex.remove(self.stateNameToIndex.keys);
        end
        
        % Launch a graphical interface showing the states in the machine.
        function g = gui(self)
            g = topsStateMachineGUI(self);
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
                newState = cell2struct( ...
                    statesInfo(ii,:), statesInfo(1,:), 2);
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
        % the state, during each call to runBriefly().  Expected to return
        % a single value, which may be the @b name of a state, in which
        % case the state machine will transition to that state immediately.
        % @b timeout must be nonzero for @b input to be invoked.
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
        % sharedEntryFevalableNames or sharedExitFevalableNames.  Values in
        % these fields will be passed as state-specific arguments to the
        % shared function.
        % @details
        % Returns the index into allStates where the new state was appended
        % or inserted.
        function allStateIndex = addState(self, stateInfo)
            % combine official state field names and default values with
            % shared entry and exit functions.
            allowedFields = cat(2, self.stateFields, ...
                self.sharedEntryFevalableNames, ...
                self.sharedExitFevalableNames);
            allowedDefaults = cat(2, self.stateDefaults, ...
                cell(size(self.sharedEntryFevalableNames)), ...
                cell(size(self.sharedExitFevalableNames)));
            
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
        
        % Edit fields of an existing state.
        % @param stateName string name of an existing state in allStates
        % @param varargin flexible number of field-value paris to edit the
        % fields of the @a stateName state.
        % @details
        % Assigns the given values to the given fields of the existing
        % state that has the name @a stateName.  @a varargin represents a
        % flexible number of traling arguments passed to editStateByName().
        % The first argument in each pair should be one of the field names
        % of the allStates struct, which include the default state fields
        % described for addField() and the names of any shared fevalables
        % as added with addSharedFevalableWithName().  The second argument
        % in each pair should be a value to assign to the named field.
        % @details
        % Editing the @b name field of a state might cause the state
        % machine to misbehave.
        % @details
        % Returns the index into allStates of the @a stateName state.  If
        % @a stateName is not the name of an existing state, returns [].
        function allStateIndex = editStateByName(self, stateName, varargin)
            [isState, allStateIndex] = self.isStateName(stateName);
            if isState
                for ii = 1:2:length(varargin)
                    field = varargin{ii};
                    if isfield(self.allStates, field)
                        self.allStates(allStateIndex).(field) = ...
                            varargin{ii+1};
                    end
                end
            end
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
        % sharedExitFevalables.  These functions are called for every
        % state, in addition to each state's own entry and exit.
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
                    existing = strcmp( ...
                        self.sharedEntryFevalableNames, name);
                    if any(existing)
                        index = find(existing, 1);
                    else
                        index = length(self.sharedEntryFevalableNames) + 1;
                    end
                    self.sharedEntryFevalableNames{index} = name;
                    self.sharedEntryFevalables{index} = fcn;
                    
                case 'exit'
                    existing = strcmp(self.sharedExitFevalableNames, name);
                    if any(existing)
                        index = find(existing, 1);
                    else
                        index = length(self.sharedExitFevalableNames) + 1;
                    end
                    self.sharedExitFevalableNames{index} = name;
                    self.sharedExitFevalables{index} = fcn;
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
        function [stateInfo, allStateIndex] = getStateInfoByName( ...
                self, stateName)
            [isState, allStateIndex] = self.isStateName(stateName);
            if isState
                stateInfo = self.allStates(allStateIndex);
            else
                stateInfo = [];
            end
        end
        
        % Prepare for state traversal.
        % @details
        % topsStateMachine extends the start() method of topsConcurrent to
        % record the startTime and enter the first state in allStates.
        function start(self)
            self.start@topsConcurrent;
            self.startTime = feval(self.clockFunction);
            self.finishTime = [];
            self.enterStateAtIndex(1);
        end
        
        % Finish doing state traversal.
        % @details
        % topsStateMachine extends the finish() method of topsConcurrent to
        % record the finishState and finishTime.
        function finish(self)
            self.finish@topsConcurrent;
            
            if length(self.allStates) >= self.currentIndex
                self.finishState = self.allStates(self.currentIndex);
            else
                self.finishState = [];
            end
            
            self.finishTime = feval(self.clockFunction);
        end
        
        % Do a little flow control within the state list.
        % @details
        % topsStateMachine extends the runBriefly() method of
        % topsConcurrent to do state traversal.  It checks the input
        % fevalable for the current state and if the input returns a state
        % name, transitions to that state.  If not, it checks whether the
        % current state's timeout has expired.  If so it transitions to the
        % next state.  If there is no next state, traversal ends.
        function runBriefly(self)
            % poll for input
            if ~isempty(self.currentInputFevalable)
                nextName = feval(self.currentInputFevalable{:});
                if self.isStateName(nextName)
                    self.transitionToStateWithName(nextName);
                    return;
                end
            end
            
            % poll for state timeout
            if feval(self.clockFunction) >= self.currentTimeoutTime
                nextName = self.allStates(self.currentIndex).next;
                if isempty(nextName)
                    self.exitCurrentState;
                    self.isRunning = false;
                else
                    self.transitionToStateWithName(nextName);
                end
            end
        end
    end
    
    methods (Access = protected)
        % reset all the current* properties for the given state
        function enterStateAtIndex(self, allStateIndex)
            self.currentIndex = allStateIndex;
            
            if length(self.allStates) >= allStateIndex
                
                currentState = self.allStates(self.currentIndex);
                self.currentInputFevalable = currentState.input;
                self.currentEntryTime = feval(self.clockFunction);
                self.currentTimeoutTime = ...
                    self.currentEntryTime + currentState.timeout;
                
                fevalName = sprintf('%s:%s', ...
                    self.entryString, currentState.name);
                self.logFeval(fevalName, currentState.entry);
                
                if ~isempty(self.sharedEntryFevalableNames)
                    
                    self.logStateSharedFeval(currentState, ...
                        self.sharedEntryFevalableNames, ...
                        self.sharedEntryFevalables);
                end
                
            else
                self.isRunning = false;
                
            end
        end
        
        % clear current* properties
        %   but leave currentIndex so it's checkable
        function exitCurrentState(self)
            currentState = self.allStates(self.currentIndex);
            
            self.currentInputFevalable = {};
            self.currentEntryTime = [];
            self.currentTimeoutTime = [];
            
            if ~isempty(self.sharedExitFevalableNames)
                self.logStateSharedFeval(currentState, ...
                    self.sharedExitFevalableNames, ...
                    self.sharedExitFevalables);
            end
            
            fevalName = sprintf('%s:%s', ...
                self.exitString, currentState.name);
            self.logFeval(fevalName, currentState.exit);
        end
        
        % Invoke transitionFevalable before exiting previous state.
        function transitionToStateWithName(self, nextName)
            nextIndex = self.stateNameToIndex(nextName);
            self.exitCurrentState;
            
            if ~isempty(self.transitionFevalable)
                inserted = cell(1, numel(self.transitionFevalable) + 1);
                inserted(1) = self.transitionFevalable(1);
                inserted{2} = self.allStates( ...
                    [self.currentIndex, nextIndex]);
                inserted(3:end) = self.transitionFevalable(2:end);
                self.logFeval(self.transitionString, inserted)
            end
            
            self.enterStateAtIndex(nextIndex);
        end
        
        % Add an entry to topsDataLog for an fevalable shared among states.
        function logStateSharedFeval(self, state, fcnNames, fcns)
            for ii = 1:length(fcnNames)
                stateArgs = state.(fcnNames{ii});
                stateFcn = cat(2, fcns{ii}, stateArgs);
                fevalName = sprintf('%s:%s', ...
                    fcnNames{ii}, state.name);
                self.logFeval(fevalName, stateFcn);
            end
        end
    end
end