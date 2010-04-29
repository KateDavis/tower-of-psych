classdef topsFoundation < handle
    % @class topsFoundation
    % Superclass for all of the funtamental Tower of Psych classes.
    % @details
    % The topsFoundation superclass provides a common interface for Tower
    % of Psych classes.  This includes:
    %   - a name property so that each object can be identified
    %   intuitively
    %   - a gui() method so that each object can be explored interactively
    %   .
    % @ingroup foundation
    
    properties (SetObservable)
        % a string name to indentify the object
        name = '';
    end
    
    methods
        % Launch a topsGUI graphical interface for this objet and return a
        % handle to the gui.
        g = gui;
    end
end
        