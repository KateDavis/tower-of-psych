classdef topsGUIUtilities
    % @class topsGUIUtilities
    % Static utility methods for making Tower of Psych GUIs.
    % @details
    % topsGUIUtilities provides static methods for creating and working
    % with Tower of Psych graphical user interfaces (GUIs).  They deal with
    % tasks like manipulating strings and positions.
    %
    % @ingroup guis
    
    methods (Static)
        % Calculate a position that bounds other positions.
        % @param varargin one or more position rectangles
        % @details
        % Merges one or more position rectangles of the form [x y width
        % height] into one big position that bounds all of the given
        % rectangles.
        function merged = mergePositions(varargin)
            % take cell array of [x y width height] rects
            p = vertcat(varargin{:});
            l = min(p(:,1));
            b = min(p(:,2));
            r = max(p(:,1)+p(:,3));
            t = max(p(:,2)+p(:,4));
            merged = [l, b, r-l, t-b];
        end
        
        % Pick a color for the given string, based on its spelling.
        % @param string any string
        % @param colors nx3 matrix with one color per row (RGB, 0-1)
        % @details
        % Maps the given @a string to one of the rows in @a colors, based
        % on the spelling of @a string.  The same string will always map to
        % the same row.  Multiple strings will also map to each row.
        function col = getColorForString(string, colors)
            hashRow = 1 + mod(sum(string), size(colors,1));
            col = colors(hashRow, :);
        end
        
        % Wrap the given string with HTML font tags.
        % @param string any string
        % @param color 1x3 color (RGB, 0-1)
        % @param isEmphasis whether to apply @em emphasis formatting
        % @param isStrong whether to apply @b strong formatting
        % @details
        % Wraps the given @a string in HTML tags which specify font
        % formatting.  @a color must contain RBG components in the range
        % 0-1.  @a isEmphasis specifies whether to apply @em emphasis
        % (true) or not.  @a isStrong specifies whether to apply @b strong
        % formatting or not.  @a color, @a isEmphasis, or @a isStrong may
        % be omitted empty, in which case no formatting is specified.
        % @details
        % Returns the given @a string, wrapped in HTML tags.
        function string = htmlWrapFormat( ...
                string, color, isEmphasis, isStrong)
            
            % Apply color?
            if nargin >=2 && ~isempty(color)
                colorHex = dec2hex(round(color*255), 2)';
                colorName = colorHex(:)';
                string = sprintf('<FONT color="%s">%s</FONT>', ...
                    colorName, string);
            end
            
            % Apply emphasis?
            if nargin >=3 && isEmphasis
                string = sprintf('<EM>%s</EM>', string);
            end
            
            % Apply strong?
            if nargin >=4 && isStrong
                string = sprintf('<STRONG>%s</STRONG>', string);
            end
        end
        
        % Strip out HTML anchors and anchor tags from a string.
        % @param string any string
        % @param isPreserveText whether to leave the anchor text in place
        % @param stripPrefix additional regexp to strip before each anchor
        % @details
        % Strips out HTML anchors (like "a=href", etc.) from the given
        % @a string.  By default, strips out the anchor text along with the
        % anchor tags.  If @a isPreserverText is provided and true, leaves
        % the anchor text without the tags.  If @a stripPrefix is provided,
        % also strips out patterns that match the regular expression @a
        % stripPrefix, immediately before anchors.
        function stripped = htmlStripAnchors( ...
                string, isPreserveText, stripPrefix)
            
            if nargin < 2 || isempty(isPreserveText)
                isPreserveText = false;
            end
            
            if nargin < 3 || isempty(stripPrefix)
                stripPrefix = '';
            end
            
            anchorPat = '<[Aa][^<]*>([^<]*)</[Aa]>';
            stripPat = [stripPrefix anchorPat stripPrefix];
            if isPreserveText
                stripped = regexprep(string, stripPat, '$1');
            else
                stripped = regexprep(string, stripPat, '');
            end
        end
        
        % Replace newline characters with HTML break tags.
        % @param string any string
        % @details
        % Replaces any newline (\n) or return carriage (\r) characters in
        % the given @a string with HTML <br/> break tags.
        function breaked = htmlBreakAtLines(string)
            newLinePat = '([\n\r]+)';
            breaked = regexprep(string, newLinePat, '<br />');
        end
    end
end