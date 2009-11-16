% Check how long it takes to log data in topsDataLog
%
%   benchTopsDataLog(n)
%
%   @param n the length of the benchmark test.
%
%   @details
%   Adds @a n pieces of data to @a n different groups in topsDataLog, for
%   n^2 total log additions.  Records how long each addition takes and
%   plots the results.
%
%   @todo
%   As of revision 78, checking whether the log already contains a given
%   group or mnemonic is a bottleneck, and additions take some 2ms.  This
%   is at least twice as slow as it should be.  I think the bottleneck
%   happens when when containers.Map objects are dereferenced (they're handle
%   subclasses) to access their keys.  I can probably work around this by
%   caching keys as I add them.
%   @ingroup utilities

function benchTopsDataLog(n)

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
ylim([0 3e-3])
xlabel('data log entry #')
legend('benchmark tic-toc', 'dataLog timestamps')