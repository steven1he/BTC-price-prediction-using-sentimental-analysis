classdef StockDataset
    properties
        dataSequence
        targetSequence
        highScaler
    end
    
    methods
        function obj = StockDataset(dataPath, sequenceLength, isTest)
            % ��ȡ����
            opts = detectImportOptions(dataPath);
            df1 = readtable(dataPath, opts);
            
            % ���� 'High' ������ҪԤ���Ŀ�꣬��Ϊ��ǩ
            % df1.High = str2double(df1.High);
            
            % ȷ�� 'Datetime' �в��������
            if any(strcmp(opts.VariableNames,'Datetime'))
                df1.Datetime = [];
            end
            
            % ���������Ŀ��ֵ�������
            numeric_columns = df1(:, vartype('double'));  % ��������ֵ��
            correlation_matrix = corr(table2array(numeric_columns), 'Rows','complete');  % ��������Ծ���
            
            disp("������Ŀ��ֵ High �������:");
            disp(correlation_matrix(:, strcmp(numeric_columns.Properties.VariableNames, 'High')));
            
            % ���������ѡ�����غ��е��������
            features = {'Close', 'Low', 'min_sentiment', 'var_sentiment', 'mean_sentiment'};
            
            % ��ȡ������Ŀ��ֵ
            featureData = table2array(df1(:, features));
            labels = df1.High;

            
            % ������Ƭ
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
            % ��һ������
            data = featureScaler(data);
            % ��һ��Ŀ��ֵ
            target = featureScaler(target);
                    
            % ����ʱ����������
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