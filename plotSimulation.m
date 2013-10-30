
function plotSimulation(nRobots)
close all
fileList=dir('./results/newSimulationResultJob_*.mat');
shortRange=cell(nRobots);
mediumRange=cell(nRobots);
longRange=cell(nRobots);

%assume L.currentRMSE is a column vector

for i=1:length(fileList)
    L=load(strcat('./results/', fileList(i).name));
    
    if mod(L.jobID, 3)== 1
        longRange{nRobots}(:, size(longRange{nRobots}, 2)+1)= L.RMSE';
    elseif mod(L.jobID, 3)== 2
        mediumRange{nRobots}(:, size(mediumRange{nRobots}, 2)+1)= L.RMSE';
    else
        shortRange{nRobots}(:, size(shortRange{nRobots}, 2)+1)= L.RMSE';
        
    end
end

shortRangePlotY=[];
shortRangeSTD= [];
mediumRangePLotY=[];
mediumRangeSTD=[];
longRangePlotY=[];
longRangeSTD=[];
totalPlotY=[];
totalPlotSTD=[];
legendNames=[];


for i=1:nRobots
    shortRangePlotY= [shortRangePlotY mean(shortRange{i},2)];
    shortRangeSTD= [shortRangeSTD std(shortRange{i},1,2)];
    
    mediumRangePLotY= [mediumRangePLotY mean(mediumRange{i},2)];
    mediumRangeSTD= [mediumRangeSTD std(mediumRange{i},1,2)];
    
    longRangePlotY= [longRangePlotY mean(longRange{i},2)];
    longRangeSTD=[longRangeSTD std(longRange{i},1,2)];
    
    totalPlotY=[totalPlotY mean([shortRangePlotY(:,end) mediumRangePLotY(:,end) longRangePlotY(:,end)],2)];
    totalPlotSTD= [totalPlotSTD std([shortRangePlotY(:,end) mediumRangePLotY(:,end) longRangePlotY(:,end)],1,2)];
    
    legendNames=[legendNames; strcat(num2str(i),' robots')];
end

plotRangeX = (1:149)';
if ~exist('./plot', 'dir')
    mkdir('./plot');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if size(shortRangePlotY,1)~=0
    shortFigure= figure();
    plot(plotRangeX,shortRangePlotY)
    title('shortRange RandomField comparison')
    ylabel('RMSE')
    xlabel('# sampling points')
    grid on
    legend(legendNames)
    hold on
    %adding error bars for STD
    for i=1:nRobots
        tmpY= shortRangePlotY(:,i);
        tmpSTD= shortRangeSTD(:,i);
        errorbar(plotRangeX, tmpY, tmpSTD, '.k')
    end
    saveas(shortFigure,'./plot/shortRange','pdf')
    hold off
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if size(mediumRangePLotY,1)~=0
    mediumFigure=figure();
    plot(plotRangeX,mediumRangePLotY)
    title('mediumRange RandomField comparison')
    ylabel('RMSE')
    xlabel('# sampling points')
    grid on
    legend(legendNames)
    hold on
    %adding error bars for STD
    for i=1:nRobots
        tmpY= mediumRangePLotY(:,i);
        tmpSTD= mediumRangeSTD(:,i);
        errorbar(plotRangeX, tmpY, tmpSTD, '.k')
    end
    saveas(mediumFigure,'./plot/mediumRange','pdf')
    hold off
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if size(longRangePlotY,1)~=0
    longFigure=figure();
    plot(plotRangeX,longRangePlotY)
    title('longRange RandomField comparison')
    ylabel('RMSE')
    xlabel('# sampling points')
    grid on
    legend(legendNames)
    hold on
    %adding error bars for STD
    for i=1:nRobots
        tmpY= longRangePlotY(:,i);
        tmpSTD= longRangeSTD(:,i);
        errorbar(plotRangeX, tmpY, tmpSTD, '.k')
    end
    saveas(longFigure,'./plot/longRange','pdf')
    hold off
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
totalFigure=figure();
plot(plotRangeX,totalPlotY)
title('total comparison')
ylabel('RMSE')
xlabel('# sampling points')
grid on
legend(legendNames)
% hold on
% %adding error bars for STD
% for i=1:nRobots
%     tmpY= totalPlotY(:,i);
%     tmpY= tmpY(1+i:10:end);
%     tmpSTD= totalPlotSTD(:,i);
%     tmpSTD= tmpSTD(1+i:10:end);
%     errorbar(plotRangeX(1+i:10:end), tmpY, tmpSTD, '.k','LineWidth',1.5)
% end
saveas(totalFigure,'./plot/total','pdf')
%hold off

end
