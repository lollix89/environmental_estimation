%sample from the probability distribution on each cell and returns a map
%of temperatures
function sampledTemperatureMap= sampleTemperatureProbability(obj, plot)
global PlotOn;

sampledTemperatureMap= nan(size(obj.fieldPosterior,1), size(obj.fieldPosterior,2));


for x=1:size(obj.fieldPosterior, 1)
    for y=1:size(obj.fieldPosterior, 2)
        
        %-------if the cell is unexplored it is useless to sample from uniform
        %probability (should never happen now)------
        if range(reshape(obj.fieldPosterior(x,y,:), 1, size(obj.temperatureVector,2)))== 0
            sampledTemperatureMap(((5*(x-1))+1):((5*(x-1))+5),((5*(y-1))+1):((5*(y-1))+5)) = NaN;
        %----------else sample from the probability distribution----
        else
            c = cumsum(reshape(obj.fieldPosterior(x,y,:), 1, size(obj.temperatureVector,2)));
            for i=1:5
                for j=1:5
                    r = rand(1,1);
                    e = [0,c];
                    [~,bin] = histc(r,e);
                    sampledTemperatureMap(((5*(x-1))+i),((5*(y-1))+j)) = obj.temperatureVector(bin);
                end
            end
        end
    end
end

%-------------------plot sampled temperature map ----------
if PlotOn==1 && plot==1
    subplot(3,2,4)
    imagesc(sampledTemperatureMap);
    title('Temperature map from observations')

end

end
