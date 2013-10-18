%sample from the probability distribution on each cell and returns a map
%of temperatures
function sampledTemperatureMapI= sampleTemperatureProbability(obj)

sampledTemperatureMap= nan(size(obj.fieldPosterior,1), size(obj.fieldPosterior,2));


for x=1:size(obj.fieldPosterior, 1)
    for y=1:size(obj.fieldPosterior, 2)
        
        %if the cell is unexplored it is useless to sample from uniform
        %probability
        if range(reshape(obj.fieldPosterior(x,y,:), 1, size(obj.temperatureVector,2)))== 0
            sampledTemperatureMap(((5*(x-1))+1):((5*(x-1))+5),((5*(y-1))+1):((5*(y-1))+5)) = NaN;
            %else sample from the probability distribution
        else
            c = cumsum(reshape(obj.fieldPosterior(x,y,:), 1, size(obj.temperatureVector,2)));
            for i=1:5
                for j=1:5
                    %sample from the corresponding probability distribution
                    r = rand(1,1);
                    e = [0,c];
                    [~,bin] = histc(r,e);
                    %sampledTemperatureMap(((5*(x-1))+1):((5*(x-1))+5),((5*(y-1))+1):((5*(y-1))+5)) = obj.temperatureVector(bin);
                    sampledTemperatureMap(((5*(x-1))+i),((5*(y-1))+j)) = obj.temperatureVector(bin);
                    %sampledTemperatureMap(x,y) = obj.temperatureVector(bin);
                end
            end
            
        end
    end
end

sampledTemperatureMapI= inpaint_nans(sampledTemperatureMap);

%sampledTemperatureMapI= (sampledTemperatureMapI +
%min(sampledTemperatureMap(:)))/(max(sampledTemperatureMap(:)) - min(sampledTemperatureMap(:)));


% maxb= max(sampledTemperatureMap(:))
% minb= min(sampledTemperatureMap(:))
% 
% maxA= max(sampledTemperatureMapI(:))
% minA= min(sampledTemperatureMapI(:))

subplot(3,2,4)
imagesc(sampledTemperatureMap);
title('Temperature map from observations')

subplot(3,2,5)
imagesc(sampledTemperatureMapI);
title('Temperature map from observations interpolated')


end
