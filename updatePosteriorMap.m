function obj= updatePosteriorMap(obj,fieldValue, x, y)
if nargin == 2
    discreteCellPositionX= ceil(obj.robotPosition(1)/obj.gridCoarseness);
    discreteCellPositionY= ceil(obj.robotPosition(2)/obj.gridCoarseness);
    posX= obj.robotPosition(1);
    posY= obj.robotPosition(2);
else
    discreteCellPositionX= ceil(x/obj.gridCoarseness);
    discreteCellPositionY= ceil(y/obj.gridCoarseness);
    posX= x;
    posY= y;
end

[~, closestValueIndex] = min(abs(obj.temperatureVector-fieldValue));
sill= 25;

for x_=1:size(obj.fieldPosterior, 1)
    for y_=1:size(obj.fieldPosterior, 2)
        %compute distance from the current position of the robot on the
        %discrete grid
        %currentDistance= pdist([posX posY; (x_*obj.gridCoarseness)-floor(obj.gridCoarseness/2) (y_*obj.gridCoarseness)-floor(obj.gridCoarseness/2)]);
        currentDistance= pdist([discreteCellPositionX discreteCellPositionY; x_ y_]);

       
%         if currentDistance <= obj.RField.Range
%             varianceFunction= obj.likelihoodVariance + (sill*(1.5*(currentDistance/obj.RField.Range)-.5*(currentDistance/obj.RField.Range)^3));     %not sure about summing up the variances
%         else
%             varianceFunction=  sill;
%         end

        if currentDistance <= obj.RField.Range/obj.gridCoarseness
            varianceFunction= currentDistance+1;
        else
            varianceFunction=  obj.RField.Range/obj.gridCoarseness;
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