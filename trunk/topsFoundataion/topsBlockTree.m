classdef topsBlockTree < handle
    properties
        name = '';
        userData = [];
        
        iterations = 1;
        iterationMethod = 'sequential';
        
        children = topsBlockTree.empty;
        parent = topsBlockTree.empty;
        
        blockBeginFcn = {};
        blockActionFcn = {};
        blockEndFcn = {};
        
        clockFcn = @cputime;
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
        
        function summary = run(self, doFeval)
            if nargin < 2
                doFeval = true;
            end
            
            % allocate for summary of fevals and child blocks
            numberOfFevals = 2+self.iterations*(1 + length(self.children));
            summary = cell(numberOfFevals, 3);
            
            % begin the block
            summary = self.fevalWithSummary(summary, 'start', self.blockBeginFcn, doFeval, 1);
            
            % do the meat of the block
            index = 1;
            for ii = 1:self.iterations
                index = index+1;
                summary = self.fevalWithSummary(summary, 'action', self.blockActionFcn, doFeval, index);
                
                switch self.iterationMethod
                    case 'sequential'
                        childSequence = 1:length(self.children);
                    case 'random'
                        childSequence = randperm(length(self.children));
                end
                
                for jj = childSequence
                    index = index+1;
                    child = self.children(jj);
                    summary{index, 1} = feval(self.clockFcn);
                    summary{index, 2} = 'sub-block';
                    summary{index, 3} = self.children(jj).run(doFeval);
                end
            end
            
            % finish the block
            summary = self.fevalWithSummary(summary, 'end', self.blockEndFcn, doFeval, numberOfFevals);
        end
        
        function summary = preview(self)
            summary = self.run(false);
        end
        
        function summary = fevalWithSummary(self, summary, note, fcn, doFeval, index)
            summary{index, 1} = feval(self.clockFcn);
            if doFeval
                feval(fcn{:});
            end
            
            summary{index, 2} = sprintf('%s:%s', self.name, note);
            if isempty(fcn)
                summary{index, 3} = '(no function)';
            else
                summary{index, 3} = summarizeFcn(fcn);
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
        
        function unrolled = unrollSummary(self, summary)
            unrolled = cell(0, size(summary, 2));
            for ii = 1:size(summary, 1)
                if iscell(summary{ii,end})
                    unrolled = cat(1, unrolled, self.unrollSummary(summary{ii,end}));
                else
                    unrolled = cat(1, unrolled, summary(ii,:));
                end
            end
        end
    end
end