function findmaxmin()
maxV=-Inf;
minV= +Inf;
for i=1:300
    if i<= 100
        field=load(['./RandomFields/RandField_SR_No' num2str(i) '.csv']);
        
    elseif i> 100 && i<=200
        field=load(['./RandomFields/RandField_IR_No' num2str(i) '.csv']);
        
    else
        field=load(['./RandomFields/RandField_LR_No' num2str(i) '.csv']);
        
    end
    
    if max(field(:)) > maxV
        maxV= max(field(:));
    end
    if min(field(:)) < minV
        minV= min(field(:));
    end
    
end
maxV
minV
end