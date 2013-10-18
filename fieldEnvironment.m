classdef fieldEstimation
    properties
        FieldWidth;
        FieldHeight;
        Coarseness= 5;
        
    end
    
    methods
        
        function obj = fieldEnvironment(field, coarseness)
            if nargin == 0
                disp('This constructor requires at least one argument!!')
            end
            
            if nargin > 1
                obj.Coarseness= coarseness;
            end
            obj.FieldHeight= size(field, 1);
            obj.FieldWidth= size(field, 2);
            
            
        end
        
    end
    
    
    methods(Access = private)
        function obj = initializeLikelihood(obj)
            
        end
        
    end
    
end



