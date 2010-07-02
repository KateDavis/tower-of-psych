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
    
    properties
        % cell array of topsSteppable objects to be run() concurrently
        components;
        
        % logical array reflecting isRunning for each object in components
        componentIsRunning;
    end
    
    methods
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
            for ii = 1:length(self.components)
                self.components{ii}.step;
                self.componentIsRunning(ii) = ...
                    self.components{ii}.isRunning;
            end
            self.isRunning = all(self.componentIsRunning);
        end
        
        % Prepare each object in components to do flow control.
        % @details
        % topsSergeant extends the start() method of topsSteppable.  It
        % calls start() sequentialy for each of the topsSteppable objects
        % in its components array.
        function start(self)
            self.start@topsSteppable;
            for ii = 1:length(self.components)
                self.components{ii}.start;
            end
            self.componentIsRunning = true(size(self.components));
        end
        
        % Let each object in components finish doing flow control.
        % @details
        % topsSergeant extends the finish() method of topsSteppable.  It calls
        % finish() sequentialy for each of the topsSteppable objects in
        % its components array.
        function finish(self)
            self.finish@topsSteppable;
            for ii = 1:length(self.components)
                self.components{ii}.finish;
            end
            self.componentIsRunning = false(size(self.components));
        end
        
        % Add a topsSteppable object to the components array.
        % @param steppable topsSteppable object to run concurrently with
        % other steppable objects in the components array.
        % @param index optional index into components where to insert @a
        % steppable
        % @details
        % addComponent() inserts @a steppable into this topsSergeant's
        % components array, at the given @a index.  If no @a index is
        % given, appends @a steppable to the end of components.
        % @details
        % Returns the index into the components array where @asteppable was
        % inserted.
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
        % @param steppable topsSteppable object that should no longer run
        % concurrently with other components.
        % @details
        % removeComponent() removes all instances of @a steppable from
        % this topsSergeant's components array.
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