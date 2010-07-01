classdef topsWheel < topsSteppable
    % @class topsWheel
    % Compose topsSteppable objects and run them concurrently.
    % @details
    % topsWheel objects may contain other topsSteppable objects and run
    % them concurrently.  It uses a metaphor of a wheel with facets on it:
    % as a wheel turns each facet may pass over the top of the wheel in
    % sequence. Likewise, as a topsWheel object run()s, it will step() each
    % of its facet objects in sequence.  The object will keep run()nign as
    % long as isRunning is true for all of its facets.
    % @ingroup foundation
    
    properties
        % cell array of topsSteppable objects to be run() concurrently
        facets;
        
        % logical array reflecting isRunning for each object in facets
        facetIsRunning;
    end
    
    methods
        % Do a little flow control with each facets object
        % @details
        % topsWheel extends the step() method of topsSteppable.  It calls
        % step() on each of the topsSteppable objects in facets.
        % @details
        % If any of the facets objects has isRunning equal to false, this
        % topsWheel object will set its own isRunning to false (and
        % therefore it will stop running).
        function step(self)
            for ii = 1:length(self.facets)
                self.facets{ii}.step;
                self.facetIsRunning(ii) = self.facets{ii}.isRunning;
            end
            self.isRunning = all(self.facetIsRunning);
        end
        
        % Prepare each facets object to do flow control.
        % @details
        % topsWheel extends the start() method of topsSteppable.  It calls
        % start() on each of the topsSteppable objects in facets.
        function start(self)
            self.start@topsSteppable;
            for ii = 1:length(self.facets)
                self.facets{ii}.start;
            end
            self.facetIsRunning = true(size(self.facets));
        end
        
        % Let each facets object finish doing flow control.
        % @details
        % topsWheel extends the finish() method of topsSteppable.  It calls
        % finish() on each of the topsSteppable objects in facets.
        function finish(self)
            self.finish@topsSteppable;
            for ii = 1:length(self.facets)
                self.facets{ii}.finish;
            end
            self.facetIsRunning = false(size(self.facets));
        end
    end
end