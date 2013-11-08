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
        RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));
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
    fid = fopen('./test.txt','w');%open output file

    %--------------------initialize field-------------------------
    rF= randomField(field,range);
    
    %--------------------initialize object robot--------------------
    r = robot(rF, stations);
    %-----------------plot selected field---------------------
    if PlotOn==1
        figure(1)
        subplot(1,3,1)
        [~, ch]=contourf(1:200,1:200,field,30);
        set(ch,'edgecolor','none');
        set(gca,'FontSize',16)
        hold on;
        for i=1:size(stations,1)
            plot(stations(i,2),stations(i,1), 'ko')
        end
        axis('equal')
        axis([-2 202 -2 202])
        hold on;
        drawnow

    end
    
    %-----------------simulation step----------------------
    while r.iteration< 150
        r= r.flyNextWayPoints();
    end
    
    %---------------saves results on file-------------------------
    if ~exist('./results', 'dir')
        mkdir('./results');
    end
    RMSE= r.data(1,:);
    
    FileName= strcat('./results/newSimulationResultJob_', num2str(jobID), '_', num2str(currentSimulation), '.mat');
    save( FileName, 'RMSE', 'entropy','jobID');
    
    for i=1:length(RMSE)
        fprintf(fid,'%f ',RMSE(i));
    end
    fprintf(fid,'\n');
    fclose(fid);
    
end

end
