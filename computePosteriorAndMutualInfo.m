function obj= computePosteriorAndMutualInfo(obj,fieldValue, x, y)


[~, closestValueIndex] = min(abs(obj.temperatureVector-fieldValue));

for x_=1:size(obj.fieldPosterior, 1)
    for y_=1:size(obj.fieldPosterior, 2)
        currentDistance= pdist([x y; ceil(x_*obj.gridCoarseness)-floor(obj.gridCoarseness/2) ceil(y_*obj.gridCoarseness)-floor(obj.gridCoarseness/2)]);


        if currentDistance <= obj.RField.Range
            varianceFunction= .1 + .05*currentDistance;
        else
            varianceFunction=  .1 + .2*currentDistance;
        end
        

        likelihoodCurrentCell= pdf(obj.likelihoodDistribution, obj.temperatureVector, obj.temperatureVector(closestValueIndex), varianceFunction);
        likelihoodCurrentCell= likelihoodCurrentCell./sum(likelihoodCurrentCell);      
        %compute posterior        
        evidence= sum(likelihoodCurrentCell.*reshape(obj.fieldPrior(x_,y_,:), 1, size(obj.fieldPrior,3)));
        posterior= (likelihoodCurrentCell.*reshape(obj.fieldPrior(x_,y_,:), 1, size(obj.fieldPrior,3)))./evidence;
        obj.fieldPosterior(x_,y_,:)= reshape(posterior, 1,1, size(obj.fieldPosterior,3));
        if any(isnan(posterior))
           disp('nooo') 
        end
        
        %update mutual information!!        
        %xEntropy= entropy (reshape(obj.fieldPrior(x,y,:), 1, size(obj.temperatureVector,2)));
        xyEntropy= entropy(reshape(obj.fieldPosterior(x_,y_,:), 1, size(obj.fieldPrior,3)));

        obj.mutualInformationMap(x_,y_)= xyEntropy; %xEntropy- xyEntropy;
    end
end

obj.fieldPrior= obj.fieldPosterior;




end