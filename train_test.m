% ��ʼ������Ŀ¼?
if ~exist('result_picture', 'dir'), mkdir('result_picture'); end
if ~exist('best_model', 'dir'), mkdir('best_model'); end

% ��������
trainData = StockDataset('filtered_merged_sentiment_price1.csv', 5, false);
valData = StockDataset('filtered_merged_sentiment_price1.csv', 5, true);
testData = StockDataset('filtered_merged_sentiment_price1.csv', 5, true);

disp('load data succes')

% [trainInput, trainResponse] = convertToCell(trainData);
[trainInput, trainResponse] = convertToCell(trainData);
[valInput, valResponse] = convertToCell(valData);

disp('load data succes')
% ����ģ��
model = CNNLSTMModel();
disp('Training model: Base');
% analyzeNetwork(model.Layers)
% connectLayers(layers, 'res_block_conv2', 'add/in2');
% ����ѵ��ѡ����� GPU
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
    'ExecutionEnvironment', 'gpu', ... % �? GPU 上训�?
    'Verbose', true,...
    'Plots', 'training-progress');

% ������
trainedModel = trainNetwork(trainInput, trainResponse,model.Layers, options);

% ���Թ���
disp('Testing...');
[testInput, testResponse] = convertToCell(testData);
predictions = predict(trainedModel, testInput, 'ExecutionEnvironment', 'gpu');

% ����һ��?
predictions = testData.highScaler(1) + predictions * (testData.highScaler(2) - testData.highScaler(1));
labels = testData.highScaler(1) + testData.targetSequence * (testData.highScaler(2) - testData.highScaler(1));

% ���ƽ��
figure;
plot(labels, 'b', 'DisplayName', 'True Labels');
hold on;
plot(predictions, 'r', 'DisplayName', 'Predictions');
title('Prediction vs True Labels');
xlabel('Time');
ylabel('Price');
legend;
saveas(gcf, 'result_picture/prediction_vs_true.png');
disp('���ͼ�ѱ����� result_picture �ļ���');



% ����ת������
function [inputCell, responseCell] = convertToCell(dataSet)
    % inputCell = permute(dataSet.dataSequence, [3,2,1]);
    inputCell = permute(num2cell(dataSet.dataSequence, [1, 2]),[3,1,2]);
    %inputCell_expand = inputCell(:,:,1);
    responseCell =  reshape(dataSet.targetSequence, [dataSet.length(), 1]);
end