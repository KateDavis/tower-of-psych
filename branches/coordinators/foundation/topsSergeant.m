classdef topsSergeant < topsSteppable
    % @class topsSergeant
    % Compose topsSteppable objects and run them concurrently.
    % @details
    % topsSergeant objects may contain other topsSteppable objects and run
    % them concurrently.  It uses the metaphor of a drill sergeant, whose
    % job it is to keep oters stepping at the same rate.  When a
    % topsSergeant run()s, it will invoke step() sequentially and
    % repeatedly for each of the steppable objects in its components array.
    % The topsSergeant will stop running as soon as one of its components
    % has isRunning equal to false.
    % @ingroup foundation
    
    properties (SetObservable)
        % topsList of steppable objects to be run() concurrently
        components;
        
        % logical array reflecting isRunning for each object in components
        componentIsRunning;
    end
    
    methods
        % Constructor takes no arguments.
        function self = topsSergeant
            self.components = topsList;
            self.componentIsRunning = false(0,0);
        end
        
        % Do a little flow control with each object in components.
        % @details
        % topsSergeant extends the step() method of topsSteppable.  It
        % calls step() sequentialy for each of the topsSteppable objects in
        % its components array.
        % @details
        % If any of the objects in components has isRunning equal to false,
        % this topsSergeant object will set its own isRunning to false (and
        % therefore it should stop running).
        function step(self)
            components = self.components.allItems;
            for ii = 1:length(components)
                components{ii}.step;
                self.componentIsRunning(ii) = components{ii}.isRunning;
            end
            self.isRunning = sum(self.componentIsRunning) > 0;
        end
        
        % Prepare each object in components to do flow control.
        % @details
        % topsSergeant extends the start() method of topsSteppable.  It
        % calls start() sequentialy for each of the topsSteppable objects
        % in its components array.
        function start(self)
            self.start@topsSteppable;
            components = self.components.allItems;
            for ii = 1:length(components)
                components{ii}.start;
            end
            self.componentIsRunning = true(size(components));
        end
        
        % Let each object in components finish doing flow control.
        % @details
        % topsSergeant extends the finish() method of topsSteppable.  It calls
        % finish() sequentialy for each of the topsSteppable objects in
        % its components array.
        function finish(self)
            self.finish@topsSteppable;
            components = self.components.allItems;
            for ii = 1:length(components)
                components{ii}.finish;
            end
            self.componentIsRunning = false(size(components));
        end
    end
end