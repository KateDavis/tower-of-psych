classdef topsFunctionLoop < handle
    properties
        modeList;
        clockFcn = @cputime;
    end
    
    methods
        function self = topsFunctionLoop
            self.modeList = topsModalList;
        end
        
        function addFunctionToModeWithPrecedence(self, fcn, mode, precedence)
            self.modeList.addItemToModeWithMnemonicWithPrecedence ...
                (fcn, mode, '', precedence);
        end
        
        function functionList = getFunctionListForMode(self, mode)
            functionList = self.modeList.getSortedItemsForMode(mode);
        end
        
        function [when, what] = runInModeForDuration(self, mode, duration)
            if nargin < 3 || isempty(duration)
                duration = 0;
            end
            if ~isfinite(duration)
                duration = 0;
            end
            
            % run whole passes through loop until duration
            %   for now, punt on timeStamps preallocation
            functionLoop = self.getFunctionListForMode(mode);
            n = length(functionLoop);
            timeStamps = cell(1, n*1e5);
            
            tt = 0;
            now = feval(self.clockFcn);;
            endTime = now + duration;
            while now <= endTime
                whens = zeros(1,n);
                for ii = 1:n
                    now = feval(self.clockFcn);
                    whens(ii) = now;
                    feval(functionLoop{ii}{:});
                end
                tt = tt+1;
                timeStamps{tt} = whens;
            end
            
            % summary of loop iterations
            when = [timeStamps{1:tt}];
            what = repmat(functionLoop, 1, tt);
        end
        
        function [what, when] = previewForMode(self, mode)
            % build mode that prints function summaries
            realFunctionLoop = self.getFunctionListForMode(mode);
            previewMode = sprintf('preview_of_%s', mode);
            for ii = 1:length(realFunctionLoop)
                preview = sprintf('%s: %s', previewMode, summarizeFcn(realFunctionLoop{ii}));
                previewFcn = {@disp, preview};
                    self.addFunctionToModeWithPrecedence(previewFcn, previewMode, -ii);
            end
            [what, when] = self.runInModeForDuration(previewMode, 0);
        end
    end
end