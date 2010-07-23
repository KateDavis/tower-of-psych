classdef topsSergeant < topsRunnableComposite
    % @class topsSergeant
    % Composes topsSteppable objects and runs them concurrently.
    % @details
    % topsSergeant objects may contain topsSteppable objects and run
    % them concurrently.  It uses the metaphor of a drill sergeant, whose
    % job it is to keep others stepping at the same rate.  When a
    % topsSergeant run()s, it invokes step() sequentially and
    % repeatedly for each of its component objects.  The topsSergeant will
    % stop running as soon as one of its children has isRunning equal to
    % false.
    % @ingroup foundation
    
    properties (SetObservable)
        % logical array reflecting isRunning for each child object
        childIsRunning;
    end
    
    methods
        % Add a topsSteppable child beneath this object.
        % @param child a topsSteppable to add beneath this object.
        % @details
        % Rede the addChild() method of topsRunnableComposite to verify
        % that @a child is a topsSteppable (or subclass) object.
        function addChild(self, child)
            if isa(child, 'topsSteppable')
                self.addChild@topsRunnableComposite(child);
            else
                warning('% cannot add child of class %s', ...
                    class(self), class(child));
            end
        end
        
        % Interleave stepping behavior of child objects.
        % @details
        % Calls start() for each child object, then calls step() repeatedly
        % and sequentially for each child, until at least one child no
        % longer isRunning, then calls finish() for each child.
        % @details
        % The since all the child objects should step() the same number of
        % times and in an interleaved fashion, they should all appear to
        % run together.
        function run(self)
            self.start;
            self.startChildren;
            
            while self.isRunning
                self.stepChildren;
            end
            
            self.finishChildren;
            self.finish;
        end
        
        
        % Do a little flow control with each child object.
        % @details
        % Calls step() once, sequentually, for each child object.
        % @details
        % If any of the child objects has isRunning equal to false, this
        % topsSergeant object will set its own isRunning to false (and
        % therefore it should stop running).
        function stepChildren(self)
            nComponents = length(self.children);
            if nComponents > 0
                for ii = 1:nComponents
                    self.children{ii}.step;
                    self.childIsRunning(ii) = ...
                        self.children{ii}.isRunning;
                end
                self.isRunning = all(self.childIsRunning);
            else
                self.isRunning = false;
            end
        end
        
        % Prepare each child object to do flow control.
        % @details
        % Calls start() once, sequentually, for each child object.
        function startChildren(self)
            for ii = 1:length(self.children)
                self.children{ii}.start;
            end
            self.childIsRunning = true(size(self.children));
        end
        
        % Let each child object finish doing flow control.
        % @details
        % Calls finish() once, sequentually, for each child object.
        function finishChildren(self)
            for ii = 1:length(self.children)
                self.children{ii}.start;
            end
            self.childIsRunning = false(size(self.children));
        end
    end
end