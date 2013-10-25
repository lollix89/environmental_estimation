%compute gradient and find best direction to move to. For now it s a
%greedy strategy ie move to the neighbouring cell with the higest
%value in the mutual information map
function bestDirection= findBestDirection(obj)
x= ceil(obj.robotPosition(1)/obj.gridCoarseness);
y= ceil(obj.robotPosition(2)/obj.gridCoarseness);

bestDirection=[];

%checking x boundaries
if x== size(obj.mutualInformationMap,1)
    rangeX=(x-1:x);
elseif x== 1
    rangeX=(x:x+1);
else
    rangeX=(x-1:x+1);
end
%checking y boundaries
if y== size(obj.mutualInformationMap,2)
    rangeY=(y-1:y);
elseif y== 1
    rangeY=(y:y+1);
else
    rangeY=(y-1:y+1);
end

%----------computing difference map-----------
pivotValue= obj.mutualInformationMap(x,y);
directionGradientMatrix= obj.mutualInformationMap(rangeX, rangeY)- pivotValue;   

% disp('***debug*****')
% disp(strcat('current position:', num2str([x y])))
% disp(strcat('Value of the gradient map : ', num2str(directionGradientMatrix)))

%size(directionGradientMatrix,1)*size(directionGradientMatrix,2)-1 is the
%number of possible directions
for i=1: size(directionGradientMatrix,1)*size(directionGradientMatrix,2)-1

    neighbourMaxima= zeros(size(directionGradientMatrix));
    maxValue= max(directionGradientMatrix(:));
    [x_,y_]= ind2sub(size(directionGradientMatrix),find(directionGradientMatrix==maxValue));
    neighbourMaxima(sub2ind(size(neighbourMaxima),x_,y_))= 1;

    linearIndexes= find(neighbourMaxima>.5);
    indexPermutation= randperm(size(linearIndexes,1));
    selectedLinearIndex= linearIndexes(indexPermutation(1));
    %make sure thew selected index won t be the maximum in the next iteration
    directionGradientMatrix(selectedLinearIndex)= -Inf;
    [relativeX, relativeY]= ind2sub(size(neighbourMaxima),selectedLinearIndex);

    if x== 1
        realX= relativeX-1;
    else
      realX= relativeX-2;
    end
    if y== 1
        realY= relativeY-1;
    else
        realY= relativeY-2;
    end
    bestDirection= [bestDirection [realX realY]'];

end

% disp(bestDirection)
% disp('***debug*****')

end