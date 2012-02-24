classdef SquareTagLogic < handle
    % @class SquareTagLogic
    % Manage state and logical behaviors for the "SquareTag" task.
    % @details
    % SquareTagLogic is the logical "back end" of the SquareTag task.  It
    % manages things like the number of squares involved in the task and
    % how far along each trial has progressed.
    % @details
    % SquareTagLogic keeps track of task geometry, such as where the
    % various squares are and where the subject is currently pointing.  But
    % it only represents geometry within unitless square, with location [0
    % 0] and dimensions [1 1].  It doesn't know anything about how to draw
    % graphics on the screen or how to read where the subject is pointing.
    
    properties
        % a name to identify a SquareTag session
        name = '';
        
        % a time to identify a SquareTag session
        time = 0;
        
        % how many trials per session
        nTrials = 10;
        
        % number of squares that the subject must tag
        nSquares = 3;
        
        % mimimum side length for a square
        minSide = 0.1;
        
        % maximum side length for a square
        maxSide = 0.2;
        
        % string indicating that the user tagged the correct square
        tagOutput = 'tag';
        
        % string indicating that the user tagged an incorrect square
        missOutput = 'miss';
        
        % string indicating that there's another square to be tagged
        nextOutput = 'nextSquare';
        
        % string indicating that there are no more squares to tag
        doneOutput = 'done';
    end
    
    properties (SetAccess = protected)
        % nx4 matrix of square positions, with rows [x y w h]
        squarePositions;
        
        % running count of trials in a session
        currentTrial;
        
        % index of the current square in a trial
        currentSquare;
        
        % how many times the subject hit the wrong square in a trial
        squareMisses;
        
        % location of the subjcet's cursor [x y]
        cursorLocation;
    end
    
    methods
        % Make a new logic object.
        function self = SquareTagLogic(name, time)
            if nargin >= 1
                self.name = name;
            end
            
            if nargin >= 2
                self.time = time;
            end
            
            self.startSession();
        end
        
        % Initialize for a new SquareTag session.
        function startSession(self)
            self.currentTrial = 0;
            self.cursorLocation = [0 0];
        end
        
        % Finish up after SquareTag session.
        function finishSession(self)
        end
        
        % Initialize for a new SquareTag trial.
        function startTrial(self)
            self.makeSquares();
            self.currentSquare = 0;
            self.squareMisses = 0;
            self.currentTrial = self.currentTrial + 1;
        end
        
        % Finish up after SquareTag trial.
        function finishTrial(self)
        end
        
        % Choose a new random position for each square.
        function makeSquares(self)
            positions = zeros(self.nSquares, 4);
            
            % define a grid with cells that accommodate the largest square
            %   assuming nSquares is less than the number of cells
            nSide = ceil(1/self.maxSide);
            shuffledCells = randperm(nSide.^2);
            sides = linspace(self.minSide, self.maxSide, self.nSquares);
            for ii = 1:self.nSquares
                gridIndex = shuffledCells(ii);
                row = 1 + mod(gridIndex-1, nSide);
                col = 1 + floor((gridIndex-1) / nSide);
                gridPos = subposition([0 0 1 1], nSide, nSide, row, col);
                positions(ii,:) = [gridPos(1:2), [1 1]*sides(ii)];
                
            end
            self.squarePositions = positions;
        end
        
        % Increment the current square in a trial.
        function output = nextSquare(self)
            if self.currentSquare < self.nSquares
                % increment and report that next square is ready
                self.currentSquare = self.currentSquare + 1;
                output = self.nextOutput;
            else
                % report that there are no more squares!
                output = self.doneOutput;
            end
        end
        
        % Get a topsClassification suitable for the current square.
        function classn = makeClassification(self)
            % make a classification that can read unitless cursorLocation
            classn = topsClassification('SquareTag');
            n = 100;
            classn.addSource('x', self.getCursorLocation('x'), 0, 1, n);
            classn.addSource('y', self.getCursorLocation('y'), 0, 1, n);
            
            % define a region for each square
            %   map most regions to the "miss" output
            %   map the the current square's region to the "tag" output
            for ii = 1:self.nSquares
                % make a region to represent this square
                squareName = sprintf('square-%d', ii);
                region = topsRegion(squareName, classn.space);

                % set the square's position in the region
                position = self.squarePositions(ii,:);
                region = region.setRectangle('x', 'y', position, 'in');

                % classify this region as "tag" or "miss"
                if ii == self.currentSquare
                    output = self.tagOutput;
                else
                    output = self.missOutput;
                end
                classn.addOutput(squareName, region, output);
            end
        end
        
        % Increment the runnign count of square misses in a trial
        function incrementMisses(self)
            self.squareMisses = self.squareMisses + 1;
        end
        
        % Set the subject's cursor location in unitless space.
        function setCursorLocation(self, location, xy)
            if nargin < 3
                self.cursorLocation = location;
            elseif strcmp(xy, 'x')
                self.cursorLocation(1) = location(1);
            elseif strcmp(xy, 'y')
                self.cursorLocation(2) = location(1);
            else
                self.cursorLocation = location;
            end
        end
        
        % Get the subject's cursor location in unitless space.
        function location = getCursorLocation(self, xy)
            if nargin < 2
                location = self.cursorLocation;
            elseif strcmp(xy, 'x')
                location = self.cursorLocation(1);
            elseif strcmp(xy, 'y')
                location = self.cursorLocation(2);
            else
                location = self.cursorLocation;
            end
        end
        
        % Summarize the current status of the session in a struct.
        function status = getStatus(self)
            props = properties(self);
            values = cell(size(props));
            for ii = 1:numel(props)
                values{ii} = self.(props{ii});
            end
            status = cell2struct(values, props);
        end
    end
end
