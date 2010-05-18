classdef ObjectGrapher < handle
    % @class ObjectGrapher
    % Graphs references among objects with the Graphviz tool.
    % @ details
    % ObjectGrapher follows refrences among objects and keeps track of
    % unique objects and how they refer to one another.  It confugures a
    % DataGrapher to graph which objects refer to which.
    % @ingroup utilities
    
    properties
        % containers.Map of objects, where to start looking for object
        % references.
        seedObjects;
        
        % containers.Map of unique objects found while following
        % references.
        uniqueObjects;
        
        % maximum number of references to follow from before stopping (to
        % avoid recursion among non-handle objects)
        maxElementDepth = 20;
        
        % a DataGrapher object for graphing the objects
        dataGrapher;
        
        % struct of object and reference data to graph
        objectInfo;
        
        % index into uniqueObjects of the last object found;
        currentIndex;
    end
    
    methods
        function self = ObjectGrapher
            self.initializeUniques;
            
            self.seedObjects = containers.Map(-1, -1, 'uniformValues', false);
            self.seedObjects.remove(self.seedObjects.keys);
            warning('off', 'MATLAB:structOnObject');

            self.dataGrapher = DataGrapher;
            self.dataGrapher.nodeNameFunction = ...
                @ObjectGrapher.classNameWithLetter;

            self.dataGrapher.edgeFunction = ...
                @ObjectGrapher.edgeFromReferences;
        end
        
        function initializeUniques(self)
            self.uniqueObjects = containers.Map(-1, -1, 'uniformValues', false);
            self.uniqueObjects.remove(self.uniqueObjects.keys);
        end
        
        function addSeedObject(self, object)
            n = self.seedObjects.length + 1;
            self.seedObjects(n) = object;
        end
        
        function n = addUniqueObject(self, object)
            n = self.uniqueObjects.length + 1;
            self.uniqueObjects(n) = object;
        end
        
        function [contains, index] = containsUniqueObject(self, object)
            contains = false;
            index = [];
            if ~isempty(object)
                objects = self.uniqueObjects.values;
                for ii = 1:length(objects)
                    if isa(object, 'handle')
                        contains = object==objects{ii};
                    else
                        contains = isequal(object, objects{ii});
                    end
                    
                    if contains
                        if nargout > 1
                            keys = self.uniqueObjects.keys;
                            index = keys{ii};
                        end
                        return
                    end
                end
            end
        end
        
        function crawlForUniqueObjects(self)
            self.initializeUniques;
            scanFun = @(object, depth, path, objFcn)self.scanObject(object, depth, path, objFcn);
            seeds = self.seedObjects.values;
            for ii = 1:length(seeds)
                self.iterateElements(seeds{ii}, self.maxElementDepth, {}, scanFun);
            end
        end
        
        function scanObject(self, object, depth, path, objFcn)
            % detect objectness and uniqueness
            %   drill through objects like they're structs
            if isobject(object)
                if isa(object, 'handle')
                    
                    if self.containsUniqueObject(object)
                        % base case: already scanned this oject
                        return
                        
                    else
                        % recur: iterate arbitrary handle object's elements
                        self.addUniqueObject(object);
                        self.iterateElements(struct(object), self.maxElementDepth, path, objFcn);
                        
                    end
                else
                    % recur: iterate arbitrary value object's elements
                    %   "value" objects are unique by definition
                    %   but limit recursion on them
                    self.addUniqueObject(object);
                    self.iterateElements(struct(object), depth-1, path, objFcn);
                end
            end
        end
        
        function traceLinksForEdges(self)
            self.crawlForUniqueObjects;

            traceFun = @(object, depth, path, objFcn)self.recordEdge(object, depth, path, objFcn);
            k = self.uniqueObjects.keys;
            indexes = [k{:}];
            uniques = self.uniqueObjects.values;
            
            self.objectInfo = struct('class', {}, 'references', {});
            for ii = indexes
                self.currentIndex = ii;
                self.objectInfo(ii).class = class(uniques{ii});
                self.objectInfo(ii).references = struct('path', {}, 'target', {});
                self.iterateElements(struct(uniques{ii}), self.maxElementDepth, {}, traceFun);
            end
            
            self.dataGrapher.inputData = self.objectInfo;
        end
        
        function recordEdge(self, object, depth, path, objFcn)
            % record edge from current object to this object
            if isobject(object)
                [contains, index] = self.containsUniqueObject(object);
                if contains
                    ref.path = path;
                    ref.target = index;
                    self.objectInfo(self.currentIndex).references(end+1) = ref;
                end
            end
        end
        
        function iterateElements(self, object, depth, path, objFcn)
            % Iterate elements of complex types to find objects.
            % Keep track of path through nested types to reach object
            % Execute some function upon reaching object:
            %   - feval(objFcn, object, depth, path, objFcn)
            %   - e.g. add to unique object list
            %   - e.g. follow references from each unique object
            
            if depth <= 0
                % base case: maxed out on recursion of non-handles
                return
            end
            
            if isstruct(object)
                % will recur through struct fields
                elements = struct2cell(object);
                paths = fieldnames(object);
                format = '.%s';
                
            elseif iscell(object)
                % will recur through cell elements
                elements = object;
                paths = num2cell(1:numel(elements));
                format = '\\{%d\\}';
                
            elseif isa(object, 'containers.Map')
                % will recur through map contents
                %   treating map like its not an object
                elements = object.values;
                paths = object.keys;
                if strcmp(object.KeyType, 'char')
                    format = '(''%s'')';
                else
                    format = '(%f)';
                end
                
            elseif isobject(object) && ~isempty(object)
                % base case: found a real object
                %   may be array of object
                %   objFcn may wish to recur
                if isscalar(object)
                    feval(objFcn, object, depth, path, objFcn);
                else
                    for ii = 1:numel(object)
                        elementPath = cell(1, length(path)+1);
                        elementPath(1:end-1) = path;
                        elementPath{end} = sprintf('(%d)', ii);
                        feval(objFcn, object(ii), depth, elementPath, objFcn);
                    end
                end
                return
                
            else
                % base case: not a complex type
                return
            end
            
            % recur: iterate each element
            for ii = 1:length(elements)
                elementPath = cell(1, length(path)+1);
                elementPath(1:end-1) = path;
                elementPath{end} = sprintf(format, paths{ii});
                self.iterateElements(elements{ii}, depth-1, elementPath, objFcn);
            end
        end
        
        function writeDotFile(self)
            self.dataGrapher.writeDotFile;
        end
        
        function generateGraph(self)
            self.dataGrapher.generateGraph;
        end
    end
    
    methods(Static)
        function nodeName = classNameWithLetter(inputData, index)
            id = inputData(index);
            letter = char(index+double('a')-1);
            nodeName = sprintf('%s-%s', id.class, letter);
        end
        
        function [edgeIndexes, edgeNames] = edgeFromReferences(inputData, index)
            id = inputData(index);
            edgeIndexes = [];
            edgeNames = {};
            for ii = 1:length(id.references)
                edgeIndexes(ii) = id.references(ii).target;
                edgeNames{ii} = sprintf('%s', id.references(ii).path{:});
            end
        end
    end
end