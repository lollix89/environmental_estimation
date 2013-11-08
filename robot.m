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
        gridCoarseness= 5;
        GPSCoarseness= 5;
        velocity= 2.5;
        sampleFr= 1; %1 sample every second
        %For simulating the environment the object Field returns the values
        %of the field
        RField;
        data=[];
        distance= 0;
    end
    
    methods

        
        function obj = robot(rField, staticStations)
            if nargin > 0
                obj.RField= rField;
                obj.fieldExtent= size(obj.RField.Field);
                if nargin > 1
                    obj.stations= staticStations;
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
                fieldValue= obj.RField.sampleField(obj.stations(idx,1),obj.stations(idx,2));
                %compute posterior update prior for the environment and update
                %mutual information map
                obj= computePosteriorAndMutualInfo(obj, fieldValue, obj.stations(idx,1),obj.stations(idx,2));
            end
            obj.entropyMap= updateEntropyMap(obj);
            obj.stations= obj.stations(1:end-1,:);
            obj.samplingPoints= [obj.robotPosition(1); obj.robotPosition(2)];
        end
                
        
        %------------flies to next waypoint-----------------
        function obj = flyNextWayPoint(obj)
            global PlotOn;
            %---------------------saving RMSE for comparison-----------------
            temperatureMap= sampleTemperatureProbability(obj);
            if PlotOn==1
                subplot(1,3,2)
                [~, ch]=contourf(1:5:200,1:5:200,temperatureMap,30);
                set(ch,'edgecolor','none');
                set(gca,'FontSize',16)
                axis('equal')
                axis([-2 202 -2 202])
                drawnow    
            end
            obj.data(:, end+1) = [sqrt(mean(mean((temperatureMap- obj.RField.Field(1:obj.gridCoarseness:end,1:obj.gridCoarseness:end)).^2))); obj.iteration; obj.distance];
            %-----------find best direction according to mutual information
            %map gradient
            bestDirection= findBestDirection(obj);
            attempt= 1;
            moved= 0;
            while moved== 0       
                %----------velocity controls how many times the robot can sample on the way to the next wayPoint---------------
                bestWaypointX= ceil(obj.robotPosition(1)/obj.GPSCoarseness) + bestDirection(1,attempt);
                bestWaypointY= ceil(obj.robotPosition(2)/obj.GPSCoarseness) + bestDirection(2,attempt);
                
                if bestWaypointX >0 && bestWaypointX <= obj.fieldExtent(1)/obj.GPSCoarseness && bestWaypointY >0 && bestWaypointY <= obj.fieldExtent(2)/obj.GPSCoarseness ...
                        && ~(any(ismember(ceil(obj.stations./obj.GPSCoarseness), [bestWaypointX bestWaypointY] , 'rows')))
                    
                    %-------now i know all the moves are legal----
                    
                    wayPointDistance= pdist([obj.robotPosition(1) obj.robotPosition(2); (bestWaypointX*obj.GPSCoarseness)-floor(obj.GPSCoarseness/2) (bestWaypointY*obj.GPSCoarseness)-floor(obj.GPSCoarseness/2)]);
                    distOneSample= obj.sampleFr* obj.velocity;
                    startDist = obj.distance;
                    
                    %-------check for some gap distance remained the
                    %previous iteration
                    gapDistance= 0;
                    if obj.robotPosition(1)- obj.samplingPoints(1,end) ~= 0 || obj.robotPosition(2)- obj.samplingPoints(2,end) ~= 0
                        gapDistance= pdist([obj.robotPosition(1) obj.robotPosition(2); obj.samplingPoints(1,end) obj.samplingPoints(2,end)]);
                    end
                    startPointX= obj.robotPosition(1);
                    startPointY= obj.robotPosition(2);
                    dirX= (bestWaypointX*obj.GPSCoarseness)-floor(obj.GPSCoarseness/2) - obj.robotPosition(1);
                    dirY= (bestWaypointY*obj.GPSCoarseness)-floor(obj.GPSCoarseness/2) - obj.robotPosition(2);
                    while  obj.distance- startDist <=  wayPointDistance && wayPointDistance -(obj.distance -startDist) >= obj.sampleFr* obj.velocity

                        distNextSample= distOneSample- gapDistance;
                        gapDistance= 0;
                        %--------sample points on the way to the next waypoint ----
                        if dirX ~= 0
                            distanceX= ceil(distNextSample* cos(atan(abs(dirY)/abs(dirX))));
                            distanceY= ceil(distNextSample* sin(atan(abs(dirY)/abs(dirX))));
                        else
                            distanceX= 0;
                            distanceY= ceil(distNextSample);
                        end
                        sampleX= startPointX + bestDirection(1,attempt)* distanceX;
                        sampleY= startPointY + bestDirection(2,attempt)* distanceY;

                        obj.samplingPoints= [obj.samplingPoints [sampleX sampleY]'];
                        startPointX= obj.samplingPoints(1,end);
                        startPointY= obj.samplingPoints(2,end);
                        obj.distance= obj.distance + distNextSample;
                        
                        fieldValue= obj.RField.sampleField(sampleX, sampleY);
                        %-------compute posterior update prior for the environment and update mutual information map-------------
                        obj= computePosteriorAndMutualInfo(obj, fieldValue, sampleX, sampleY);
                    end
                    
                    previousPosition= obj.robotPosition;
                    obj.robotPosition=[(bestWaypointX*obj.GPSCoarseness)-floor(obj.GPSCoarseness/2) (bestWaypointY*obj.GPSCoarseness)-floor(obj.GPSCoarseness/2)];
                    obj.path= [obj.path obj.robotPosition'];
                    
                    %------------plot the path followed on the map---------
                    if PlotOn==1
                        subplot(1,3,1)
                        title('Robot path on the field')
                        plot(previousPosition(1,2),previousPosition(1,1), 'w*')
                        plot(obj.robotPosition(1,2),obj.robotPosition(1,1), 'r*')
                        hold on;
                        drawnow
                    end
                    moved= 1;
                else
                    %if looking for allowed direction try in incresing
                    %order all the direection, if already moved, exit and
                    %recompute gradient 
                    attempt= attempt+1;
                    disp(strcat('!!!!!!!Attempting next direction: ', num2str(attempt)))
                end
            end
            obj.iteration= obj.iteration+ 1;
            %------------update entropy map------------
            obj.entropyMap= updateEntropyMap(obj);
            
            if PlotOn==1
                subplot(1,3,3)
                [~, ch]=contourf(1:5:200,1:5:200,obj.mutualInformationMap,30);
                set(ch,'edgecolor','none');
                set(gca,'FontSize',16)
                axis('equal')
                axis([-2 202 -2 202])
                drawnow

            end
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

