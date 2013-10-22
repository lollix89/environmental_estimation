function obj= updateMutualInformation(obj, x, y)

%xEntropy= entropy (reshape(obj.fieldPrior(x,y,:), 1, size(obj.temperatureVector,2)));
xyEntropy= entropy(reshape(obj.fieldPosterior(x,y,:), 1, size(obj.temperatureVector,2)));

obj.mutualInformationMap(x,y)= xyEntropy; %xEntropy- xyEntropy;

end