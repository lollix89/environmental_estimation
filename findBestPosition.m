function [bestPositionX bestPositionY] = findBestPosition(obj)

    [~, idx]= max(obj.mutualInformationMap(:));
    [bestPositionX, bestPositionY]= ind2sub(size(obj.mutualInformationMap), idx);
end