classdef EventWithData < event.EventData
    % It's outrageous--outrageous--that Matlab's EventData superclass
    % doesn't have a userData property, or a default subclass with user
    % data.  Here it is.
    
    properties
        userData;
    end
    
    methods
        function self = EventWithData(userData)
            self = self@event.EventData;
            if nargin
                self.userData = userData;
            end
        end
    end
end