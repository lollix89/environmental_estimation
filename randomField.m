classdef randomField
    %Class simulating the environment. The implemented method simulates the sensor of
    %the robot sampling the environment and returning the value.
    properties
        Field=[];      
    end
    
    methods
        function obj= randomField(field)
            obj.Field= field;
        end
        
        function sample= sampleField(obj,X,Y)
            sample= obj.Field(X,Y);
        end
        
    end
end