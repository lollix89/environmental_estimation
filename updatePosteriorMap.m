function obj= updatePosteriorMap(obj,fieldValue, x, y)
if nargin == 2
    discreteCellPositionX= ceil(obj.robotPosition(1)/5);
    discreteCellPositionY= ceil(obj.robotPosition(2)/5);
else
    discreteCellPositionX= ceil(x/5);
    discreteCellPositionY= ceil(y/5);
end

[~, closestValueIndex] = min(abs(obj.temperatureVector-fieldValue));

for x=1:size(obj.fieldPosterior, 1)
    for y=1:size(obj.fieldPosterior, 2)
        %compute distance from the current position of the robot
        currentDistance= pdist([discreteCellPositionX discreteCellPositionY; x y]);
        %first attempt of relating field range to variance
        if currentDistance <= obj.RField.Range
            currentVariance= (obj.RField.Range- currentDistance)/obj.RField.Range*obj.likelihoodVariance + (currentDistance/obj.RField.Range)*size(obj.temperatureVector,2)/2;
        else
            currentVariance=  (currentDistance/obj.RField.Range)*size(obj.temperatureVector,2)/2;
        end
        
        likelihoodCurrentCell= pdf(obj.likelihoodDistribution, obj.temperatureVector, obj.temperatureVector(closestValueIndex), currentVariance);
        likelihoodCurrentCell= likelihoodCurrentCell./sum(likelihoodCurrentCell);
        
        %         disp('****************debug**********')
        %         disp(strcat('Current position:', num2str(discreteCellPositionX), '-', num2str(discreteCellPositionY)))
        %         disp(strcat('Current cell: ', num2str(x), '-', num2str(y)))
        %         disp(strcat('Distance: ', num2str(currentDistance)))
        
        obj= computePosterior(obj, x, y, likelihoodCurrentCell);
        %         disp(strcat('Current cell mutual information: ',
        %         num2str(obj.mutualInformationMap(x,y))))
    end
end




end