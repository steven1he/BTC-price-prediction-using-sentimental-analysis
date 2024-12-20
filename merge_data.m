% 设置初始环境
clc; clear; close all;

% 读取CSV文件
file_path = 'all_data_rounded_10min.csv'; % 请替换为你的文件路径
data = readtable(file_path);

% 保留需要的列：Timestamp、High、Low、Close、Volume
columns_to_keep = {'Timestamp', 'High', 'Low', 'Close', 'Volume'};
if all(ismember(columns_to_keep, data.Properties.VariableNames))
    data = data(:, columns_to_keep);
else
    error('CSV文件中缺少必要的列：Timestamp, High, Low, Close, Volume');
end

% 创建新的情感分析列并赋值为0
sentiment_columns = {'mean_sentiment', 'median_sentiment', 'max_sentiment', ...
                     'min_sentiment', 'var_sentiment', 'extreme_sentiment_count'};
for i = 1:numel(sentiment_columns)
    data.(sentiment_columns{i}) = zeros(height(data), 1); % 添加并初始化为0
end

% 将情感分析列插入到High列之前
cols = [{'Timestamp'}, sentiment_columns, {'High', 'Low', 'Close', 'Volume'}];
data = data(:, cols);

% 保存修改后的数据到新CSV文件
output_file = 'modified_pretrain_data.csv';
writetable(data, output_file);

% 打印完成信息
disp(['已保存到 ', output_file]);
