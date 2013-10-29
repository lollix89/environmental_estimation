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
        likelihoodVariance= .1;
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
        %rField simulates the environment
        %fieldExtent is #rows and #cols of the field
        %lVariance is the variance of P(y|x)
        %tRange is the minimum and maxium of temperature
        %tInterval is the coarseness of values
        %lDistribution is the distribution probability of P(y|x)
        
        function obj = robot(rField, staticStations, lVariance, tRange, tInterval, lDistribution)
            nargin
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
            obj= initializeLikelihood(obj);
            obj= initializePriorDistribution(obj);
            %----------------initialize mutualInformationMap---------------
            obj.mutualInformationMap= 30.*ones(ceil(obj.fieldExtent(1)/obj.gridCoarseness),ceil(obj.fieldExtent(2)/obj.gridCoarseness));
            %---------------initialize entropy map-------------------------
            obj.entropyMap= updateEntropyMap(obj);
            %------------sample field at current position and at eventually present stations-------------
            obj.stations(end+1,:)= obj.robotPosition;
            for idx=1:size(obj.stations,1)
                fieldValue= obj.RField.sampleField(obj.stations(idx,1),obj.stations(idx,2), obj.gridCoarseness);
                %compute posterior update prior for the environment and update
                %mutual information map
                obj= updatePosteriorMap(obj, fieldValue, obj.stations(idx,1),obj.stations(idx,2));
                obj.entropyMap= updateEntropyMap(obj);
            end
            obj.stations= obj.stations(1:end-1,:);
            obj.samplingPoints= [obj.robotPosition(1); obj.robotPosition(2)];
        end
        
        %------------flies around the environment-----------------
        function obj = flyNextWayPoints(obj)
            global PlotOn;
            totalEntropy= sum(obj.entropyMap(:));
            %---------------------saving RMSE for comparison-----------------
            temperatureMap= sampleTemperatureProbability(obj, 0);
            obj.data(:, end+1) = [sqrt(mean(mean((temperatureMap(1:obj.gridCoarseness:ceil(obj.fieldExtent(1)/obj.gridCoarseness), 1:obj.gridCoarseness:ceil(obj.fieldExtent(2)/obj.gridCoarseness))-...
                obj.RField.Field(1:obj.gridCoarseness:ceil(obj.fieldExtent(1)/obj.gridCoarseness),1:obj.gridCoarseness:ceil(obj.fieldExtent(2)/obj.gridCoarseness))).^2))); ...
                obj.iteration; obj.distance; totalEntropy];
            %-----------plot current entropy--------------------
            if PlotOn== 1
                subplot(3,2,2)
                title('Entropy plot')
                ylabel('Entropy')
                xlabel('# of iterations')
                plot(obj.iteration, totalEntropy, 'r-')
                hold on;
            end
            
            [bestPositionX bestPositionY]= findBestPosition(obj);
            disp('**************debug************')
            disp(strcat('Iteration # ', num2str(obj.iteration)))
            disp(strcat('Next best position is: ', num2str([bestPositionX bestPositionY])))
            
            if ~(any(ismember(ceil(obj.stations./obj.gridCoarseness), [bestPositionX bestPositionY] , 'rows')))
                
                bestPositionX= (bestPositionX*obj.gridCoarseness)-floor(obj.gridCoarseness/2);
                bestPositionY= (bestPositionY*obj.gridCoarseness)-floor(obj.gridCoarseness/2);
                
                fieldValue= obj.RField.sampleField(bestPositionX, bestPositionY, obj.gridCoarseness);
                %-------compute posterior update prior for the environment and update mutual information map-------------
                obj= updatePosteriorMap(obj, fieldValue, bestPositionX, bestPositionY);
                
                previousPosition= obj.robotPosition;
                obj.robotPosition=[bestPositionX bestPositionY];
                disp(strcat('current robot position is:', num2str(obj.robotPosition)))
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
                disp('Weird because the maximum is on a station, no failsafe here!!!')
            end
            obj.iteration= obj.iteration+ 1;
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
        
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        %initialize likelihood matrix (oss: observations y are on rows, real values x are on columns)
        function obj = initializeLikelihood(obj)
            for j=1:size(obj.temperatureVector,2)
                y= pdf(obj.likelihoodDistribution, obj.temperatureVector, obj.temperatureVector(j), obj.likelihoodVariance);
                obj.likelihood(j,:)= y./sum(y);
            end
        end
        
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

