%% **🚀 初始化环境**
clc; clear; close all;

%% **📥 加载 CSV 数据**
filename = 'Bitcoin_tweets.csv';
opts = detectImportOptions(filename, 'Delimiter', ',', 'VariableNamesLine', 1);
opts = setvaropts(opts, 'text', 'WhitespaceRule', 'preserve');
data = readtable(filename, opts);

% **去除重复值**
data = unique(data, 'rows');
disp(['Shape after removing duplicates: ', num2str(size(data))]);

% **转换 'date' 列为 datetime 格式**
data.date = datetime(data.date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss', 'Format', 'yyyy-MM-dd HH:mm:ss');

% **删除无效日期和空文本**
data = data(~isnat(data.date) & ~cellfun('isempty', data.text), :);
disp(['Shape after dropping invalid datetime values: ', num2str(size(data))]);

%% **📖 读取 VADER 词典**
lexiconPath = 'vader_lexicon.txt';
opts = detectImportOptions(lexiconPath, 'Delimiter', '\t', 'ReadVariableNames', false);
opts.VariableNames = {'Word', 'Score', 'StdDev', 'Distribution'}; % 确保列名正确
lexicon = readtable(lexiconPath, opts);

% **转换 'Word' 列为字符串数组**
lexicon.Word = string(lexicon.Word);

% **创建情感词典**
sentimentDict = containers.Map(lexicon.Word, lexicon.Score);

%% **📝 清理推文**
clean_tweet = @(twt) regexprep(regexprep(regexprep(regexprep(regexprep( ...
    twt, '#bitcoin|#Bitcoin|#btc', 'bitcoin', 'ignorecase'), ...  % 替换#bitcoin
    '#[A-Za-z0-9]+', ''), ...                                    % 移除其他主题标签
    '\n', ''), ...                                               % 移除换行符
    'https?://\S+', ''), ...                                     % 移除链接
    '@\w+ *', '');                                              % 移除提及用户

% **应用清理**
data.CleanTwt = eraseURLs(data.text);            % 删除 URL
data.CleanTwt = erasePunctuation(data.CleanTwt); % 删除标点符号
data.CleanTwt = lower(data.CleanTwt);            % 转换为小写
data.CleanTwt = cellfun(clean_tweet, data.text, 'UniformOutput', false);

% **确保只保留英文字母和空格**
data.CleanTwt = regexprep(data.CleanTwt, '[^a-zA-Z\s]', '');

% **删除清理后为空的推文**
data = data(~cellfun(@isempty, data.CleanTwt), :);

%% **🔄 分批处理推文情感分析**
n = height(data);
batch_size = 500000; % 每次处理 50 万条数据
num_batches = ceil(n / batch_size); % 计算总批次

% **预分配存储变量**
Sentiment = nan(n, 1);
SentimentMax = nan(n, 1);
SentimentMin = nan(n, 1);
SentimentMedian = nan(n, 1);
SentimentVar = nan(n, 1);
ExtremeSentimentCount = nan(n, 1);

% **启动并行池**
num_workers = min(6, num_batches); % 确保并行池不会超过批次数
% **检查并行池是否已存在**
if isempty(gcp('nocreate'))
    parpool(num_workers);
else
    disp('✅ 并行池已存在，继续使用当前并行池。');
end


for batch_idx = 1:num_batches
    fprintf('🚀 Processing batch %d/%d...\n', batch_idx, num_batches);
    
    % **计算当前批次范围**
    start_idx = (batch_idx - 1) * batch_size + 1;
    end_idx = min(batch_idx * batch_size, n);
    batch_indices = start_idx:end_idx;
    
    % **创建局部变量避免 parfor 复制整个表**
    tweetTexts = data.CleanTwt(batch_indices);
    batch_size_actual = numel(batch_indices);

    % **并行计算**
    batchSentiment = nan(batch_size_actual, 1);
    batchSentimentMax = nan(batch_size_actual, 1);
    batchSentimentMin = nan(batch_size_actual, 1);
    batchSentimentMedian = nan(batch_size_actual, 1);
    batchSentimentVar = nan(batch_size_actual, 1);
    batchExtremeSentimentCount = nan(batch_size_actual, 1);

    parfor i = 1:batch_size_actual
        documents = tokenizedDocument(tweetTexts{i}); % 令牌化推文
        tokens = tokenDetails(documents);  % 获取推文的单词列表
        wordsList = tokens.Token;  % 提取单词
        scores = zeros(size(wordsList));

        % 遍历推文中的每个单词，查找情感得分
        for j = 1:numel(wordsList)
            word = string(wordsList{j});  % 确保单词是字符串
            if isKey(sentimentDict, word)
                scores(j) = sentimentDict(word); % 获取单词的情感得分
            end
        end

        % 计算推文的情感统计量
        if ~isempty(scores)
            batchSentiment(i) = mean(scores);  % 计算均值
            batchSentimentMax(i) = max(scores); % 计算最大值
            batchSentimentMin(i) = min(scores); % 计算最小值
            batchSentimentMedian(i) = median(scores); % 计算中位数
            batchSentimentVar(i) = var(scores); % 计算方差
            batchExtremeSentimentCount(i) = sum(scores > 0.75 | scores < -0.75); % 计算极端情感
        end
    end
    
    % **保存批次结果**
    Sentiment(batch_indices) = batchSentiment;
    SentimentMax(batch_indices) = batchSentimentMax;
    SentimentMin(batch_indices) = batchSentimentMin;
    SentimentMedian(batch_indices) = batchSentimentMedian;
    SentimentVar(batch_indices) = batchSentimentVar;
    ExtremeSentimentCount(batch_indices) = batchExtremeSentimentCount;
end

%% **📊 统计情感得分（按分钟）**
data.Sentiment = Sentiment;
data.SentimentMax = SentimentMax;
data.SentimentMin = SentimentMin;
data.SentimentMedian = SentimentMedian;
data.SentimentVar = SentimentVar;
data.ExtremeSentimentCount = ExtremeSentimentCount;
data.Datetime = dateshift(data.date, 'start', 'minute');

% **计算各种情感统计值**
aggregated_stats = groupsummary(data, 'Datetime', {'mean', 'median', 'max', 'min', 'var'}, 'Sentiment');

%% **💾 保存数据**
writetable(aggregated_stats, 'Sentiment_cleaned_1min.csv');
disp('✅ Bitcoin Tweet Sentiment saved to CSV successfully.');

% **获取过去90天的数据**
end_date = max(aggregated_stats.Datetime);
start_date = end_date - days(90);
filtered_sentiment = aggregated_stats(aggregated_stats.Datetime >= start_date & ...
    aggregated_stats.Datetime <= end_date, :);

% **保存过去90天的数据**
writetable(filtered_sentiment, 'Sentiment_cleaned_90days_1min.csv');
disp('✅ Filtered Bitcoin Tweet Sentiment for the last 90 days saved to CSV successfully.');

