function obj= updatePosteriorMap(obj,fieldValue)
discreteCellPositionX= ceil(obj.robotPosition(1)/5);
discreteCellPositionY= ceil(obj.robotPosition(2)/5);

[~, closestValueIndex] = min(abs(obj.temperatureVector-fieldValue));

for x=1:size(obj.fieldPosterior, 1)
    for y=1:size(obj.fieldPosterior, 2)
        %compute distance from the current position of the robot
        currentDistance= pdist([discreteCellPositionX discreteCellPositionY; x y]);
        %for now the variance of the likelihood of the neighbouring
        %cells is a coefficient, need to find the formula that relates
        %the range of the field to the variance
        likelihoodCurrentCell= pdf(obj.likelihoodDistribution, obj.temperatureVector, obj.temperatureVector(closestValueIndex), (currentDistance+1)^2); %figure out how distance relates to variance
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