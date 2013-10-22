%keep the entropy of entire environment updated
function entropyMap= updateEntropyMap(obj)

entropyMap= zeros(ceil(obj.fieldExtent(1)/5),ceil(obj.fieldExtent(2)/5));
for x=1: size(obj.fieldPrior, 1)
    for y=1: size(obj.fieldPrior, 2)
           entropyMap(x,y)= entropy(reshape(obj.fieldPrior(x,y,:), 1, size(obj.temperatureVector,2)));   
    end
end

end
