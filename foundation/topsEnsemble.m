classdef topsEnsemble < topsFoundation
    % @class topsEnsemble
    % Aggregate objects into an ensemble for batch opertaions.
    % @details
    % topsEnsemble groups together other objects and can access their
    % properties or methods all at once.  Individual objects in the
    % ensemble can be accessed or removed by index.  The order of objects
    % in the ensemble, can be specified as they're added to the ensemble.
    % This affects the order in which properties and methods will be
    % accessed.
    % @details
    % Any object can be added to an ensemble.  The objects should have some
    % property names or method names in common, so that the objects can
    % work in concert.  topsEnsemble leaves this up to the user.
    % @details
    % topsEnsemble is expected to work with "handle" objects (objects that
    % inherit from the built-in handle class.  Other objects or data types
    % may be added, but these may behave poorly.  Non-handle objects may
    % not reflect property changes correctly.  Non-object data types may
    % cause errors when the ensemble attempts to access their methods.
    %
    % @ingroup foundation
    
    properties (SetAccess = protected)
        % array of objects in the ensemble
        objects = {};
    end
    
    methods
        % Constuct with name optional.
        % @param name optional name for this object
        % @details
        % If @a name is provided, assigns @a name to this object.
        function self = topsEnsemble(name)
            if nargin >= 1
                self.name = name;
            end
        end
        
        % Is the given object a member of the ensemble?
        function [isMember, index] = contains(self, object)
        end
        
        % Add an object to the ensemble.
        function add(self, object)
        end
        
        % Take the indexed objects out of the ensemble.
        function remove(self, index)
        end
        
        % Set a property for one or more objects.
        function setProperty(self, property, value, index)
            object.setPropertySilently(property, value);
        end
        
        % Get a property value for one or more objects.
        function value = getProperty(self, property, index)
            value = object.(property);
        end
        
        % Call a method for one or more objects.
        function result = callMethod(self, method, args, index)
            object.(method)(varargin{:});
        end
        
        % Get an array of objects in the ensemble.
        function object = getObjects(self, index)
        end
        
        % Assign one object to a property of another object.
        % @details
        % "Wires up" an aggregation relationship between two managed
        % objects.  The given @a outer object will refer to the @a inner
        % object, using the assignment specified in @a varargin.  Both @a
        % outer and @a inner must be members of this ensemble.
        % @details
        % Aggregation can be undone by passing an empty @a inner object.
        % @details
        % @a varargin will be passed to Matlab's built-in substruct(), to
        % specify an arbitrary reference into @a outer.  The reference
        % could be to one of @a outer's properties, a sub-element or
        % sub-field of a property.  I if @a outer is an array of objects,
        % the reference could refer to one or more elements of @a outer.
        % @details
        % For example, to specify the 'data' property of @a outer, use the
        % following "dot" reference to the 'data' property:
        % @code
        % assignObject(@a inner, @a outer, '.', 'data');
        % @endcode
        % The result of this simple asignment would be the same as
        % @code
        % outer.data = inner;
        % @endcode
        function assign(self, inIndex, outIndex, varargin)
            subs = substruct(varargin{:});
            subsasgn(outer, subs, inner);
        end
    end
end