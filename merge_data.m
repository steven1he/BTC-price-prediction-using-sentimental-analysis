%% 🚀 初始化环境
clc; clear; close all;

%% 📥 读取数据
sentiment_file = 'Sentiment_cleaned_90days_1min.csv';
price_file = 'btcusd_1-min_data.csv';

sentiment_data = readtable(sentiment_file);
price_data = readtable(price_file);

%% 🕒 处理时间格式
% 确保 sentiment_data 的时间格式正确
sentiment_data.Datetime = datetime(sentiment_data.Datetime, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');

% 转换 price_data 的时间戳为 Datetime，并去掉时区
price_data.Datetime = datetime(price_data.Timestamp, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
price_data.Datetime.TimeZone = '';  % 确保与 sentiment_data 格式一致

%% 🎯 只保留 sentiment_data 中出现的时间点对应的 price_data
price_data = price_data(ismember(price_data.Datetime, sentiment_data.Datetime), :);

%% ✂️ **删除 `Timestamp` 列**
price_data.Timestamp = [];

%% 🔗 进行合并
% **保留 sentiment_data 全部列**
% **保留 price_data 只有 Open, High, Low, Close, Volume 这五列**
merged_data = innerjoin(sentiment_data, price_data, 'Keys', 'Datetime');

%% 💾 保存合并后的数据
output_file = 'filtered_merged_sentiment_price1.csv';
writetable(merged_data, output_file);
disp(['✅ 已删除 Timestamp，最终数据保存到: ', output_file]);
