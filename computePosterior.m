%compute posterior for the current cell
function obj= computePosterior(obj, x, y, likelihoodDistribution)

evidence= sum(likelihoodDistribution.*reshape(obj.fieldPrior(x,y,:), 1, size(obj.temperatureVector,2)));
posterior= (likelihoodDistribution.*reshape(obj.fieldPrior(x,y,:), 1, size(obj.temperatureVector,2)))./evidence;

obj.fieldPosterior(x,y,:)= reshape(posterior, 1,1, size(obj.temperatureVector,2));

%***********************update mutual information!!
obj= updateMutualInformation(obj, x, y);
%***********************update prior with computed posterior
obj.fieldPrior(x,y,:)= obj.fieldPosterior(x,y,:);
%
end
