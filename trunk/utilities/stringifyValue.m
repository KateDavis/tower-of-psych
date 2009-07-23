function stringSummary = stringifyValue(value)
%Summarize various data as strings

if ischar(value)

    % put string in quotes
    stringSummary = sprintf('''%s''', value);

elseif isnumeric(value) && isscalar(value)
    
    % builtin scalar conversion
    stringSummary = num2str(value);

elseif isa(value, 'function_handle')
    
    % builtin function handle conversion
    stringSummary = sprintf('@%s', func2str(value));

elseif iscell(value) && ~isempty(value) && isa(value{1}, 'function_handle')
    
    % function-with-arguments cell array
    %   summarizeFcn is recursive to this function
    stringSummary = summarizeFcn(value);
    
else
    
    % last resort, summarize type and size
    stringSummary = sprintf('%s[%s]', class(value), num2str(size(value)));
end