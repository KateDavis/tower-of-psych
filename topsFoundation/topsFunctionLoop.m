classdef topsFunctionLoop < handle
    properties (SetObservable)
        modeList;
        proceed = true;
        clockFcn = @topsTimer;
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
        
        function runInModeForDuration(self, mode, duration)
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
            
            self.proceed = true;
            nowTime = feval(self.clockFcn);
            endTime = nowTime + duration;
            while (nowTime <= endTime) && self.proceed
                for ii = 1:n
                    feval(functionLoop{ii}{:});
                end
                nowTime = feval(self.clockFcn);
            end
        end
        
        function previewForMode(self, mode)
            % build new mode that prints function summaries
            realFunctionLoop = self.getFunctionListForMode(mode);
            previewMode = sprintf('preview_of_%s', mode);
            for ii = 1:length(realFunctionLoop)
                preview = sprintf('%s: %s', previewMode, summarizeFcn(realFunctionLoop{ii}));
                previewFcn = {@disp, preview};
                    self.addFunctionToModeWithPrecedence(previewFcn, previewMode, -ii);
            end
            self.runInModeForDuration(previewMode, 0);
        end
    end
end