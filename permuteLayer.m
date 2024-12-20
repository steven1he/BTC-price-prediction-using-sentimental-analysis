classdef permuteLayer < nnet.layer.Layer
    
    properties
        PermuteOrder
    end
    
    methods
        function layer = permuteLayer(permuteOrder, name)
            % Constructor function for the PermuteLayer
            layer.Name = name;
            layer.PermuteOrder = permuteOrder;
            layer.Description = "Permute layer with order " + mat2str(permuteOrder);
        end
        
        function Z = predict(layer, X)
            % Forward input data through the layer at prediction time
            Z = permute(X, layer.PermuteOrder);
        end
    end
end