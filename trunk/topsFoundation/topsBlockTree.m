classdef topsBlockTree < handle
    properties (SetObservable)
        name = '';
        userData = [];
        
        iterations = 1;
        iterationMethod = 'sequential';
        
        children = topsBlockTree.empty;
        parent = topsBlockTree.empty;
        
        blockBeginFcn = {};
        blockActionFcn = {};
        blockEndFcn = {};
    end
    
    events
        BlockBegin;
    end
    
    properties(Hidden = true)
        validIterationMethods = {'sequential', 'random'};
    end
    
    methods
        function self = topsBlockTree
        end
        
        function addChild(self, child)
            child.parent = self;
            self.children(end+1) = child;
        end
        
        function run(self, doFeval)
            if nargin < 2
                doFeval = true;
            end
            
            % notify listeners, like the GUI
            self.notify('BlockBegin');
            
            % begin the block
            self.fevalAndLog('start', self.blockBeginFcn, doFeval);
            
            % do the meat of the block
            for ii = 1:self.iterations
                self.fevalAndLog('action', self.blockActionFcn, doFeval);
                
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
            self.fevalAndLog('end', self.blockEndFcn, doFeval);
        end
        
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