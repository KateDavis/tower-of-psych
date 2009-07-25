classdef battleTimer < handle
    %Skeletal timer class to help schedule "encounter" battle events
    %   with thought, might get promoted to topsFoundataion
    
    properties
        nextFire=inf;
        repeatInterval=inf;
        callback={};
        
        clockFcn = @now;
        summary=cell(0,2);
    end
    
    methods
        function self = battleTimer
        end
        
        function loadForTimeWithCallback(self, time, callback)
            self.nextFire = time;
            self.callback = callback;
        end
        
        function didFire = tick(self)
            nowTime = feval(self.clockFcn);
            didFire = nowTime >= self.nextFire;
            
            if didFire
                feval(self.callback{:});
                self.summary(end+1,1:2) = {nowTime, self.callback};
                self.nextFire = nowTime + self.repeatInterval;
            end
        end
    end
end