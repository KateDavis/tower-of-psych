%Summarize various data as strings
%
%   stringSummary = stringifyValue(value)
%
%   @param value any variable
%
%   @details
%   Returns a string that describes @a value.  For simple types like
%   strings and nubmers, the string may an exact description.  For complex
%   types like structs and objects, the string may only describe the type
%   and size of @a value.
%   @ingroup utilities

function stringSummary = stringifyValue(value)

if isempty(value)
    
    % empty, with type
    stringSummary = sprintf('(empty %s)', class(value));
    
elseif ischar(value)
    
    % string as is
    stringSummary = value;
    
elseif isnumeric(value) && isscalar(value)
    
    % builtin scalar conversion
    stringSummary = num2str(value);
    
elseif islogical(value) && isscalar(value)
    
    % boolean strings
    if value
        stringSummary = 'true';
    else
        stringSummary = 'false';
    end
    
elseif isa(value, 'function_handle')
    
    % built-in function handle conversion
    stringSummary = func2str(value);
    if ~strcmp(stringSummary(1), '@')
        stringSummary = sprintf('@%s', stringSummary);
    end
    
else
    
    % last resort, summarize type and size
    stringSummary = sprintf('%s[%s]', class(value), num2str(size(value)));
end