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
        temperatureInterval= .5;
        fieldExtent;
        robotPosition=[];
        entropyMap=[];
        iteration= 1;
        gridCoarseness= 5;
        GPSCoarseness= 5;
        %For simulating the environment the object Field returns the values
        %of the field
        RField;
        data=[];
        distance= 0;
    end
    
    methods        
         function obj = robot(rField, staticStations)
            if nargin == 0
                disp('This constructor requires at least one argument!!')
            elseif nargin > 0
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
                fieldValue= obj.RField.sampleField(obj.stations(idx,1),obj.stations(idx,2), obj.gridCoarseness);
                %compute posterior update prior for the environment and update
                %mutual information map
                obj= computePosteriorAndMutualInfo(obj, fieldValue, obj.stations(idx,1),obj.stations(idx,2));
            end
            obj.entropyMap= updateEntropyMap(obj);   
            obj.stations= obj.stations(1:end-1,:);
            obj.samplingPoints= [obj.robotPosition(1); obj.robotPosition(2)];
        end
        
        %------------flies around the environment-----------------
        function obj = flyNextWayPoints(obj)
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
            
            obj.data(:, end+1) = [sqrt(mean(mean((temperatureMap(1:obj.gridCoarseness:ceil(obj.fieldExtent(1)/obj.gridCoarseness), 1:obj.gridCoarseness:ceil(obj.fieldExtent(2)/obj.gridCoarseness))-...
                obj.RField.Field(1:obj.gridCoarseness:ceil(obj.fieldExtent(1)/obj.gridCoarseness),1:obj.gridCoarseness:ceil(obj.fieldExtent(2)/obj.gridCoarseness))).^2))); ...
                obj.iteration; obj.distance];
            
            bestPositionX = randi([1 obj.fieldExtent(1)/obj.gridCoarseness], 1, 1);
            bestPositionY= randi([1 obj.fieldExtent(2)/obj.gridCoarseness], 1, 1);
            
            if ~(any(ismember(ceil(obj.stations./obj.gridCoarseness), [bestPositionX bestPositionY] , 'rows')))
                
                bestPositionX= (bestPositionX*obj.gridCoarseness)-floor(obj.gridCoarseness/2);
                bestPositionY= (bestPositionY*obj.gridCoarseness)-floor(obj.gridCoarseness/2);
                
                fieldValue= obj.RField.sampleField(bestPositionX, bestPositionY, obj.gridCoarseness);
                %-------compute posterior update prior for the environment and update mutual information map-------------
                obj= computePosteriorAndMutualInfo(obj, fieldValue, bestPositionX, bestPositionY);
                
                previousPosition= obj.robotPosition;
                obj.robotPosition=[bestPositionX bestPositionY];
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
        
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        
        %initialize prior for every cell of the environment
        function obj = initializePriorDistribution(obj)
            for i=1:(obj.fieldExtent(1)/obj.gridCoarseness)
                for j=1:(obj.fieldExtent(2)/obj.gridCoarseness)
                    obj.fieldPrior(i,j,:)= ones(1,1, size(obj.temperatureVector, 2))./size(obj.temperatureVector, 2);
                end
            end
            obj.fieldPosterior= obj.fieldPrior;
        end
        
        
    end
    
end

