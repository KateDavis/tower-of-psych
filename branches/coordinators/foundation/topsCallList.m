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
    % @ingroup foundation
    
    properties (SetObservable)
        % cell array of fevalable cell arrays to call as a batch
        fevalables;
    end
    
    methods
        % Constructor takes no arguments.
        function self = topsCallList
        end
        
        % 
    end
end