% 初始化工作目录?
if ~exist('result_picture', 'dir'), mkdir('result_picture'); end
if ~exist('best_model', 'dir'), mkdir('best_model'); end

% 加载数据
trainData = StockDataset('filtered_merged_sentiment_price1.csv', 5, false);
valData = StockDataset('filtered_merged_sentiment_price1.csv', 5, true);
testData = StockDataset('filtered_merged_sentiment_price1.csv', 5, true);

disp('load data succes')

% [trainInput, trainResponse] = convertToCell(trainData);
[trainInput, trainResponse] = convertToCell(trainData);
[valInput, valResponse] = convertToCell(valData);

disp('load data succes')
% 定义模型
model = CNNLSTMModel();
disp('Training model: Base');
% analyzeNetwork(model.Layers)
% connectLayers(layers, 'res_block_conv2', 'add/in2');
% 定义训练选项，启用 GPU
%layerOutputs = activations(model, trainInput, 'last')
% layerOutputs = activations(model, trainInput)
%
options = trainingOptions('adam',...
    'InitialLearnRate', 0.01,...
    'MaxEpochs', 100,...
    'MiniBatchSize', 256,...
    'Shuffle', 'every-epoch',...
    'ValidationData', {valInput, valResponse},...
    'ValidationFrequency', 10,...
    'ExecutionEnvironment', 'gpu', ... % 鍦? GPU 涓婅缁?
    'Verbose', true,...
    'Plots', 'training-progress');

% 练网络
trainedModel = trainNetwork(trainInput, trainResponse,model.Layers, options);

% 测试过程
disp('Testing...');
[testInput, testResponse] = convertToCell(testData);
predictions = predict(trainedModel, testInput, 'ExecutionEnvironment', 'gpu');

% 反归一化?
predictions = testData.highScaler(1) + predictions * (testData.highScaler(2) - testData.highScaler(1));
labels = testData.highScaler(1) + testData.targetSequence * (testData.highScaler(2) - testData.highScaler(1));

% 绘制结果
figure;
plot(labels, 'b', 'DisplayName', 'True Labels');
hold on;
plot(predictions, 'r', 'DisplayName', 'Predictions');
title('Prediction vs True Labels');
xlabel('Time');
ylabel('Price');
legend;
saveas(gcf, 'result_picture/prediction_vs_true.png');
disp('结果图已保存至 result_picture 文件夹');



% 批量转换数据
function [inputCell, responseCell] = convertToCell(dataSet)
    % inputCell = permute(dataSet.dataSequence, [3,2,1]);
    inputCell = permute(num2cell(dataSet.dataSequence, [1, 2]),[3,1,2]);
    %inputCell_expand = inputCell(:,:,1);
    responseCell =  reshape(dataSet.targetSequence, [dataSet.length(), 1]);
end