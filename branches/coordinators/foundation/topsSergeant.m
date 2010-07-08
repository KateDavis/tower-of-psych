classdef topsSergeant < topsSteppable
    % @class topsSergeant
    % Compose topsSteppable objects and run them concurrently.
    % @details
    % topsSergeant objects may contain other topsSteppable objects and run
    % them concurrently.  It uses the metaphor of a drill sergeant, whose
    % job it is to keep others stepping at the same rate.  When a
    % topsSergeant run()s, it invokes step() sequentially and
    % repeatedly for each of its component objects.  The topsSergeant will
    % stop running as soon as one of its components has isRunning equal to
    % false.
    % @ingroup foundation
    
    properties (SetObservable)
        % cell array of steppable objects to be run() concurrently
        components = {};
        
        % logical array reflecting isRunning for each object in components
        componentIsRunning;
    end
    
    methods
        % Add a topsSteppable "component".
        % @param steppable a topsSteppable object
        % @param index optional index where to insert @a steppable
        % @details
        % Adds the given @a steppable to the components array.
        % If @a index is provided, inserts @a steppable at @a index and
        % shifts other elements of components as needed.
        % @details
        % Returns the index into components where @a steppable was
        % appended or insterted.
        function index = addComponent(self, steppable, index)
            if nargin > 2
                self.components = topsFoundation.cellAdd( ...
                    self.components, steppable, index);
            else
                self.components = topsFoundation.cellAdd( ...
                    self.components, steppable);
            end
        end

        % Constructor takes no arguments.
        function self = topsSergeant
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
            nComponents = length(self.components);
            if nComponents > 0
                for ii = 1:nComponents
                    self.components{ii}.step;
                    self.componentIsRunning(ii) = ...
                        self.components{ii}.isRunning;
                end
                self.isRunning = all(self.componentIsRunning);
            else
                self.isRunning = false;
            end
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
    end
end