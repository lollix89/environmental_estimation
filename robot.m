classdef robot
    properties
        mutualInformationMap;
        path=[]
        samplingPoints=[];
        stations=[];
        fieldPrior=[];
        fieldPosterior=[];
        likelihood = [];
        temperatureVector= [];
        likelihoodDistribution= 'norm';
        likelihoodVariance= .5;
        temperatureRange=[-12,58];
        temperatureInterval= .1;
        fieldExtent;
        robotPosition=[];
        entropyMap=[];
        iteration= 1;
        gain= 5;
        gridCoarseness= 5;
        GPSCoarseness= 5;
        %For simulating the environment the object Field returns the values
        %of the field
        RField;
        data=[];
        distance= 0;
    end
    
    methods
        %rField simulates the environment
        %fieldExtent is #rows and #cols of the field
        %lVariance is the variance of P(y|x)
        %tRange is the minimum and maxium of temperature
        %tInterval is the coarseness of values
        %lDistribution is the distribution probability of P(y|x)
        
        function obj = robot(rField, staticStations, lVariance, tRange, tInterval, lDistribution)
            if nargin == 0
                disp('This constructor requires at least one argument!!')
            elseif nargin > 0
                obj.RField= rField;
                obj.fieldExtent= size(obj.RField.Field);
                if nargin > 1
                    obj.stations= staticStations;
                    if nargin > 2
                        obj.likelihoodVariance = lVariance;
                        if nargin > 3
                            obj.temperatureRange   = tRange;
                            if nargin > 4
                                obj.temperatureInterval    = tInterval;
                                if nargin > 5
                                    obj.likelihoodDistribution  = lDistribution;
                                end
                            end
                        end
                    end
                end
            end
            %--------------assign a a random position in the grid-------------
            availablePositionMatrix= ones(obj.fieldExtent);
            occupiedPositions= [];
            if ~isempty(obj.stations)
                occupiedPositions = sub2ind(size(availablePositionMatrix), obj.stations(:,1), obj.stations(:,2));
            end
            availablePositionMatrix(occupiedPositions)= 0;
            availablePositionIndexes= find(availablePositionMatrix== 1);
            randIdx= randi([1,size(availablePositionIndexes,1)]);
            availablePositionIndexes(randIdx,1);
            [obj.robotPosition(1), obj.robotPosition(2)]= ind2sub(size(availablePositionMatrix), availablePositionIndexes(randIdx,1));
            obj.path= [obj.path obj.robotPosition'];
            %---------------create temperatureVector------------------
            obj.temperatureVector= (obj.temperatureRange(1):obj.temperatureInterval:obj.temperatureRange(2));
            %-------------initialize probabilities distributions----------
            obj= initializePriorDistribution(obj);
            %----------------initialize mutualInformationMap---------------
            obj.mutualInformationMap= 30.*ones(ceil(obj.fieldExtent(1)/obj.gridCoarseness),ceil(obj.fieldExtent(2)/obj.gridCoarseness));
            %------------sample field at current position and at eventually present stations-------------
            obj.stations(end+1,:)= obj.robotPosition;
            for idx=1:size(obj.stations,1)
                fieldValue= obj.RField.sampleField(obj.stations(idx,1),obj.stations(idx,2), obj.gridCoarseness);
                %compute posterior update prior for the environment and update
                %mutual information map
                obj= updatePosteriorMap(obj, fieldValue, obj.stations(idx,1),obj.stations(idx,2));
            end
            obj.entropyMap= updateEntropyMap(obj);   
            obj.stations= obj.stations(1:end-1,:);
            obj.samplingPoints= [obj.robotPosition(1); obj.robotPosition(2)];
        end
        
        %------------flies around the environment-----------------
        function obj = flyNextWayPoints(obj)
            global PlotOn;
            totalEntropy= sum(obj.entropyMap(:));
            %---------------------saving RMSE for comparison-----------------
            temperatureMap= sampleTemperatureProbability(obj, 0);
            obj.data(:, end+1) = [sqrt(mean(mean((temperatureMap(1:obj.gridCoarseness:end, 1:obj.gridCoarseness:end)-...
                obj.RField.Field(1:obj.gridCoarseness:end,1:obj.gridCoarseness:end)).^2))); obj.iteration; obj.distance; totalEntropy];
            %-----------plot current entropy--------------------
            if PlotOn== 1
                subplot(3,2,2)
                title('Entropy plot')
                ylabel('Entropy')
                xlabel('# of iterations')
                plot(obj.iteration, totalEntropy, 'r-')
                hold on;
            end
            bestDirection= findBestDirection(obj);
            %----------gain controls how many cells the robot moves in that
            %direction
            %before recomputing the best trajectory----------------
            i= 0;
            boundary= 0;
            attempt= 1;
            while i< obj.gain && boundary== 0
                bestWaypointX= ceil(obj.robotPosition(1)/obj.GPSCoarseness) + bestDirection(1,attempt);
                bestWaypointY= ceil(obj.robotPosition(2)/obj.GPSCoarseness) + bestDirection(2,attempt);
                
                if bestWaypointX >0 && bestWaypointX <= obj.fieldExtent(1)/obj.GPSCoarseness && bestWaypointY >0 && bestWaypointY <= obj.fieldExtent(2)/obj.GPSCoarseness ...
                        && ~(any(ismember(ceil(obj.stations./obj.GPSCoarseness), [bestWaypointX bestWaypointY] , 'rows')))
                    
                    %-------once i m here i know all the moves are legal----
                    for samplePoint= 1: obj.GPSCoarseness/obj.gridCoarseness
                        %--------sampling points on the way to the next waypoint ----
                        bestCellX= ceil(obj.samplingPoints(1,end)/obj.gridCoarseness) + bestDirection(1,attempt);
                        bestCellY= ceil(obj.samplingPoints(2,end)/obj.gridCoarseness) + bestDirection(2,attempt);
                        
                        obj.samplingPoints= [obj.samplingPoints [(bestCellX*obj.gridCoarseness)-floor(obj.gridCoarseness/2) (bestCellY*obj.gridCoarseness)-floor(obj.gridCoarseness/2)]'];
                        obj.distance= obj.distance + pdist([obj.samplingPoints(:, end-1)'; obj.samplingPoints(:,end)']);
                        
                        %------------plot the sampling points on the map---------
%                        currentSamplingPoint= obj.samplingPoints(:, end);
%                         if PlotOn==1
%                             subplot(3,2,3)
%                             title('Robot path on the field')
%                             plot(currentSamplingPoint(2,1),currentSamplingPoint(1,1), 'k+')
%                             hold on;
%                             drawnow
%                         end
                        fieldValue= obj.RField.sampleField(obj.samplingPoints(1,end),obj.samplingPoints(2,end), obj.gridCoarseness);
                        %-------compute posterior update prior for the environment and update mutual information map-------------
                        obj= updatePosteriorMap(obj, fieldValue, obj.samplingPoints(1,end), obj.samplingPoints(2,end));
                    end
                    
                    previousPosition= obj.robotPosition;
                    obj.robotPosition=[(bestWaypointX*obj.GPSCoarseness)-floor(obj.GPSCoarseness/2) (bestWaypointY*obj.GPSCoarseness)-floor(obj.GPSCoarseness/2)];
                    obj.path= [obj.path obj.robotPosition'];
                    
                    %------------plot the path followed on the map---------
                    if PlotOn==1
                        subplot(3,2,3)
                        title('Robot path on the field')
                        plot(previousPosition(1,2),previousPosition(1,1), 'w*')
                        plot(obj.robotPosition(1,2),obj.robotPosition(1,1), 'r*')
                        hold on;
                        drawnow
                    end
                    
                else
                    %if looking for allowed direction try in decreasing
                    %order all the direection, if already moved, exit and
                    %recompute gradient
                    if i==0
                        attempt= attempt+1;
                        %decreasing i and iteration since are increased
                        %once out of the loop
                        i=i-1;
                        obj.iteration= obj.iteration-1;
                        disp(strcat('!!!!!!!Attempting next direction: ', num2str(attempt)))
                    else
                        %disp('boundary found... exiting')
                        boundary= 1;
                    end
                end
                i=i+1;
                obj.iteration= obj.iteration+ 1;
            end
            %------------update entropy map------------
            obj.entropyMap= updateEntropyMap(obj);
            
            if PlotOn==1
                subplot(3,2,1)
                imagesc(obj.mutualInformationMap)
                hold on;
                for j=1:size(obj.stations,1)
                    plot(ceil(obj.stations(j,2)/obj.gridCoarseness),ceil(obj.stations(j,1)/obj.gridCoarseness), 'ko')
                end
                title('Mutual information map')
                drawnow
            end
            %pause
        end
        
        %Simulates the communication between two robots and
        %updates belief. oss: assumes perfect communication
        function obj= communicate(obj, otherBelieves, totalRobots)
            weightFactor= 1/totalRobots;
            tmpSum= zeros(size(obj.fieldPrior));
            for neighb= 1:size(otherBelieves,2)
                tmpSum= tmpSum + (otherBelieves{neighb} - obj.fieldPrior);
            end
            obj.fieldPrior= obj.fieldPrior + (weightFactor*tmpSum);
        end
        
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)       
        %initialize prior for every cell of the environment
        function obj = initializePriorDistribution(obj)
            
            %The grid is divided into gridcoarseness (m) spaced CELLS and every cell is given a
            %uniform probability distribution (uniformative prior). Waypoint
            %distance is formed by a grid of 10 m spaced points
            
            %           (+*)-+-(*+)-+-(*+)              * waypoints
            %             |  |   |  |  |                + probability point
            %             +--+---+--+--+
            %             |  |   |  |  |
            %           (+*)-+-(*+)-+-(*+)
            %             |  |   |  |  |
            %             +--+---+--+--+
            %             |  |   |  |  |
            %           (+*)-+-(*+)-+-(*+)
            for i=1:(obj.fieldExtent(1)/obj.gridCoarseness)
                for j=1:(obj.fieldExtent(2)/obj.gridCoarseness)
                    obj.fieldPrior(i,j,:)= ones(1,1, size(obj.temperatureVector, 2))./size(obj.temperatureVector, 2);
                end
            end
            obj.fieldPosterior= obj.fieldPrior;
        end
        
        
    end
    
end

