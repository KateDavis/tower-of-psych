classdef topsRunnableComposite < topsRunnable
    % @class topsRunnableComposite
    % Superclass for objects that run just by running other objects.
    % @details
    % The topsRunnableComposite superclass provides a common interface for
    % runnable objects that compose other runnable objects, and refer to
    % these as "children".  topsRunnableComposite objects run() by
    % combining the run() behaviors of their children.  They may do this in
    % any way.
    % @details
    % topsRunnableComposite objects should
    % @ingroup foundation
    
    properties (SetObservable)
        % cell array of topsRunnable (or subclass) objects
        children = {};
    end
    
    methods
        % Add a child beneath this object.
        % @param child a topsRunnable to add beneath this object.
        % @details
        % Appends @a child to the children array of this object.
        function addChild(self, child)
            self.children = topsFoundation.cellAdd(self.children, child);
        end
        
        % Remove a child beneath this object.
        % @param child a topsRunnable to remove fmor beneath this object.
        % @details
        % Removes all instances of @a child from the children array of this
        % object.
        function removeChild(self, child)
            self.children = ...
                topsFoundation.cellRemoveItem(self.children, child);
        end
    end
end