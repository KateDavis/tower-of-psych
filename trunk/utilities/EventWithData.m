classdef EventWithData < event.EventData
    % @class EventWithData
    % A way to pass arbitrary data with Matlab events.
    % It's outrageous that Matlab's default EventData class has no property
    % to hold arbitrary data, or no suitable default subclass.
    % EventWithData adds this "userData" property.

    properties
        % arbitrary data to pass with the event
        userData;
    end
    
    methods
        % Constructor takes one optional argument
        % @param userData arbitrary data to pass with the event
        function self = EventWithData(userData)
            self = self@event.EventData;
            if nargin
                self.userData = userData;
            end
        end
    end
end