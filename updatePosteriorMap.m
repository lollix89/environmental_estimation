function obj= updatePosteriorMap(obj,fieldValue, x, y)
if nargin == 2
    discreteCellPositionX= ceil(obj.robotPosition(1)/obj.gridCoarseness);
    discreteCellPositionY= ceil(obj.robotPosition(2)/obj.gridCoarseness);
else
    discreteCellPositionX= ceil(x/obj.gridCoarseness);
    discreteCellPositionY= ceil(y/obj.gridCoarseness);
end

[~, closestValueIndex] = min(abs(obj.temperatureVector-fieldValue));

for x_=1:size(obj.fieldPosterior, 1)
    for y_=1:size(obj.fieldPosterior, 2)
        %compute distance from the current position of the robot on the
        %discrete grid
        currentDistance= pdist([discreteCellPositionX discreteCellPositionY; x_ y_]);
        
        sill= 25* (1/obj.temperatureInterval);
        discreteRange= (obj.RField.Range)/obj.gridCoarseness;
        
        if currentDistance <= discreteRange
            varianceFunction= obj.likelihoodVariance + (sill - obj.likelihoodVariance)*(1.5*(currentDistance/discreteRange)-.5*(currentDistance/discreteRange)^3);
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