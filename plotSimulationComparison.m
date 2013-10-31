
function plotSimulationComparison(nRobots, ComparisonNumber)
close all

fileList={};

for i=1: ComparisonNumber
    fileList{i}= dir(strcat('./results', num2str(i), '/newSimulationResultJob_*.mat'));
end

shortRange=cell(ComparisonNumber,nRobots);
mediumRange=cell(ComparisonNumber,nRobots);
longRange=cell(ComparisonNumber,nRobots);
sampleFactor= 150;

%assume L.currentRMSE is a column vector
for j=1: ComparisonNumber
    for i=1:length(fileList{j})
        L=load(strcat('./results', num2str(j),'/', fileList{j}(i).name));
        L.RMSEI=  L.RMSEI(1:sampleFactor:3000);   
        
        if mod(L.jobID, 3)== 1
            longRange{j,nRobots}(:, size(longRange{j,nRobots}, 2)+1)= L.RMSEI';
        elseif mod(L.jobID, 3)== 2
            mediumRange{j,nRobots}(:, size(mediumRange{j,nRobots}, 2)+1)= L.RMSEI';
        else
            shortRange{j,nRobots}(:, size(shortRange{j,nRobots}, 2)+1)= L.RMSEI';
        end
    end
end

shortRangePlotY= cell(1,ComparisonNumber);
shortRangeSTD= cell(1,ComparisonNumber);
mediumRangePLotY= cell(1,ComparisonNumber);
mediumRangeSTD= cell(1,ComparisonNumber);
longRangePlotY= cell(1,ComparisonNumber);
longRangeSTD= cell(1,ComparisonNumber);
totalPlotY= cell(1,ComparisonNumber);
totalPlotSTD= cell(1,ComparisonNumber);
legendNames= {};

for j=1:ComparisonNumber
    for i=1:nRobots
        shortRangePlotY{j}= [shortRangePlotY{j} mean(shortRange{j,i},2)];
        shortRangeSTD{j}= [shortRangeSTD{j} std(shortRange{j,i},1,2)];
        
        mediumRangePLotY{j}= [mediumRangePLotY{j} mean(mediumRange{j,i},2)];
        mediumRangeSTD{j}= [mediumRangeSTD{j} std(mediumRange{j,i},1,2)];
        
        longRangePlotY{j}= [longRangePlotY{j} mean(longRange{j,i},2)];
        longRangeSTD{j}=[longRangeSTD{j} std(longRange{j,i},1,2)];
        
        totalPlotY{j}=[totalPlotY{j} mean([shortRangePlotY{j}(:,end) mediumRangePLotY{j}(:,end) longRangePlotY{j}(:,end)],2)];
        totalPlotSTD{j}= [totalPlotSTD{j} std([shortRangePlotY{j}(:,end) mediumRangePLotY{j}(:,end) longRangePlotY{j}(:,end)],1,2)];
    end
end

legendNames{1}= 'coarseness=5 gain=5';
legendNames{2}= 'coarseness=5 gain=1';

plotRangeX = (1:sampleFactor:3000)';
if ~exist('./plot', 'dir')
    mkdir('./plot');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(shortRangePlotY{1})~=1
    
    shortRangePlotY= cell2mat(shortRangePlotY);
    shortRangeSTD= cell2mat(shortRangeSTD);
    
    shortFigure= figure(1);
    plot(plotRangeX,shortRangePlotY)
    title('ShortRange RandomField comparison')
    ylabel('RMSE')
    xlabel('meters')
    grid on
    legend(legendNames)
    hold on
    %adding error bars for STD
    for i=1:ComparisonNumber
        tmpY= shortRangePlotY(:,i);
        tmpSTD= shortRangeSTD(:,i);
        errorbar(plotRangeX, tmpY, tmpSTD, '.k')
    end
    saveas(shortFigure,'./plot/shortRange','pdf')
    hold off
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(mediumRangePLotY{1})~=1
    mediumRangePLotY= cell2mat(mediumRangePLotY);
    mediumRangeSTD= cell2mat(mediumRangeSTD);
    mediumFigure=figure(2);
    plot(plotRangeX,mediumRangePLotY)
    title('MediumRange RandomField comparison')
    ylabel('RMSE')
    xlabel('meters')
    grid on
    legend(legendNames)
    hold on
    %adding error bars for STD
    for i=1:ComparisonNumber
        tmpY= mediumRangePLotY(:,i);
        tmpSTD= mediumRangeSTD(:,i);
        errorbar(plotRangeX, tmpY, tmpSTD, '.k')
    end
    saveas(mediumFigure,'./plot/mediumRange','pdf')
    hold off
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(longRangePlotY{1})~=1
    longRangePlotY= cell2mat(longRangePlotY);
    longRangeSTD= cell2mat(longRangeSTD);
    longFigure=figure(3);
    plot(plotRangeX,longRangePlotY)
    title('longRange RandomField comparison')
    ylabel('RMSE')
    xlabel('meters')
    grid on
    legend(legendNames)
    hold on
    %adding error bars for STD
    for i=1:ComparisonNumber
        tmpY= longRangePlotY(:,i);
        tmpSTD= longRangeSTD(:,i);
        errorbar(plotRangeX, tmpY, tmpSTD, '.k')
    end
    saveas(longFigure,'./plot/longRange','pdf')
    hold off
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
totalFigure=figure(4);
totalPlotY= cell2mat(totalPlotY);
plot(plotRangeX,totalPlotY)
title('total comparison')
ylabel('RMSE')
xlabel('meters')
grid on
legend(legendNames)
hold off

saveas(totalFigure,'./plot/total','pdf')

end
