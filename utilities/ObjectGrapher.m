classdef ObjectGrapher < handle
    %Crawl among objects in Matlab, generate abstract graph, render with
    %something like GraphViz
    
    % @todo
    % Draw the seed object(s?) in a cluster, with edges constriaining and
    % weight 100.  Draw subsequent edges outside the cluster with edges not
    % constraining and weight 0.
    % Does this imply a better way to manage writing the graph file?
    % Should be object-at-a-time, with node and edge defaults set in
    % between.  Maybe there's a Graphable class...
    
    properties
        seedObjects;
        uniqueObjects;
        maxElementDepth;
        
        dotBinary;
        dotBinaryPath;
        dotFile;
        dotFilePath;
        imageFile;
        
        colors;
    end
    
    methods (Static)
        function og = withSeedObject(object)
            og = ObjectGrapher;
            og.addSeedObject(object);
            og.crawlForUniqueObjects;
            og.writeDotFile;
        end
        
        function og = withSeedObjectAndImageStyle(object, style)
            og = ObjectGrapher;
            og.addSeedObject(object);
            og.crawlForUniqueObjects;
            og.writeDotFile;
            og.writeDotImage(style);
            system(sprintf('open %s', fullfile(og.dotFilePath, og.imageFile)));
        end
    end
    
    methods
        function self = ObjectGrapher
            self.maxElementDepth = 20;
            
            self.initializeUniques;
            
            bogus = -1;
            self.seedObjects = containers.Map(bogus, bogus, 'uniformValues', false);
            self.seedObjects.remove(bogus);
            
            self.dotBinary = 'circo';
            self.dotBinaryPath = '/usr/local/bin/';
            self.dotFilePath = '~/Desktop';
            self.dotFile = sprintf('MatlabObjectGraph.dot');
            self.imageFile = sprintf('MatlabObjectGraph.png');
            
            self.colors = spacedColors(61);
            
            % shut up
            warning('off', 'MATLAB:structOnObject');
        end
        
        function initializeUniques(self)
            bogus = 'bogus';
            self.uniqueObjects = containers.Map(bogus, bogus, 'uniformValues', false);
            self.uniqueObjects.remove(bogus);
        end
        
        function addSeedObject(self, object)
            n = self.seedObjects.length + 1;
            self.seedObjects(n) = object;
        end
        
        function key = addUniqueObject(self, object)
            n = self.uniqueObjects.length + 1;
            key = sprintf('%s_%d', class(object), n);
            self.uniqueObjects(key) = object;
        end
        
        function [contains, key] = containsUniqueObject(self, object)
            contains = false;
            key = [];
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
                            key = keys{ii};
                        end
                        return
                    end
                end
            end
        end
        
        function crawlForUniqueObjects(self)
            self.initializeUniques;
            seeds = self.seedObjects.values;
            for ii = 1:length(seeds)
                scanFun = @(object, depth, path, objFcn)self.scanObject(object, depth, path, objFcn);
                self.iterateElements(seeds{ii}, self.maxElementDepth, {}, scanFun)
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
        
        function iterateElements(self, object, depth, path, objFcn)
            % Iterate elements of complex types to find objects.
            % Keep track of path through nested types to reach object
            % Execute some function upon reaching object:
            %   - feval(objFcn, object, depth, path, objFcn)
            %   - e.g. add to unique object list
            %   - e.g. generate GraphViz edge
            %   - etc...
            
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
                format = '{%d}';
                
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
            fileWithPath = fullfile(self.dotFilePath, self.dotFile);
            dotFile = fopen(fileWithPath, 'w+');
            
            try
                % declare graph
                fprintf(dotFile, 'graph MatlabObjectGraph\n{\n');
                
                % declare graph header-type stuff
                d = 1;
                fprintf(dotFile, 'ranksep="%d"\n', 2*d);
                fprintf(dotFile, 'nodesep="%d"\n', d);
                fprintf(dotFile, 'mindist="%d"\n', 3*d);
                fprintf(dotFile, 'sep="+%d"\n', 2*d);
                
                ratio = 3/4;
                fprintf(dotFile, 'ratio="%d"\n', d);
                
                overlap = 'scale';
                fprintf(dotFile, 'overlap="%s"\n', overlap);
                
                splines = 'true';
                fprintf(dotFile, 'splines="%s"\n', splines);
                
                font = 'FreeSans';
                fontSize = 12;
                fprintf(dotFile, 'node [shape="record" fontname="%s" fontsize="%d"]\n', ...
                    font, fontSize);
                
                arrow = 'normal';
                fprintf(dotFile, 'edge [fontname="%s" fontsize="%d" arrowhead="%s"]\n', ...
                    font, fontSize, arrow);
                
                fprintf(dotFile, '\n');
                
                % declare all nodes with properties
                keys = self.uniqueObjects.keys;
                for ii = 1:length(keys)
                    object = self.uniqueObjects(keys{ii});
                    nodeLabelForObject(keys{ii}, object, dotFile);
                end
                
                fprintf(dotFile, '\n');
                
                % iterate object properties to draw edges
                %   draw special edge first time each object encountered
                %   treat seed objects as alreay encountered
                keys = self.uniqueObjects.keys;
                bogus = 'kjhg';
                keysMap = containers.Map(bogus, bogus, 'uniformValues', false);
                keysMap.remove(bogus);
                for ii = 1:self.seedObjects.length
                    [contains, seedKey] = self.containsUniqueObject(self.seedObjects(ii));
                    keysMap(seedKey) = true;
                end

                for ii = 1:length(keys)
                    object = self.uniqueObjects(keys{ii});
                    edgesForObject(keys{ii}, object, dotFile, keysMap);
                end
                
                % close the graph
                fprintf(dotFile, '}\n\n');
                
            catch err
                fclose(dotFile);
                rethrow(err);
            end
            fclose(dotFile);
            
            function nodeLabelForObject(name, object, dotFile)
                
                % gather those properties that point to objects
                propMap = containers.Map('a', 0);
                propMap.remove('a');

                brokenObject = struct(object);
                props = fieldnames(brokenObject);
                n = length(props);
                for ii = 1:n
                    p = props{ii};
                    propFun = @(object, depth, path, objFcn)propertyPointsToObject(name, p, path, object, propMap);
                    self.iterateElements(brokenObject.(p), self.maxElementDepth, {}, propFun);
                end

                % write the useful properties to node label
                props = propMap.keys;
                n = length(props);
                if n > 0
                    for ii = 1:n
                        labelCells{ii} = sprintf('<%s>%s', props{ii}, props{ii});
                    end
                    labelProps = sprintf('|%s', labelCells{:});
                else
                    labelProps = '';
                end
                col = self.colorForString(name);
                fprintf(dotFile, '%s [label="{{<top>|%s}%s}" color="%s"]\n', name, name, labelProps, col);
            end
            
            function propertyPointsToObject(name, prop, path, object, propMap)
                propMap(prop) = true;
            end
            
            function edgesForObject(name, object, dotFile, keysMap)
                brokenObject = struct(object);
                props = fieldnames(brokenObject);
                n = length(props);
                for ii = 1:n
                    p = props{ii};
                    edgeFun = @(object, depth, path, objFcn)edgeFromNodeToObject(name, p, path, object, dotFile, keysMap);
                    self.iterateElements(brokenObject.(p), self.maxElementDepth, {}, edgeFun);
                end
            end
            
            function edgeFromNodeToObject(name, prop, path, object, dotFile, keysMap)
                [contains, target] = self.containsUniqueObject(object);
                if contains
                    
                    if any(strcmp(keysMap.keys, target))
                        weight = 0;
                        constraint = 'false';
                    else
                        weight = 100;
                        constraint = 'true';
                        keysMap(target) = true;
                    end
                    
                    col = self.colorForString(name, .75);
                    pathStr = sprintf('%s', path{:});
                    fprintf(dotFile, '%s:%s--%s:top [label="%s" color="%s" fontcolor="%s" constraint="%s" weight="%d"]\n', ...
                        name, prop, target, pathStr, col, col, constraint, weight);
                end
            end
        end
        
        function writeDotImage(self, bin)
            if nargin < 2
                bin = self.dotBinary;
            end
            dotBinary = fullfile(self.dotBinaryPath, bin);
            imageFile = fullfile(self.dotFilePath, self.imageFile);
            dotFile = fullfile(self.dotFilePath, self.dotFile);
            command = sprintf('%s -Tpng -o %s %s', ...
                dotBinary, imageFile, dotFile);
            unix(command);
        end
        
        function colString = colorForString(self, string, alpha)
            hash = 1 + mod(sum(string), size(self.colors,1));
            rgb = ceil(self.colors(hash, :)*255);
            if nargin < 3
                colString = sprintf('#%02x%02x%02x', rgb(1), rgb(3), rgb(2));
            else
                colString = sprintf('#%02x%02x%02x%02x', ...
                    rgb(1), rgb(3), rgb(2), ceil(alpha*255));
            end
        end
    end
end