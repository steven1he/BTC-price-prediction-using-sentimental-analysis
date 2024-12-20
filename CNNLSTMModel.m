classdef CNNLSTMModel < handle
    properties
        Layers
    end
    
    methods
        function obj = CNNLSTMModel()
            % ���������
            % Create a simple deep learning model in MATLAB with similar layers
            % transpose = TransposeLayer('transpose_1')
            % expandDimensionLayer = functionLayer(@(X) reshape(X, [1, size(X,1), size(X,2)]), 'Name','expandDim');
            layers = [
                sequenceInputLayer([5 5])
                % permuteLayer([1 4 3 2], 'permute')
                % Convolution Layer 1
                convolution1dLayer(1, 64, 'Name', 'conv1')
                reluLayer('Name', 'relu1')
            
                % Convolution Layer 2
                convolution1dLayer(3, 128, 'Padding', [1 1], 'Name', 'conv2')
                reluLayer('Name', 'relu2')
            
                % Convolution Layer 3
                convolution1dLayer(3, 128, 'Padding', [1 1], 'Name', 'conv3')
                reluLayer('Name', 'relu3')
            
                % Residual Block
                convolution1dLayer(3, 128, 'Padding', 'same', 'Name', 'res_block_conv1')
                reluLayer('Name', 'res_block_relu1')
                convolution1dLayer(3, 128, 'Padding', 'same', 'Name', 'res_block_conv2')
            
                %  Adding a residual connection
                additionLayer(2, 'Name', 'add')
                %reluLayer('Name', 'res_block_out')
                %flatten layer
                averagePooling1dLayer(5, 'Stride', 5, 'Name', 'pool')
                dropoutLayer(0.5)
                flattenLayer('Name', 'flatten')
                lstmLayer(128,'OutputMode','sequence')
                dropoutLayer(0.2)
                lstmLayer(128,'OutputMode','last')
                dropoutLayer(0.2)
                % AttentionLayer(128,'attention')
                % flattenLayer('Name', 'flatten2')
                % Fully connected layers
                fullyConnectedLayer(128, 'Name', 'fc1')
                reluLayer('Name', 'relu_fc1')
                fullyConnectedLayer(64, 'Name', 'fc2')
                reluLayer('Name', 'relu_fc2')
                fullyConnectedLayer(1, 'Name', 'output')
            
                % Output layer for regression
                regressionLayer('Name', 'regressionoutput')
            ];
            obj.Layers = layerGraph(layers);
            %obj.Layers = connectLayers(obj.Layers, 'relu3', 'add/in1');
            obj.Layers = connectLayers(obj.Layers, 'res_block_conv2', 'add/in2');
        end
    end
end




