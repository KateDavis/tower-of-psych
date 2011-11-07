classdef topsCallList < topsConcurrent
    % @class topsCallList
    % A list of functions to call sequentially, as a batch.
    % topsCallList manages a list of functions to be called as a batch.
    % @details
    % Since topsCallList extends topsConcurrent, a topsCallList object can
    % be added as one of the components of a topsConcurrentComposite
    % object, and its batch of functions can be invoked concurrently with
    % other topsConcurrent objects.
    % @details
    % A topsCallList object has no internal state to keep track of, so it
    % has no natural way to decide when it's done running.  The
    % alwaysRunning property determines whether the object should be
    % considered running following each call to runBriefly().
    % @details
    % topsCallList expects functions of a particular form, which it
    % calls "fevalable".  Fevalables are cell arrays that have a function
    % handle as the first element.  Additional elements are treated as
    % arguments to the function.
    % @details
    % The fevalables convention makes it easy to make arbitrary function
    % calls with Matlab's built-in feval() function--hence the name--so the
    % cell array "foo" would be an fevalable if it could be executed with
    % feval(foo{:}).
    % @details
    % By default, all of the fevalables in the call list will be called
    % during each runBriefly().  Optionally, each call can be given a name
    % and its runBriefly() activity can be toggled with setActiveByName().
    % Or, one call can replaced with a different call, useing
    % setCallByName();
    % @ingroup foundation
    
    properties (SetObservable)
        % struct array with fevalable cell arrays to call as a batch
        calls;
        
        % true or false, whether to run indefinitely
        alwaysRunning = false;
    end
    
    properties (Hidden)
        % string default name for added calls
        defaultName = 'call';
    end
    
    methods
        % Add an "fevalable" to the call list.
        % @param fevalable a cell array with contents to pass to feval()
        % @param name optional string name to assign to @a fevalable
        % @details
        % Appends or inserts the given @a fevalable to the calls struct
        % array.  If @a name is provided, @a fevalable can be referred to
        % later by @a name.  It will replace any existing fevalable with
        % the same name.  If @a name is omitted, addCall() assigns a
        % generic name and appends @a fevalable to the end of the calls
        % array.
        % @details
        % Returns the index into the calls struct array where @a fevalable
        % was appended or inserted.
        function index = addCall(self, fevalable, name)
            if nargin < 3
                name = self.defaultName;
            end
            
            newCall = struct( ...
                'fevalable', {fevalable}, ...
                'name', name, ...
                'isActive', true);
            
            if isempty(self.calls)
                % initialize the calls struct array
                index = 1;
                self.calls = newCall;
                
            else
                if strcmp(name, self.defaultName);
                    % append with the default name
                    index = numel(self.calls) + 1;
                    
                else
                    names = {self.calls.name};
                    isReplacement = strcmp(name, names);
                    if any(isReplacement)
                        % replace by matching name
                        index = find(isReplacement, 1, 'first');
                        
                    else
                        % append with the new name
                        index = numel(self.calls) + 1;
                    end
                end
                
                self.calls(index) = newCall;
            end
        end
        
        % Toggle whether a call is active.
        % @param name given to an fevalable during addCall()
        % @param isActive true or false, whether to invoke the named
        % fevalable during runBriefly()
        % @details
        % Determines whether the named fevalable function call in the calls
        % struct array will be invoked during runBriefly().  If multiple
        % calls have the same name, @a isActive will be applied to all of
        % them.
        function setActiveByName(self, isActive, name)
            named = strcmp({self.calls.name}, name);
            [self.calls(named).isActive] = deal(isActive);
        end
        
        % Invoke active calls in a batch.
        function runBriefly(self)
            if ~isempty(self.calls)
                isActive = [self.calls.isActive];
                fevalables = {self.calls(isActive).fevalable};
                for ii = 1:length(fevalables)
                    feval(fevalables{ii}{:});
                end
                self.isRunning = self.isRunning && self.alwaysRunning;
            end
        end
    end
end
