classdef topsFunctionLoop < handle
    properties (SetObservable)
        modeList;
        proceed = true;
        clockFcn = @now;
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
            functionList = self.modeList.getAllItemsFromModeSorted(mode);
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
            
            self.proceed = true;
            tt = 0;
            nowTime = feval(self.clockFcn);;
            endTime = nowTime + duration;
            while (nowTime <= endTime) && self.proceed
                whens = zeros(1,n);
                for ii = 1:n
                    nowTime = feval(self.clockFcn);
                    whens(ii) = nowTime;
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