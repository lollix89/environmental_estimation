function obj= updatePosteriorMap(obj,fieldValue, x, y)
if nargin == 2
    discreteCellPositionX= ceil(obj.robotPosition(1)/obj.gridCoarseness);
    discreteCellPositionY= ceil(obj.robotPosition(2)/obj.gridCoarseness);
else
    discreteCellPositionX= ceil(x/obj.gridCoarseness);
    discreteCellPositionY= ceil(y/obj.gridCoarseness);
end

[~, closestValueIndex] = min(abs(obj.temperatureVector-fieldValue));

sill= 25;

for x_=1:size(obj.fieldPosterior, 1)
    for y_=1:size(obj.fieldPosterior, 2)
        %compute distance from the current position of the robot on the
        %discrete grid
        %currentDistance= pdist([posX posY; (x_*obj.gridCoarseness)-floor(obj.gridCoarseness/2) (y_*obj.gridCoarseness)-floor(obj.gridCoarseness/2)]);
        currentDistance= pdist([discreteCellPositionX discreteCellPositionY; x_ y_]);

        if currentDistance== 0
            varianceFunction= obj.likelihoodVariance;
        elseif currentDistance <= obj.RField.Range/obj.gridCoarseness
            varianceFunction= (sill*(1.5*(currentDistance/(obj.RField.Range/obj.gridCoarseness))-.5*(currentDistance/(obj.RField.Range/obj.gridCoarseness))^3)); 
        else
            varianceFunction=  sill;
        end

%         if currentDistance <= obj.RField.Range/obj.gridCoarseness
%             varianceFunction= currentDistance + obj.likelihoodVariance ;
%         else
%             varianceFunction=  obj.RField.Range/obj.gridCoarseness;
%         end

        likelihoodCurrentCell= pdf(obj.likelihoodDistribution, obj.temperatureVector, obj.temperatureVector(closestValueIndex), varianceFunction);
        likelihoodCurrentCell= likelihoodCurrentCell./sum(likelihoodCurrentCell);
        obj= computePosterior(obj, x_, y_, likelihoodCurrentCell);
    end
end




end