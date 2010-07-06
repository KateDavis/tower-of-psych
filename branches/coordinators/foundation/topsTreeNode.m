classdef topsTreeNode < topsRunnable
    % @class topsTreeNode
    % A tree-like way to organize an experiment.
    % @details
    % topsTreeNode gives you a uniform, tree-like framework for organizing
    % the different components of an experiment.  All levels of
    % organization--trials, sets of trials, tasks, paradigmns, whole
    % experiments--can be represented by interconnected topsTreeNode
    % objects, as one large tree.
    % @details
    % Every node can have a parent and some children, which are also
    % nodes.  You start an experiment by calling run() on the topmost
    % parent node.  It may invoke a "start" function and then calls run()
    % each of its child nodes.  Each child does the same, invoking its own
    % "start" function and then invoking run() on each of its children.
    % This flow of "start" and run() continues until it reaches the bottom
    % of the tree where there is a node that has no children.
    % @details
    % Then it's back up the tree.  On the way up, each child may invoke its
    % "finish" function before passing control back to its parent node.
    % Once a parent finishes run()ning all of its children, it may invoke
    % its own "finish" function, and so one, until the flow reaches the
    % topmost node again.  At that point the experiment is done.
    % @details
    % topsTreeNode only treats the structure of an experiment.  The details
    % have to be defined elsewhere, as in specific "start" and "finish"
    % functions.  Any object that has a run() method may function as a
    % child node at the bottom of the tree (a "leaf").  topsRunnable
    % objects like topsCallList and topsStateMachine provide rich ways to
    % organize trial details.
    % @details
    % Many psychophysics experiments use a tree structure implicitly, along
    % with a similar down-then-up flow of behavior.  topsTreeNode makes
    % the stucture and flow explicit, which offers some advantages:
    %   - You can extend your task structure arbitrarily, without running
    %   out of vocabulary words or hard-coded concepts like "task" "block",
    %   "subblock", "trial", "intertrial", etc.
    %   - You can visualize the structure of your experiment using the
    %   topsTreeNode.gui() method.
    % @ingroup foundation
    
    properties (SetObservable)
        % number of times to run through this node's children
        iterations = 1;
        
        % count of iterations while running
        iterationCount = 0;
        
        % how to run through this node's children--'sequential' or
        % 'random' order
        iterationMethod = 'sequential';
        
        % topsList of runnable children
        children;
        
        % a parent topsTreeNode
        parent = topsTreeNode.empty;
    end
    
    properties (Hidden)
        validIterationMethods = {'sequential', 'random'};
    end
    
    methods
        % Constructor takes no arguments
        function self = topsTreeNode
            self = self@topsRunnable;
            self.children = topsList;
        end
        
        % Add a child beneath this node.
        % @param child a topsTreeNode to add beneath this node.
        % @details
        % Sets the parent property of the @a child to be this
        % node, and appends @a child to the children property of
        % this node.
        function addChild(self, child)
            self.children.add(child);
            if isprop(child, 'parent')
                child.parent = self;
            end
        end
        
        % Create a new child and add it beneath this node.
        % @details
        % Returns a new topsTreeNode which is a child of this node and
        % whose parent is this node.
        function child = newChild(self)
            child = topsTreeNode;
            self.addChild(child);
        end
        
        % Recursively run(), starting with this node.
        % @details
        % Begin traversing the tree with this node as the topmost parent.
        % The sequence of events should go like this:
        %   - This node sends a 'RunStart' notification to any
        %   listeners.
        %   - This node executes its startFevalable
        %   - This node does zero or more "iterations":
        %       - This node calls run() on each of its children,
        %       in an order determined by this node's iterationMethod.
        %       Each child then performs the same sequence of actions as
        %       this node.
        %   - This node executes its finishFevalable
        %   .
        % Note that the sequence of events is recursive.  Thus, the
        % behavior of run() depends on this node as well as its children,
        % their children, etc.
        % @details
        % Also note that the recursion happens in the middle of the
        % sequence of events.  Thus, startFevalables will tend
        % to happen first, in the order of parents before children.  Then
        % finishFevalables will tend to happen last, in the order of
        % children before parents.
        function run(self)
            self.logAction(self.startString);
            self.notify('RunStart');
            self.logFeval(self.startString, self.startFevalable);
            
            % recursive
            try
                for ii = 1:self.iterations
                    self.iterationCount = ii;
                    nChildren = self.children.length;
                    switch self.iterationMethod
                        case 'random'
                            childSequence = randperm(nChildren);
                            
                        otherwise
                            childSequence = 1:nChildren;
                            
                    end
                    
                    children = self.children.allItems;
                    for jj = childSequence
                        children{jj}.run;
                    end
                end
                
            catch recurErr
                warning(recurErr.identifier, '%s named %s failed:', ...
                    class(self), self.name, recurErr.message);

                % attempt to clean up despite error
                try
                    self.logAction(self.finishString);
                    self.notify('RunFinish');
                    self.logFeval(self.finishString, self.finishFevalable);

                catch finishErr
                    warning(finishErr.identifier, '%s named %s failed to finish:', ...
                        class(self), self.name, finishErr.message);
                end
                    
                rethrow(recurErr)
            end
            
            self.logAction(self.finishString);
            self.notify('RunFinish');
            self.logFeval(self.finishString, self.finishFevalable);
        end
    end
end