classdef battleQueue < handle
    %Skeletal queue of feval()able cell arrays, for "encounter" game
    %   With thought, may get promoted to topsFoundataion
    
    properties
        fevalables={};
        isLocked=false;
        clockFcn = @now;
        summary = cell(0,2);
    end
    
    methods
        function self = battleQueue
        end
        
        function addFevalable(self, fevalable)
            self.fevalables{end+1} = fevalable;
        end
        
        function dispatchNextFevalable(self)
            if ~self.isLocked && length(self.fevalables) > 0
                nowTime = feval(self.clockFcn);
                feval(self.fevalables{1}{:});
                self.summary(end+1, 1:2) = {nowTime, self.fevalables{1}};
                self.fevalables(1) = [];
            end
        end
    end
end