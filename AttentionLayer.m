classdef AttentionLayer < nnet.layer.Layer
    
    properties (Learnable)
        % 学习参数
        Weights % 权重
        Bias    % 偏置
    end
    
    methods
        function layer = AttentionLayer(numInputs, name)
            % 设置层名
            layer.Name = name;

            % 初始化权重
            layer.Weights = randn(1);
            layer.Bias = randn(1);
        end
        
        function Z = predict(layer, X)
            % 前向传播
            % X 是一个 N×1×numFeatures 的数组
            % Z 是一个 1×numFeatures 的数组
            
            % 计算注意力得分
            
            % disp(size(layer.Weights))

            scores = X .* layer.Weights + layer.Bias;
            
            % 计算权重
            % scores = dlarray(scores, 'BC')
            weights = softmax(dlarray(scores,'BC'));
            % 计算加权求和结果
            Z = X;
            % Z = stripdims(Z)
        end
    end
end
