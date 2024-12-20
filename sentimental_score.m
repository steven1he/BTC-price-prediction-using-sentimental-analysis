% 设置初始环境
clc; clear; close all;

% 加载CSV数据
filename = 'Bitcoin_tweets.csv';
opts = detectImportOptions(filename, 'Delimiter', ',', 'VariableNamesLine', 1);
opts = setvaropts(opts, 'text', 'WhitespaceRule', 'preserve');
data = readtable(filename, opts);

% 去除重复值
data = unique(data, 'rows');
disp(['Shape after removing duplicates: ', num2str(size(data))]);

% 转换'date'列为日期时间格式
data.date = datetime(data.date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss', 'Format', 'yyyy-MM-dd HH:mm:ss');

% 删除无效日期和文本
data = data(~isnat(data.date) & ~cellfun('isempty', data.text), :);
disp(['Shape after dropping invalid datetime values: ', num2str(size(data))]);

% 清理推文的函数
clean_tweet = @(twt) regexprep(regexprep(regexprep(regexprep(regexprep( ...
    twt, '#bitcoin|#Bitcoin|#btc', 'bitcoin', 'ignorecase'), ...  % 替换#bitcoin
    '#[A-Za-z0-9]+', ''), ...                                    % 移除其他主题标签
    '\n', ''), ...                                               % 移除换行符
    'https?://\S+', ''), ...                                     % 移除链接
    '@\w+ *', '');                                               % 移除提及用户

% 清理推文
data.CleanTwt = cellfun(clean_tweet, data.text, 'UniformOutput', false);

% 加载情感词典
lexiconPath = 'vader_lexicon.txt';
lexicon = readtable(lexiconPath, 'Delimiter', '\t', ...
                    'ReadVariableNames', false, 'Format', '%s%f%s%s');
lexicon.Properties.VariableNames = {'Word', 'Score', 'Unused1', 'Unused2'};
sentimentDict = containers.Map(lexicon.Word, lexicon.Score);

% VADER情感分析
numTexts = height(data);
sentimentScores = zeros(numTexts, 1);

for i = 1:numTexts
    text = lower(data.CleanTwt{i}); % 转为小写
    words = split(regexprep(text, '[^\w\s]', '')); % 移除标点符号并分词

    % 计算情感得分
    wordScores = zeros(numel(words), 1);
    for j = 1:numel(words)
        word = words{j};
        if isKey(sentimentDict, word)
            wordScores(j) = sentimentDict(word);
        end
    end

    % 修正得分（处理否定词）
    for j = 1:numel(words)
        if isKey(sentimentDict, words{j})
            % 检查前一个词是否是否定词
            if j > 1 && isNegation(words{j-1})
                wordScores(j) = -wordScores(j);
            end
        end
    end

    % 计算复合分数
    if ~isempty(wordScores)
        sentimentScores(i) = sum(wordScores) / sqrt(sum(wordScores.^2) + 15);
    end
end

data.Sentiment = sentimentScores;

% 按每分钟分组并计算多种统计量
data.Datetime = dateshift(data.date, 'start', 'minute');
mean_sentiment = varfun(@mean, data, 'InputVariables', 'Sentiment', 'GroupingVariables', 'Datetime');
median_sentiment = varfun(@median, data, 'InputVariables', 'Sentiment', 'GroupingVariables', 'Datetime');
max_sentiment = varfun(@max, data, 'InputVariables', 'Sentiment', 'GroupingVariables', 'Datetime');
min_sentiment = varfun(@min, data, 'InputVariables', 'Sentiment', 'GroupingVariables', 'Datetime');
var_sentiment = varfun(@var, data, 'InputVariables', 'Sentiment', 'GroupingVariables', 'Datetime');

extreme_sentiment_count = groupsummary(data, 'Datetime', @(x) sum(x > 0.75 | x < -0.75), 'Sentiment');

% 合并统计量
aggregated_stats = join(mean_sentiment, median_sentiment);
aggregated_stats = join(aggregated_stats, max_sentiment);
aggregated_stats = join(aggregated_stats, min_sentiment);
aggregated_stats = join(aggregated_stats, var_sentiment);
aggregated_stats = join(aggregated_stats, extreme_sentiment_count);

% 创建完整的每分钟日期范围并填补缺失的时间点
full_date_range = (min(data.Datetime):minutes(1):max(data.Datetime))';
minute_sentiment_complete = table(full_date_range, 'VariableNames', {'Datetime'});
minute_sentiment_complete = outerjoin(minute_sentiment_complete, aggregated_stats, 'Keys', 'Datetime', 'MergeKeys', true);

% 对缺失值进行线性插值
for col = 2:width(minute_sentiment_complete)
    if isnumeric(minute_sentiment_complete{:, col})
        minute_sentiment_complete{:, col} = fillmissing(minute_sentiment_complete{:, col}, 'linear');
    else
        minute_sentiment_complete{:, col} = fillmissing(minute_sentiment_complete{:, col}, 'constant', 0);
    end
end

% 保存完整的数据集为CSV文件
writetable(minute_sentiment_complete, 'Sentiment_cleaned_1min.csv');
disp('Bitcoin Tweet Sentiment saved to CSV successfully.');

% 获取过去90天的数据
end_date = max(minute_sentiment_complete.Datetime);
start_date = end_date - days(90);

filtered_sentiment = minute_sentiment_complete(minute_sentiment_complete.Datetime >= start_date & ...
    minute_sentiment_complete.Datetime <= end_date, :);

% 保存过去90天的数据为CSV文件
writetable(filtered_sentiment, 'Sentiment_cleaned_90days_1min.csv');
disp('Filtered Bitcoin Tweet Sentiment for the last 90 days saved to CSV successfully.');

% 辅助函数
function isNeg = isNegation(word)
    % 判断是否为否定词
    negations = {'not', 'no', 'never', 'none', 'nobody', 'nothing', 'neither', 'nor', 'nowhere'};
    isNeg = any(strcmp(word, negations));
end
