% 设置初始环境
clc; clear; close all;

% 读取 CSV 文件
file_path = 'btcusd_1-min_data.csv'; % 替换为你的文件路径
data = readtable(file_path);

% 将 UNIX 时间戳转换为日期时间格式
% 假设列名为 'Timestamp'
if ismember('Timestamp', data.Properties.VariableNames)
    data.Timestamp = datetime(data.Timestamp, 'ConvertFrom', 'posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss');
    disp('时间戳已成功转换！');
else
    error('CSV 文件中找不到列名 ''Timestamp''。请检查文件内容。');
end

% 查看转换后的数据
disp('转换后的数据前五行：');
disp(data(1:5, :));

% 保存为新文件
output_file = 'converted_timestamp_data.csv';
writetable(data, output_file);
disp(['时间戳已转换并保存到 ', output_file]);
