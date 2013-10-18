function startSimulation()

close all

%Load a random field
if isdir('./RandomFields')
    % choose randomly
    FT= randi([1 2]);
    fieldNum= randi([1 100]);
    
    if FT==1
        field=load(['./RandomFields/RandField_LR_No' num2str(200+fieldNum) '.csv']);
    elseif FT==2
        field=load(['./RandomFields/RandField_IR_No' num2str(100+fieldNum) '.csv']);
    elseif FT==3
        field=load(['./RandomFields/RandField_SR_No' num2str(fieldNum) '.csv']);
    end
else
    error('Directory does not exist!!!')
end

%initialize field
rF= randomField(field);

%initialize object
r = robot(rF,(size(field)));
%r.plotLikelihood();

figure(1)


subplot(3,2,3)
imagesc(r.RField.Field)
hold on;

%simulation step
for i=1:2000
    r= r.flyNextWayPoints();
end

temperatureMap= sampleTemperatureProbability(r);
errorMap= abs(field - temperatureMap);


subplot(3,2,6)
surf(errorMap)
title('Error map')

end
 