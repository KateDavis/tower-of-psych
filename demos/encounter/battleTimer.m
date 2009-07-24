classdef battleTimer < handle
    %Skeletal timer class to help schedule "encounter" battle events
    %   with thought, might get promoted to topsFoundataion
    
    properties
        nextFire=inf;
        repeatInterval=0;
        callback={};
    end
    
    methods
        function self = battleTimer
        end
        
        function loadForTimeWithCallback(self, time, callback)
            self.nextFire = time;
            self.callback = callback;
        end
        
        function didFire = tick(self, nowTime)
            didFire = nowTime >= self.nextFire;
            
            if didFire
                feval(self.callback{:});
                if self.repeatInterval
                    self.nextFire = nowTime + self.repeatInterval;
                else
                    self.nextFire = inf;
                end
            end
        end
    end
end