%Summarize various data as strings
%
%   string = summarizeValue(value, n)
%
%   @ param value any variable to summarize
%   @ param n optional maximum length of returned string, default is 30;
%
%   @details
%   Returns a string that describes @a value.  For simple types like
%   strings and nubmers, the string may an exact, description.
%   For large arrays or complex types like structs and objects, the string
%   may only summarize @a value.
%
%   @ingroup utilities

function string = summarizeValue(value, n)

if nargin < 2
    n = 30;
end

if n <= 0
    string = '';
    return
end

if ischar(value)
    
    if isempty(value)
        string = '''''';
    else
        if numel(value) > n
            string = sprintf('%s...', value(1:n-3));
        else
            string = value;
        end
    end
    
elseif isnumeric(value)
    
    if isempty(value)
        string = '[]';
    else
        stringed = num2str(value);
        stringed(:,end+1) = ';';
        string = sprintf('[%s]', summarizeValue(stringed', n-2));
    end
    
elseif islogical(value)
    
    if isempty(value)
        string = '[]';
    else
        m = min(n, numel(value));
        boolCell = cell(1,m);
        value = value';
        boolCell(value(1:m)) = deal({'true'});
        boolCell(~value(1:m)) = deal({'false'});
        boolStr = sprintf('%s ', boolCell{:});
        string = sprintf('[%s]', summarizeValue(boolStr(1:end-1), n-2));
    end
    
elseif iscell(value)
    
    if isempty(value)
        string = '{}';
    elseif isscalar(value)
        string = sprintf('{%s}', summarizeValue(value{1}, n-2));
    else
        string = sprintf('{%s, ...}', summarizeValue(value{1}, n-7));
    end
    
elseif isa(value, 'function_handle')
    
    strFun = func2str(value);
    if ~strcmp(strFun(1), '@')
        strFun = sprintf('@%s', strFun);
    end
    string = summarizeValue(strFun, n);
    
else
    % last resort, type and size
    basic = sprintf('%s[%s]', class(value), num2str(size(value)));
    string = summarizeValue(basic, n);
end