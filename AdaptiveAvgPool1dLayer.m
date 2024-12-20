classdef AdaptiveAvgPool1dLayer < nnet.layer.Layer
    
    properties
        % (Optional) Layer properties
        % Layer properties go here
    end
    
    methods
        function layer = AdaptiveAvgPool1dLayer(name)
            % Constructor (optional)
            % Set layer name
            if nargin == 1
                layer.Name = name;
            end
            
            % Set layer description
            layer.Description = 'Adaptive 1D Average Pooling Layer';
        end

        function Z = predict(layer, X)
            % Forward input data through the layer at prediction time)
            % Apply 1D average pooling (pool across the second dimension)
            X = permute(X, [1, 3, 2]); % Transpose along last two dimensions
            Z = mean(X, 2); % Take the mean across the second dimension
            Z = permute(Z, [1, 3, 2]); % Revert the transposition
        end

        function Z = forward(layer, X)
            % Forward input data through the layer at prediction time
            Z = predict(layer, X); % Use the predict method
        end

        function dLdX = backward(layer, X, Z, dLdZ, memory)
            % Backward propagate the derivative of the loss function through 
            % the layer (this method is required if you are going to train 
            % the network).
            % Gradient of average pooling is distributed evenly
            X = permute(X, [1, 3, 2]); % Transpose along last two dimensions
            dLdZ = permute(dLdZ, [1, 3, 2]); % Transpose along last two dimensions
            dLdX = dLdZ / size(X, 2); % Take the gradient mean
            dLdX = repelem(dLdX, 1, size(X, 2)); % Repeat for distribution
            dLdX = permute(dLdX, [1, 3, 2]); % Revert the transposition
        end
    end
end