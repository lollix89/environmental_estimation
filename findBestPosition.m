function [bestPositionX bestPositionY] = findBestPosition(obj)

    [val, idx]= max(obj.mutualInformationMap(:));
    val
    [bestPositionX, bestPositionY]= ind2sub(size(obj.mutualInformationMap), idx);
end