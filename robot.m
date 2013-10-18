classdef robot
    properties
        mutualInformationMap;
        path=[]
        fieldPrior=[];
        fieldPosterior=[];
        likelihood = [];
        temperatureVector= [];
        likelihoodDistribution= 'norm';
        likelihoodVariance= 1;
        temperatureRange=[0,50];
        temperatureInterval= .5;
        wayPointCoarseness = 10;
        samplePointCoarseness = 5;      %not used for now
        fieldExtent;
        robotPosition;
        entropyMap=[];
        iteration= 0;
        %For simulating the environment the object Field returns the values
        %of the field
        RField;
        
    end
    
    methods
        %rField simulates the environment
        %fieldExtent is #rows and #cols of the field
        %lVariance is the variance of P(y|x)
        %tRange is the minimum and maxium of temperature
        %tInterval is the coarseness of values
        %lDistribution is the distribution probability of P(y|x)
        
        function obj = robot(rField, fieldExtent, lVariance, tRange, tInterval, lDistribution)
            nargin
            if nargin == 1
                disp('This constructor requires at least two argument!!')
            elseif nargin > 1
                obj.RField= rField;
                obj.fieldExtent= fieldExtent ;
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
            %temporary, this value will be passed in a multi rotor environment
            obj.robotPosition = randi([1,obj.fieldExtent(1)],1,2);
            obj.path= [obj.path obj.robotPosition'];
            %
            obj.temperatureVector= (obj.temperatureRange(1):obj.temperatureInterval:obj.temperatureRange(2));
            
            obj= initializeLikelihood(obj);
            obj= initializePriorDistribution(obj);
            %initialize mutualInformationMap
            obj.mutualInformationMap= 30.*ones(ceil(obj.fieldExtent(1)/5),ceil(obj.fieldExtent(2)/5));
            %initialize entropy map
            obj.entropyMap= updateEntropyMap(obj);
            
        end
        %plot likelihood
        function obj = plotLikelihood(obj)
            surf(obj.likelihood)
        end
        
        %flies around the environment
        function obj = flyNextWayPoints(obj)
            %plot current entropy
            totalEntropy= sum(obj.entropyMap(:));
            obj.iteration= obj.iteration+ 1;
            subplot(3,2,2)
            title('Entropy plot')
            ylabel('Entropy')
            xlabel('# of iterations')
            plot(obj.iteration, totalEntropy, 'r-')
            hold on;
            
            %sample field at current position
            fieldValue= obj.RField.sampleField(obj.robotPosition(1),obj.robotPosition(2));
            %compute posterior  and update prior for the entire environment
            obj= updatePosteriorMap(obj, fieldValue);
            %update entropy map
            obj.entropyMap= updateEntropyMap(obj);
                
            %find best direction to move to
            bestDirection= findBestDirection(obj);      %For the moment it is greedy
            %move the robot to the center of the best cell found so far
            obj.robotPosition=[(bestDirection(1)*5)-2 (bestDirection(2)*5)-2];
            obj.path= [obj.path obj.robotPosition'];
            
            %plot the path followed on the map
            subplot(3,2,3)
            title('Robot path on the field')
            plot(obj.robotPosition(1,2),obj.robotPosition(1,1), 'w*')
            hold on;
            drawnow
            subplot(3,2,1)
            surf(obj.mutualInformationMap)
            title('Mutual information map')
            drawnow
            %
            pause
        end
        
        
    end
    
    
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
            
            %The grid is divided into 5m spaced CELLS and every cell is given a
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
            obj.fieldExtent
            for i=1:(obj.fieldExtent(1)/5)
                for j=1:(obj.fieldExtent(2)/5)
                    obj.fieldPrior(i,j,:)= ones(1,1, size(obj.temperatureVector, 2))./size(obj.temperatureVector, 2);
                    %S= sum(obj.fieldPrior(i,j,:),3)
                end
            end
            obj.fieldPosterior= obj.fieldPrior;
        end
        
        
    end
    
end

