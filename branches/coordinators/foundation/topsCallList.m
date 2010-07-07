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
        % topsList of fevalable cell arrays to call as a batch
        fevalables;
        
        % true or false, whether to run indefinitely
        alwaysRunning = true;
    end
    
    methods
        % Constructor takes no arguments.
        function self = topsCallList
            self.fevalables = topsList;
        end
        
        % Invoke fevalables in a batch.
        function step(self)
            self.logAction(self.stepString);
            batch = self.fevalables.allItems;
            for ii = 1:length(batch)
                feval(batch{ii}{:});
            end
            self.isRunning = self.isRunning && self.alwaysRunning;
        end
    end
end