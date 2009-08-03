function benchTopsDataLog(n)
% Add n mnemonics and n^2 data items to a topsDataLog

mnemonics = cell(1,n);
data = cell(1,n);
for ii = 1:n
    mnemonics{ii} = sprintf('mnemonic%d', ii);
    data{ii} = ii;
end

topsDataLog.flushAllData;

benchTimes = zeros(1, n^2);
ii = 0;
for m = mnemonics
    for d = data
        ii = ii + 1;
        tic;
        topsDataLog.logMnemonicWithData(m{1}, d{1});
        benchTimes(ii) = toc;
    end
end
% for d = data
%     for m = mnemonics
%         ii = ii + 1;
%         tic;
%         theLog.logMnemonicWithData(m{1}, d{1});
%         benchTimes(ii) = toc;
%     end
% end


% get internally recorded log entry times
%   compare to benchmarked times
logStruct = topsDataLog.getAllDataSorted;
internalTimes = diff([logStruct.time])*(60*60*24);

cla
line(1:(n^2), benchTimes, 'Color', [1 0 0])
line(1:((n^2)-1), internalTimes, 'Color', [0 1 0])
ylabel('time to make data log entry (s)')
xlabel('data log entry #')
legend('benchmark tic-toc', 'dataLog timestamps')