classdef topsEnsemble < topsCallList
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
    % property names or method names in common, so that they can respond in
    % concert to the same property or method access.
    % @details
    % topsEnsemble is expected to work with "handle" objects (objects that
    % inherit from the built-in handle class.  Other objects or data types
    % may be added, but these may behave poorly.  Non-handle objects may
    % not reflect property changes correctly.  Non-object data types may
    % cause errors when the ensemble attempts to access their methods.
    % @details
    % topsEnsemble can make repeated method calls on its aggregated objects
    % during runBriefly().  Use prepareToCallMethod() to set up repeated
    % calls.
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
        
        % Add an object to the ensemble.
        function addObject(self, object)
        end
        
        % Remove one or more objects from the ensemble.
        function removeObject(self, index)
        end
        
        % Get one or more objects in the ensemble.
        function object = getObject(self, index)
        end
        
        % Is the given object a member of the ensemble?
        function [isMember, index] = containsObject(self, object)
        end
        
        % Assign one object to a property of one other object.
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
        % sub-field of a property.
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
        function assignObject(self, inIndex, outIndex, varargin)
            subs = substruct(varargin{:});
            subsasgn(outer, subs, inner);
        end
        
        % Set a property for one or more objects.
        function setObjectProperty(self, property, value, index)
        end
        
        % Get a property value for one or more objects.
        %   cell with value from each
        function value = getObjectProperty(self, property, index)
        end
        
        % Call a method for one or more objects.
        % check nargout for alternate invokations
        %   0: take no outputs
        %   1: cell with first output from each invokation
        function result = callObjectMethod(self, method, args, index)
        end
        
        % Prepare to call one or more method, repeatedly
        %   take no outputs
        %   delegate to call list
        %   need a name to refer to the repeated call
        %   assume object as first method arg
        %   package self-call and add to calls fevalable
        %   isActive = false by default, else called from runBriefly()
        function prepareObjectMethod(self, method, args, name, index)
        end
    end
end