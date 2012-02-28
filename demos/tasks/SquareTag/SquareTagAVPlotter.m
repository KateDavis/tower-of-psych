classdef SquareTagAVPlotter < SquareTagAV
    % @class SquareTagAVPlotter
    % Plot Square Tag graphics in Matlab axes.
    % @details
    % SquareTagAVPlotter is a graphical "front end" of the SquareTag task.
    % It plots graphics in a Matlab figure and axes.
    %
    % @ingroup demos
    
    properties
        % background color for the task
        backgroundColor = [.7 .7 .8];
        
        % color for squares yet to be tagged
        squareColor = [.75 0 .1];
        
        % color for squares already tagged
        taggedColor = [0 .75 .1];
        
        % color for the subject's cursor
        cursorColor = [.75 .25 0];
    end
    
    properties(SetAccess = protected)
        % Matlab figure that holds the axes
        fig;
        
        % Matlab axes that holds the task
        ax;
        
        % Matlab graphics objects to represent task squares
        squares;
        
        % Matlab line to represent the user's cursor
        cursor;
    end
    
    methods
        % Make a new AV object.
        function self = SquareTagAVPlotter(varargin)
            self = self@SquareTagAV(varargin{:});
        end
        
        % Set up audio-visual resources as needed.
        function initialize(self)
            monitorPos = get(0, 'MonitorPositions');
            self.fig = figure( ...
                'Color', self.backgroundColor, ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'Name', mfilename(), ...
                'Pointer', 'custom', ...
                'PointerShapeCData', nan(16, 16), ...
                'Units', 'pixels', ...
                'Position', monitorPos(1,:), ...
                'ToolBar', 'none', ...
                'HitTest', 'off', ...
                'Selected', 'off', ...
                'SelectionHighlight', 'off');
            
            self.ax = axes( ...
                'Parent', self.fig, ...
                'ActivePositionProperty', 'Position', ...
                'Box', 'on', ...
                'Color', self.backgroundColor, ...
                'DrawMode', 'fast', ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'View', [0 90], ...
                'XLim', [0 1], ...
                'XScale', 'linear', ...
                'XTick', [], ...
                'YLim', [0 1], ...
                'YScale', 'linear', ...
                'YTick', [], ...
                'HitTest', 'off', ...
                'Selected', 'off', ...
                'SelectionHighlight', 'off');
            
            self.squares = zeros(1, self.logic.nSquares);
            for ii = 1:self.logic.nSquares
                self.squares(ii) = rectangle( ...
                    'Parent', self.ax, ...
                    'Curvature', [0 0], ...
                    'FaceColor', self.squareColor, ...
                    'EdgeColor', self.squareColor, ...
                    'LineStyle', 'none', ...
                    'Position', [0 0 1 1], ...
                    'HitTest', 'off', ...
                    'Selected', 'off', ...
                    'SelectionHighlight', 'off', ...
                    'Visible', 'off');
                
            end
            
            self.cursor = line(0, 0, ...
                'Parent', self.ax, ...
                'Color', self.cursorColor, ...
                'LineStyle', 'none', ...
                'Marker', '.', ...
                'MarkerSize', 30, ...
                'HitTest', 'off', ...
                'Selected', 'off', ...
                'SelectionHighlight', 'off', ...
                'Visible', 'off');
            
            % block to let Matlab process new graphics
            drawnow();
        end
        
        % Clean up audio-visual resources from initialize().
        function terminate(self)
            delete(self.fig);
            self.fig = [];
            self.ax = [];
            self.squares = [];
        end
        
        % Indicate start of trial.
        function doBeforeSquares(self)
            for ii = 1:self.logic.nSquares
                squarePos = self.logic.squarePositions(ii,:);
                set(self.squares(ii), ...
                    'FaceColor', self.squareColor, ...
                    'EdgeColor', self.squareColor, ...
                    'Position', squarePos, ...
                    'Visible', 'on');

                set(self.cursor, 'Visible', 'on');
            end
        end
        
        % Indicate ready to tag next square.
        function doNextSquare(self)
            alreadyTagged = 1:(self.logic.currentSquare-1);
            if ~isempty(alreadyTagged)
                set(self.squares(alreadyTagged), ...
                    'FaceColor', self.taggedColor, ...
                    'EdgeColor', self.taggedColor)
            end
        end
        
        % Indicate end of trial.
        function doAfterSquares(self)
            set(self.squares, 'Visible', 'off');
            set(self.cursor, 'Visible', 'off');
        end
        
        % Update the subject's cursor.
        function updateCursor(self)
            point = self.logic.cursorLocation;
            set(self.cursor, ...
                'XData', point(1), ...
                'YData', point(2));
        end
    end
end
