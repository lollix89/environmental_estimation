function startSimulation(jobID, nSimulations)

close all
global PlotOn;
PlotOn= 1;

%-------------position of the stations (static sensors)--------------
stations=[];
stations(:,1)=[24 34 14 94 134 74 94 166 186 174];
stations(:,2)=[166 94 22 14 86 66 174 174 106 34];
%--------------start simulation
for currentSimulation=1:nSimulations
    
    %---------------Load a random field---------------
    if isdir('./RandomFields')
        fieldNum= randi([1 100]);
        
        if mod(jobID, 3)== 1
            field=load(['./RandomFields/RandField_LR_No' num2str(200+fieldNum) '.csv']);
            range= 100;
        elseif mod(jobID,3)== 2
            field=load(['./RandomFields/RandField_IR_No' num2str(100+fieldNum) '.csv']);
            range= 50;
        else
            field=load(['./RandomFields/RandField_SR_No' num2str(fieldNum) '.csv']);
            range= 10;
        end
    else
        error('Directory does not exist!!!')
    end
    
    %--------------------initialize field-------------------------
    rF= randomField(field,range);
    
    
    
    %--------------------initialize object robot--------------------
    r = robot(rF, stations);
    %----------------------plot field---------------------
    if PlotOn==1
        figure(1)
        subplot(3,2,3)
        imagesc(r.RField.Field)
        hold on;
        for i=1:size(stations,1)
            plot(stations(i,2),stations(i,1), 'ko')
        end
        drawnow
        
        hold on;
    end
    
    %-----------------simulation step----------------------
    while r.distance< 3000
        r= r.flyNextWayPoints();
    end
    %-------------------sample temperature from resulting probability---------------
    sampleTemperatureProbability(r, 1);
    %errorMap= abs(field - temperatureMap);
    
    xSampled= r.data(3,:);
    x= 1:3000;
    RMSEI= interp1(xSampled, r.data(1,:), x);
    entropyI= interp1(xSampled, r.data(4,:), x);
    if PlotOn==1
        %---------------plot RMSE values w.r.t. meters
        subplot(3,2,5)
        plot(x, RMSEI)
        grid on
        ylabel('RMSE')
        xlabel('meters')
        title('RMSE error')
        
        %-------------------plot entropy values w.r.t. meters-------
        subplot(3,2,6)
        plot(x, entropyI)
        grid on
        ylabel('Entropy')
        xlabel('meters')
        title('Total entropy')
    end
    %---------------saves results on file-------------------------
    if ~exist('./results', 'dir')
        mkdir('./results');
    end
    
    FileName= strcat('./results/newSimulationResultJob_', num2str(jobID), '_', num2str(currentSimulation), '.mat');
    save( FileName, 'RMSEI', 'entropyI','jobID');
    
    
end

end
