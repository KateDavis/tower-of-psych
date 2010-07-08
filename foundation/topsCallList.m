classdef topsCallList < topsSteppable
    % @class topsCallList
    % A list of functions to call sequentially, as a batch.
    % topsCallList manages a list of functions to be called as a batch.
    % @details
    % Since topsCallList extends topsSteppable, a topsCallList object can
    % be added as one of the components of a topsSergeant object, and its
    % batch of functions can be invoked "in step" with other steppable
    % objects.
    % @details
    % A topsCallList object has no internal state to keep track of, so it
    % has no natural way to decide when it's done running.  The
    % alwaysRunning property determines whether the object should be
    % considered running following each call to step().
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
    % @ingroup foundation
    
    properties (SetObservable)
        % cell array of fevalable cell arrays to call as a batch
        fevalables = {};
        
        % true or false, whether to run indefinitely
        alwaysRunning = false;
    end
    
    methods
        % Add an "fevalable" to the call list.
        % @param fevalable a cell array whose contents to pass to feval()
        % @param index optional index where to insert @a fevalable
        % @details
        % Adds the given @a fevalable to the list of calls in fevalables.
        % If @a index is provided, inserts @a fevalable at @a index and
        % shifts other elements of fevalables as needed.
        % @details
        % Returns the index into fevalables where @a fevalable was
        % appended or insterted.
        function index = addCall(self, fevalable, index)
            if nargin > 2
                self.fevalables = topsFoundation.cellAdd( ...
                    self.fevalables, fevalable, index);
            else
                self.fevalables = topsFoundation.cellAdd( ...
                    self.fevalables, fevalable);
            end
        end
        
        % Invoke all fevalables in a batch.
        function step(self)
            self.logAction(self.stepString);
            for ii = 1:length(self.fevalables)
                feval(self.fevalables{ii}{:});
            end
            self.isRunning = self.isRunning && self.alwaysRunning;
        end
    end
end