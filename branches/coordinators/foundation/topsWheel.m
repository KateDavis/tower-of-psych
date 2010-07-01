classdef topsWheel < topsSteppable
    % @class topsWheel
    % Compose topsSteppable objects and run them concurrently.
    % @details
    % topsWheel objects may contain other topsSteppable objects and run
    % them concurrently.  It uses the metaphor of a turning wheel, parts of
    % which may pass over the top over and over again, in sequence.
    % Likewise, as a topsWheel run()s, it will step() each of its
    % components over and over again, in sequence.  Since they will step()
    % with the same frequency, they should appear to run all at once.  The
    % topsWheel will stop running as soon as one of its components has
    % isRunning equal to false.
    % @ingroup foundation
    
    properties
        % cell array of topsSteppable objects to be run() concurrently
        components;
        
        % logical array reflecting isRunning for each object in components
        componentIsRunning;
    end
    
    methods
        % Do a little flow control with each object in components.
        % @details
        % topsWheel extends the step() method of topsSteppable.  It calls
        % step() on each of the topsSteppable objects in components.
        % @details
        % If any of the components objects has isRunning equal to false,
        % this topsWheel object will set its own isRunning to false (and
        % therefore it should stop running).
        function step(self)
            for ii = 1:length(self.components)
                self.components{ii}.step;
                self.componentIsRunning(ii) = self.components{ii}.isRunning;
            end
            self.isRunning = all(self.componentIsRunning);
        end
        
        % Prepare each object in components to do flow control.
        % @details
        % topsWheel extends the start() method of topsSteppable.  It calls
        % start() on each of the topsSteppable objects in components.
        function start(self)
            self.start@topsSteppable;
            for ii = 1:length(self.components)
                self.components{ii}.start;
            end
            self.componentIsRunning = true(size(self.components));
        end
        
        % Let each object in components finish doing flow control.
        % @details
        % topsWheel extends the finish() method of topsSteppable.  It calls
        % finish() on each of the topsSteppable objects in components.
        function finish(self)
            self.finish@topsSteppable;
            for ii = 1:length(self.components)
                self.components{ii}.finish;
            end
            self.componentIsRunning = false(size(self.components));
        end
    end
end