classdef topsConcurrentComposite < topsRunnableComposite
    % @class topsConcurrentComposite
    % Composes topsConcurrent objects and runs them concurrently.
    % @details
    % topsConcurrentComposite objects may contain topsConcurrent objects and run
    % them concurrently.  When a
    % topsConcurrentComposite run()s, it invokes runBriefly() sequentially and
    % repeatedly for each of its component objects.  The topsConcurrentComposite will
    % stop running as soon as one of its children has isRunning equal to
    % false.
    % @ingroup foundation
    
    properties (SetObservable)
        % logical array reflecting isRunning for each child object
        childIsRunning;
    end
    
    methods
        % Add a topsConcurrent child beneath this object.
        % @param child a topsConcurrent to add beneath this object.
        % @details
        % Extends the addChild() method of topsRunnableComposite to verify
        % that @a child is a topsConcurrent (or subclass) object.
        function addChild(self, child)
            if isa(child, 'topsConcurrent')
                self.addChild@topsRunnableComposite(child);
            else
                warning('% cannot add child of class %s', ...
                    class(self), class(child));
            end
        end
        
        % Interleave runBriefly() behavior of child objects.
        % @details
        % Calls start() for each child object, then calls runBriefly() repeatedly
        % and sequentially for each child, until at least one child no
        % longer isRunning, then calls finish() for each child.
        % @details
        % The since all the child objects should runBriefly() the same number of
        % times and in an interleaved fashion, they should all appear to
        % run together.
        function run(self)
            self.start;
            self.startChildren;
            
            while self.isRunning
                self.runChildren;
            end
            
            self.finishChildren;
            self.finish;
        end
        
        
        % Do a little flow control with each child object.
        % @details
        % Calls runBriefly() once, sequentually, for each child object.
        % @details
        % If any of the child objects has isRunning equal to false, this
        % topsConcurrentComposite object will set its own isRunning to false (and
        % therefore it should stop running).
        function runChildren(self)
            nComponents = length(self.children);
            if nComponents > 0
                for ii = 1:nComponents
                    self.children{ii}.runBriefly;
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