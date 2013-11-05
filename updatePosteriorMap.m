function obj= updatePosteriorMap(obj, fieldValue, x, y)

[~, closestValueIndex] = min(abs(obj.temperatureVector-fieldValue));

sill= 25;

for x_=1:size(obj.fieldPosterior,1)
    for y_=1:size(obj.fieldPosterior,2)
        
        currentDistance= pdist([x y; (x_*obj.gridCoarseness)-floor(obj.gridCoarseness/2) (y_*obj.gridCoarseness)-floor(obj.gridCoarseness/2)]);

        if currentDistance <= obj.RField.Range
            varianceFunction= obj.likelihoodVariance + (sill*(1.5*(currentDistance/obj.RField.Range)-.5*(currentDistance/obj.RField.Range)^3));
        else
            varianceFunction=  sill;
        end
        
%         if currentDistance < 5
%             disp('%%%%%%%%%%%%%%%%%%')
%             disp(strcat('current cell is: ', num2str(x_), '-', num2str(y_)))
%             disp(strcat('pivot cell is: ', num2str(discreteCellPositionX), '-', num2str(discreteCellPositionY)))
%             disp(strcat('currentDistance: ', num2str(currentDistance)))
%             disp(strcat('discreteRange: ', num2str(discreteRange)))
%             disp(strcat('variance value: ', num2str(varianceFunction)))
%             disp('%%%%%%%%%%%%%%%%%%')
%         end

        likelihoodCurrentCell= pdf(obj.likelihoodDistribution, obj.temperatureVector, obj.temperatureVector(closestValueIndex), varianceFunction);
        likelihoodCurrentCell= likelihoodCurrentCell./sum(likelihoodCurrentCell);
        obj= computePosterior(obj, x_, y_, likelihoodCurrentCell);
    end
end




end