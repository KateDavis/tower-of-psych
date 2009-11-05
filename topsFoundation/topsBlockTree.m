classdef topsBlockTree < handle
    % @class topsBlockTree
    % A tree-like way to organize an experiment.
    % topsBlockTree gives you a uniform, tree-like framework for organizing
    % the different components of an experiment.  All levels of
    % organization--trials, sets of trials, tasks, paradigmns, whole 
    % experiments--can be represented by interconnected topsBlockTree 
    % objects, or "blocks".
    % <br><br>
    % Every block can have a parent and some children, which are also
    % blocks.  You start an experiment by "running" the topmost parent
    % block.  It performs some actions and then "runs" each of its
    % children.  Each child it performs its own actions and "runs" each of
    % its own children.  Those children in turn perform actions and "run"
    % their children, and so on until reaching the bottom of the tree where
    % there  is a block without any children.
    % <br><br>
    % Then it's back up the tree.  On the way up, each child block performs
    % a final action.  When a parent finishes "running" all of its
    % children, it performs its own final action.  Then <em>its</em> parent
    % can finish up in the same way, and so on, until reaching the topmost
    % parent again.  At that point the experiment is done.
    % <br><br>
    % Of course, that's just the structure of the experiment.  The details
    % have to be defined elsewhere and invoked when each block performs its
    % actions.
    % <br><br>
    % Many psychophysics experiments use a tree structure implicitly, along
    % with a similar down-then-up flow of behavior.  topsBlockTree makes
    % the stucture and flow explicit, which offers some advantages:
    %   - You can extend your task arbitrarily, without running out of
    %   vocabulary words like "task" "block", "subblock", "trial",
    %   "intertrial", etc.  They can all be blocks!  What's important is
    %   how the blocks are connected.
    %   - You can easily view the structure of your experiment using the
    %   topsBlockTree.gui() method.
    
    properties (SetObservable)
        % a string name for this block
        name = '';
        
        % any value or object you want
        userData = [];
        
        % number of times to run through this block's children
        iterations = 1;
        
        % how to run through this block's children--'sequential' or
        % 'random' order
        iterationMethod = 'sequential';
        
        % array of topsBlockTree children
        children;
        
        % a parent topsBlockTree
        parent;
        
        % action to perform before iterating through any children
        blockStartFcn = {};
        
        % action to perform before each iteration
        blockActionFcn = {};
        
        % action to perform after all iterations
        blockEndFcn = {};
    end
    
    properties(Hidden)
        startString = 'start';
        actionString = 'action';
        endString = 'end';
        validIterationMethods = {'sequential', 'random'};
    end
    
    events
        % Notifies any listeners just before performing any actions or
        % iterations
        BlockStart;
    end
   
    methods
        % Constructor takes no arguments
        function self = topsBlockTree
            self.children = topsBlockTree.empty;
            self.parent = topsBlockTree.empty;
        end
        
        % Launch a graphical interface for this block and its children.
        % Returns a handle to the new topsBlockTreeGUI
        function g = gui(self)
            g = topsBlockTreeGUI(self);
        end
        
        % Add a child beneath this block
        % @param child a topsBlockTree to add beneath this block.
        % @details
        % Sets the parent property of the <em>child</em> to be this
        % block, and appends <em>child</em> to the children property of
        % this block.
        function addChild(self, child)
            child.parent = self;
            self.children(end+1) = child;
        end
        
        % Run an experiment, starting with this block.
        % @param doFeval true or false, whether to perform any actions
        % (true, the default), or just traverse the tree (false).
        % @details
        % Begin traversing the tree with this block as the topmost parent.
        % The sequence of events goes like this:
        %   - This block sends a 'BlockStart' notification to any
        %   listeners.
        %   - This block executes its blockStartFcn (if doFeval is true)
        %   - This block does zero or more "iterations":
        %       - This block executes its blockActionFcn (if doFeval is
        %       true)
        %       - This block calls run() on each of its children,
        %       in an order determined by this block's iterationMethod.
        %       Each child then performs the same sequence of actions as
        %       this block.
        %   - This block executes its blockEndFcn (if doFeval is true)
        %   .
        % Note that the sequence of events is recursive.  Thus, the
        % behavior of run() depends on this block as well as its children,
        % their children, etc.
        % <br><br>
        % Also note that the recursion happens in the middle of the
        % sequence of events.  Thus, all of the blockStartFcn and
        % blockActionFcns will happen first, in the order of parents before
        % children.  Then all the blockEndFcns will happen, in the order of
        % children before parents.
        function run(self, doFeval)
            if nargin < 2
                doFeval = true;
            end
            
            % notify listeners, like the GUI
            self.notify('BlockStart');
            
            % start the block
            self.fevalAndLog(self.startString, self.blockStartFcn, doFeval);
            
            % do the meat of the block
            for ii = 1:self.iterations
                self.fevalAndLog(self.actionString, self.blockActionFcn, doFeval);
                
                switch self.iterationMethod
                    case 'sequential'
                        childSequence = 1:length(self.children);
                    case 'random'
                        childSequence = randperm(length(self.children));
                end
                
                for jj = childSequence
                    self.children(jj).run(doFeval);
                end
            end
            
            % finish the block
            self.fevalAndLog(self.endString, self.blockEndFcn, doFeval);
        end
        
        % Shorthand for run() method with doFeval = false.
        function preview(self)
            self.run(false);
        end
        
        function fevalAndLog(self, note, fcn, doFeval)
            if ~isempty(fcn)
                if doFeval
                    group = sprintf('%s:%s', self.name, note);
                    topsDataLog.logDataInGroup(fcn, group);
                    feval(fcn{:});
                else
                    group = sprintf('%s:%s(preview)', self.name, note);
                    topsDataLog.logDataInGroup(fcn, group);
                end
            end
        end
        
        function set.iterationMethod(self, iterationMethod)
            if any(strcmp(iterationMethod, self.validIterationMethods))
                self.iterationMethod = iterationMethod;
            else
                warning(sprintf('%s.iterationMethod may be %s', ...
                    mfilename, sprintf('"%s", ', self.validIterationMethods{:})));
            end
        end
    end
end