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

        % Summarize a cell array as a 2D cell array of strings.
        % @param cellArray any cell array
        % @param colors nx3 matrix with one color per row (RGB, 0-1)
        % @details
        % Summarizes the given @a cellArray as a 2D cell array of strings
        % suitable for display as a table.  Each element of the returned 2D
        % cell array contains a string summary of one element of @a
        % cellArray.
        % @details
        % If @a cellArray is 1D or 2D, rows and columns arrangements are
        % are preserved in the returned cell array.  For higher-dimensional
        % cell arrays, columns are preserved and all other dimensions are
        % folded into rows.  
        % @details
        % Quoted 'strings' in the value summaries summary will be colored
        % in based on their spelling and the given @colors.  The summaries
        % will contain HTML color tags.
        function tableCell = makeTableForCellArray(cellArray, colors)
            if isempty(cellArray)
                tableCell = {};
                return;
            end 
            
            % compute indices for folding into 2 dimensions
            %   while preserving columns
            nElements = numel(cellArray);
            nRows = size(cellArray, 1);
            nCols = size(cellArray, 2);
            rowFolder = zeros(nRows, nElements/nRows);
            rowFolder(:) = 1:nElements;
            columnFolder = zeros(nElements/nCols, nCols);
            for ii = 0:(nElements/(nRows*nCols)-1)
                rowChunk = (1:nRows)+ii*nRows;
                columnChunk = (1:nCols)+ii*nCols;
                columnFolder(rowChunk,1:nCols) = ...
                    rowFolder(1:nRows,columnChunk);
            end
            
            % make a summary for each element of cellArray
            tableCell = cell(nElements/nCols, nCols);
            for ii = 1:nElements
                foldIndex = columnFolder(ii);
                item = cellArray{foldIndex};
                info = topsGUIUtilities.makeSummaryForItem(item, colors);
                info = topsGUIUtilities.spaceInstadOfLines(info);
                info = sprintf('<HTML>%s</HTML>', info);
                tableCell{ii} = info;
            end
        end
        
        % Summarize a struct array as a 2D cell array of strings.
        % @param structArray any struct array
        % @param colors nx3 matrix with one color per row (RGB, 0-1)
        % @details
        % Summarizes the given @a structArray as a 2D cell array of strings
        % suitable for display as a table.  Each element of @a structArray
        % corresponds to a row in the returned cell array.  Each field of
        % @a structArray corresponds to a column.  Each individual element
        % of the returned 2D cell array contains a string summary of one
        % data value from @a structArray.
        % @details
        % Also returns a cell array of field names, suitable as table row
        % headers.
        % @details
        % Quoted 'strings' in the value summaries summary will be colored
        % in based on their spelling and the given @colors.  The summaries
        % will contain HTML color tags.
        function [tableCell, fields] = makeTableForStructArray( ...
                structArray, colors)
            
            fields = fieldnames(structArray);
            nFields = numel(fields);
            nElements = numel(structArray);
            
            tableCell = cell(nElements, nFields);
            for ii = 1:nElements
                for jj = 1:nFields
                    item = structArray(ii).(fields{jj});
                    info = topsGUIUtilities.makeSummaryForItem(item, colors);
                    info = sprintf('<HTML>%s</HTML>', info);
                    info = topsGUIUtilities.spaceInstadOfLines(info);
                    tableCell{ii,jj} = info;
                end
            end
        end
        
        % Make a descriptive title for an item.
        % @param item any item
        % @param item name a name to display for @a item
        % @param color a color for the description (RGB, 0-1)
        % @details
        % Makes a title for the given @a item, based on the @a item class,
        % size, and the given @a name, with HTML formatting.  @a name will
        % appear in the default foreground color, the rest of the title
        % will appear in the given @a color.
        function title = makeTitleForItem(item, name, color)
            if isempty(item)
                suffix = ' (empty)';
            elseif numel(item) > 1
                suffix = ' array';
            else
                suffix = '';
            end
            title = sprintf('is a %s%s', class(item), suffix);
            title = topsGUIUtilities.htmlWrapFormat( ...
                title, color, false, false);
            title = sprintf('%s %s', name, title);
        end
        
        % Make a descriptive summary of an item.
        % @param item any item
        % @param colors nx3 matrix with one color per row (RGB, 0-1)
        % Makes a summary for the given @a item, based on the built-in
        % disp() function.  Quoted 'strings' in the summary will be colored
        % in based on their spelling and the given @colors.  The summary
        % will contain HTML color tags.
        function info = makeSummaryForItem(item, colors)
            
            if ischar(item)
                % item is a string, color it in
                color = topsGUIUtilities.getColorForString(item, colors);
                info = sprintf('''%s''', item);
                info = topsGUIUtilities.htmlWrapFormat( ...
                    info, color, false, false);
                
            else
                % use what disp() has to say about the item
                info = evalc('disp(item)');
                info = topsGUIUtilities.htmlStripAnchors( ...
                    info, false, '[\s,]*');
                
                % locate quoted strings
                quotePat = '''([^'']+)''';
                quotedStrings = regexp(info, quotePat, 'tokens');
                
                % wrap each one in colored formatting
                for ii = 1:numel(quotedStrings)
                    qs = quotedStrings{ii}{1};
                    color = topsGUIUtilities.getColorForString(qs, colors);
                    qsPat = sprintf('''%s''', qs);
                    qsWrapped = topsGUIUtilities.htmlWrapFormat( ...
                        qsPat, color, false, false);
                    info = regexprep(info, qsPat, qsWrapped);
                end
            end
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
        % the given @a string with HTML <br/> break tags.  Returns the
        % updated string.
        function string = htmlBreakAtLines(string)
            newLinePat = '([\n\r]+)';
            string = regexprep(string, newLinePat, '<br />');
        end

        % Remove newline characters from the given string.
        % @param string any string
        % @details
        % Replaces any newline (\n) or return carriage (\r) characters in
        % the given @a string with a single space.  Returns the updated
        % string.
        function string = spaceInstadOfLines(string)
            newLinePat = '([\n\r]+)';
            string = regexprep(string, newLinePat, ' ');
        end
    end
end