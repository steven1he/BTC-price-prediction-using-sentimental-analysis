classdef StockDataset
    properties
        dataSequence
        targetSequence
        highScaler
    end
    
    methods
        function obj = StockDataset(dataPath, sequenceLength, isTest)
            % 读取数据
            opts = detectImportOptions(dataPath);
            df1 = readtable(dataPath, opts);
            
            % 假设 'High' 是我们要预测的目标，作为标签
            % df1.High = str2double(df1.High);
            
            % 确保 'Datetime' 列不参与分析
            if any(strcmp(opts.VariableNames,'Datetime'))
                df1.Datetime = [];
            end
            
            % 检查特征与目标值的相关性
            numeric_columns = df1(:, vartype('double'));  % 仅保留数值列
            correlation_matrix = corr(table2array(numeric_columns), 'Rows','complete');  % 计算相关性矩阵
            
            disp("特征与目标值 High 的相关性:");
            disp(correlation_matrix(:, strcmp(numeric_columns.Properties.VariableNames, 'High')));
            
            % 根据相关性选择高相关和中等相关特征
            features = {'Close', 'Low', 'min_sentiment', 'var_sentiment', 'mean_sentiment'};
            
            % 提取特征和目标值
            featureData = table2array(df1(:, features));
            labels = df1.High;

            
            % 数据切片
            trainSize = round(size(featureData, 1) * 0.9);
            valSize = round(size(featureData, 1) * 0.05);
            if isTest
                data = featureData(trainSize + valSize + 1:end, :);
                target = labels(trainSize + valSize + 1:end);
            else
                data = featureData(1:trainSize, :);
                target = labels(1:trainSize);
            end
            obj.highScaler = [min(target), max(target)];   
            featureScaler = @(x) (x - min(x)) ./ (max(x) - min(x));
            % 归一化特征
            data = featureScaler(data);
            % 归一化目标值
            target = featureScaler(target);
                    
            % 生成时间序列样本
            obj.dataSequence = [];
            obj.targetSequence = [];
            
            for i = 1:size(data, 1)-sequenceLength
                obj.dataSequence = cat(3, obj.dataSequence, data(i:i+sequenceLength-1, :));
                obj.targetSequence = [obj.targetSequence; target(i+sequenceLength)];
            end
        end
        
        function len = length(obj)
            len = size(obj.dataSequence, 3);
        end
        
        function [data, target] = getItem(obj, idx)
            % data = obj.dataSequence(:,:,idx);
            % target = obj.targetSequence(idx);
            data = obj.dataSequence;
            target = obj.targetSequence;
        end
    end
end