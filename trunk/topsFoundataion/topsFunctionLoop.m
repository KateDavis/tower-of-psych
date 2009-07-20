classdef topsFunctionLoop < handle
    properties
        currentMode;
        modes;
        clockFcn = @cputime;
    end
    
    properties(Hidden = true)
        defaultModeName = 'default';
    end
    
    methods
        function self = topsFunctionLoop
            self.currentMode = self.defaultModeName;
            self.modes.(self.defaultModeName) = cell(0, 2);
        end
        
        function addFunctionWithPriorityToMode(self, fcn, priority, modeName)
            if nargin < 4 || isempty(modeName)
                modeName = self.defaultModeName;
            end
            
            if ~isfield(self.modes, modeName)
                self.modes.(modeName) = cell(0, 2);
            end
            self.modes.(modeName)(end+1,:) = {fcn, priority};
        end
        
        function functionLoop = prepareLoopForModes(self, modeNames)
            if nargin < 2 || isempty(modeNames)
                modeNames = {self.defaultModeName};
            end
            if ischar(modeNames)
                modeNames = {modeNames};
            end
            
            % get all speified functions
            modeConcatenate = cell(0, 2);
            for ii = 1:numel(modeNames)
                mn = modeNames{ii};
                modeConcatenate = cat(1, modeConcatenate, self.modes.(mn));
            end
            
            % sort by priority
            [p,i] = sort([modeConcatenate{:,2}]);
            functionLoop = modeConcatenate(i,1);
        end
        
        function summary = runForDurationForModes(self, duration, modeNames)
            if nargin < 2 || isempty(duration)
                duration = 0;
            end
            if nargin < 3 || isempty(modeNames)
                modeNames = {self.defaultModeName};
            end
            
            % Until I get smarter, I'll punt on preallocating timeStamps.
            %   Doubling the array online is very costly.
            % Building the summary online is alos very costly.
            
            % prepare to loop through functions and take timestamps
            functionLoop = self.prepareLoopForModes(modeNames);
            n = length(functionLoop);
            timeStamps = zeros(1, n*1e6);
            
            ii = 0;
            now = feval(self.clockFcn);
            endTime = now + duration;
            while now < endTime
                ii = ii + 1;
                now = feval(self.clockFcn);
                timeStamps(ii) = now;
                feval(functionLoop{mod(ii,n)+1}{:});
            end
            
            % format a summary
            summary = cell(ii,2);
            for jj = 1:ii
                summary{jj,1} = timeStamps(jj);
                summary(jj,2) = functionLoop(mod(jj,n)+1);
            end
        end
        
        function summary = runForIterationsForModes(self, iterations, modeNames)
            if nargin < 2 || isempty(iterations)
                duration = 1;
            end
            if nargin < 3 || isempty(modeNames)
                modeNames = {self.defaultModeName};
            end
            
            % prepare to loop through functions and take timestamps
            functionLoop = self.prepareLoopForModes(modeNames);
            n = length(functionLoop);
            timeStamps = zeros(1, n*iterations);
            
            ii = 0;
            ff = repmat(1:n, 1, iterations);
            feval(self.clockFcn);
            for ii = 1:n*iterations
                timeStamps(ii) = feval(self.clockFcn);
                feval(functionLoop{ff(ii)}{:});
            end
            
            % format a summary
            summary = cell(ii,2);
            for jj = 1:ii
                summary{jj,1} = timeStamps(jj);
                summary(jj,2) = functionLoop(mod(jj,n)+1);
            end
        end
        
        function summary = previewForModes(self, modeNames)
            if nargin < 3 || isempty(modeNames)
                modeNames = {self.defaultModeName};
            end
            functionLoop = self.prepareLoopForModes(modeNames);
            summary = cell(size(functionLoop, 1), 2);
            summary(:,2) = functionLoop;
            [summary{:,1}] = deal(feval(self.clockFcn));
        end
    end
end