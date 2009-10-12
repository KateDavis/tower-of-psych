function functionSummary = summarizeFcn(fcn)
%Build a readable summary of a feval()able cell array

if isempty(fcn)
    functionSummary = '';
else
    if length(fcn) > 1
        argSummary = stringifyValue(fcn{2});
        for ii = 3:length(fcn)
            argSummary = sprintf('%s, %s', argSummary, stringifyValue(fcn{ii}));
        end
    else
        argSummary = '';
    end
    functionSummary = sprintf('%s(%s)', stringifyValue(fcn{1}), argSummary);
end