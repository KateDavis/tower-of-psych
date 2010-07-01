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
        % If any of the objects in components has isRunning equal to false,
        % this topsWheel object will set its own isRunning to false (and
        % therefore it should stop running).
        function step(self)
            for ii = 1:length(self.components)
                self.components{ii}.step;
                self.componentIsRunning(ii) = ...
                    self.components{ii}.isRunning;
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
        
        % Add a topsSteppable object to the components array.
        % @param steppable topsSteppable object to run concurrently with
        % other objects in components.
        % @param index optional index into components where to insert @a
        % steppable
        % @details
        % addComponent() inserts @a steppable into this topsWheel's
        % components array, at the given @a index.  If no @a index is
        % given, appends @a steppable to the end of components.
        % @details
        % Returns as an optional output the index into components where @a
        % steppable was inserted.
        function index = addComponent(self, steppable, index)
            l = length(self.components) + 1;
            if nargin < 3 || isempty(index)
                index = l;
            end
            comps = cell(1, l);
            selector = false(1, l);
            selector(index) = true;
            comps{selector} = steppable;
            comps(~selector) = self.components;
            self.components = comps;
        end
        
        % Remove a topsSteppable object from the components array.
        % @param steppable topsSteppable object to stop running
        % concurrently with other components.
        % @details
        % removeComponent() removes all instances of @a steppable from
        % this topsWheel's components array.
        function removeComponent(self, steppable)
            if isempty(steppable)
                return
            end
            l = length(self.components);
            selector = false(1, l);
            for ii = 1:l
                selector(ii) = self.components{ii} == steppable;
            end
            self.components = self.components(~selector);
        end
    end
end