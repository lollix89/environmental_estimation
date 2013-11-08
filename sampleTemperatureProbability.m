%sample from the probability distribution on each cell and returns a map
%of temperatures
function sampledTemperatureMap= sampleTemperatureProbability(obj)

sampledTemperatureMap= nan(size(obj.fieldPosterior,1), size(obj.fieldPosterior,2));


for x=1:size(obj.fieldPosterior, 1)
    for y=1:size(obj.fieldPosterior, 2)
        
        c = cumsum(reshape(obj.fieldPosterior(x,y,:), 1, size(obj.fieldPosterior,3)));
        r = rand(1,1);
        e = [1,c];
        [~,bin] = histc(r,e);
        sampledTemperatureMap(x,y) = obj.temperatureVector(bin);
        
    end
end


end
