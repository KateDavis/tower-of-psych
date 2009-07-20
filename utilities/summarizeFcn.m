function functionSummary = summarizeFcn(fcn)
%Build a readable summary of a feval()able cell array

if length(fcn) > 1
    argSummary = summarizeArgument(fcn{2});
else
    argSummary = '';
end

for ii = 3:length(fcn)
    argSummary = sprintf('%s, %s', argSummary, summarizeArgument(fcn{ii}));
end

functionSummary = sprintf('%s(%s)', func2str(fcn{1}), argSummary);

function argSummary = summarizeArgument(arg)
if ischar(arg)
    argSummary = sprintf('''%s''', arg);
elseif isnumeric(arg) && isscalar(arg)
    argSummary = num2str(arg);
else
    argSummary = sprintf('%s[%s]', class(arg), num2str(size(arg)));
end