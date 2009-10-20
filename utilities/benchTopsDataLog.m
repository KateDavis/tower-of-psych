function benchTopsDataLog(n)
%Add n groups and n^2 data items to a topsDataLog

groups = cell(1,n);
data = cell(1,n);
for ii = 1:n
    groups{ii} = sprintf('group%d', ii);
    data{ii} = ii;
end

topsDataLog.flushAllData;

benchTimes = zeros(1, n^2);
ii = 0;
for g = groups
    for d = data
        ii = ii + 1;
        tic;
        topsDataLog.logDataInGroup(d{1}, g{1});
        benchTimes(ii) = toc;
    end
end
% for d = data
%     for g = groups
%         ii = ii + 1;
%         tic;
%         topsDataLog.logDataInGroup(d{1}, g{1});
%         benchTimes(ii) = toc;
%     end
% end


% get internally recorded log entry times
%   compare to benchmarked times
logStruct = topsDataLog.getSortedDataStruct;
internalTimes = diff([logStruct.mnemonic]);

cla
line(1:(n^2), benchTimes, 'Color', [1 0 0])
line(1:((n^2)-1), internalTimes, 'Color', [0 1 0])
ylabel('time to make data log entry (s)')
xlabel('data log entry #')
legend('benchmark tic-toc', 'dataLog timestamps')