%compute gradient and find best direction to move to. For now it s a
%greedy strategy ie move to the neighbouring cell with the higest
%value in the mutual information map
function bestDirection= findBestDirection(obj)
x= ceil(obj.robotPosition(1)/5);
y= ceil(obj.robotPosition(2)/5);

%checking x boundaries
if x== size(obj.mutualInformationMap,1)
    rangeX=(x-1:x);
    rangeDirectionsX= (1:2);
elseif x== 1
    rangeX=(x:x+1);
    rangeDirectionsX= (2:3);
else
    rangeX=(x-1:x+1);
    rangeDirectionsX=(1:3);
end
%checking y boundaries
if y== size(obj.mutualInformationMap,2)
    rangeY=(y-1:y);
    rangeDirectionsY= (1:2);
elseif y== 1
    rangeY=(y:y+1);
    rangeDirectionsY= (2:3);
else
    rangeY=(y-1:y+1);
    rangeDirectionsY= (1:3);
end
%
%
%
%             %[mapGradientX, mapGradientY]= gradient(obj.mutualInformationMap, 1);
%             GradientMagnitude= gradient(obj.mutualInformationMap);
%             %GradientMagnitude= sqrt(mapGradientX.^2 + mapGradientY.^2);
%
%             subplot(3,2,5)
%             surf(obj.mutualInformationMap)
%             title('Mutual information map')
%             drawnow
%
%
%             neighbourMaxima= imregionalmax(GradientMagnitude(rangeX, rangeY));
%
%             linearIndexes= find(neighbourMaxima>.5);
%             indexPermutation= randperm(size(linearIndexes,1));
%             selectedLinearIndex= linearIndexes(indexPermutation(1));
%             [relativeX, relativeY]= ind2sub(size(neighbourMaxima),selectedLinearIndex);
%             %check if it s on top edge of thre grid
%             if x== 1
%                 realX= x-1+relativeX;
%             else
%                 realX= x-2+relativeX;
%             end
%             %check if it on left edge of the grid
%             if y== 1
%                 realY= y-1+relativeY;
%             else
%                 realY= y-2+relativeY;
%             end
%             bestDirection=[realX realY];

[mapGradientX, mapGradientY]= gradient(obj.mutualInformationMap);
GradientMagnitude= sqrt(mapGradientX.^2 + mapGradientY.^2);

subplot(3,2,5)
% surf(GradientMagnitude)
% title('Mutual information gradient map')
% drawnow

v=1:size(obj.mutualInformationMap,1);
% contour(v,v,obj.mutualInformationMap),
% hold on
quiver(v,v,mapGradientX,mapGradientY)
grid on
drawnow

directionMatrixX= [-1/sqrt(2) -1 -1/sqrt(2); 0 0 0; 1/sqrt(2) 1 1/sqrt(2)];
directionMatrixY= [-1/sqrt(2) 0 1/sqrt(2); -1 0 1; -1/sqrt(2) 0 1/sqrt(2)];

directionalGradient= (mapGradientX(rangeX, rangeY).*directionMatrixX(rangeDirectionsX,rangeDirectionsY))+...
    (mapGradientY(rangeX,rangeY).*directionMatrixY(rangeDirectionsX,rangeDirectionsY));

neighbourMaxima= imregionalmax(directionalGradient);
linearIndexes= find(neighbourMaxima>.5);
indexPermutation= randperm(size(linearIndexes,1));
selectedLinearIndex= linearIndexes(indexPermutation(1));
[relativeX, relativeY]= ind2sub(size(neighbourMaxima),selectedLinearIndex);
if x== 1
    realX= x-1+relativeX;
else
    realX= x-2+relativeX;
end
%check if it is on left edge of the grid
if y== 1
    realY= y-1+relativeY;
else
    realY= y-2+relativeY;
end
bestDirection=[realX realY];


disp('***debug*****')
disp(strcat('current position:', num2str([x y])))
disp(strcat('Value of the gradient map : ', num2str(directionalGradient)))
disp(num2str(neighbourMaxima))
disp('gradient x direction: ')
mapGradientX(rangeX, rangeY)
disp('Gradient y direcrtion: ')
mapGradientY(rangeX, rangeY)
disp(strcat(num2str('Best direction: ')))
disp(bestDirection)
disp('***debug*****')

end