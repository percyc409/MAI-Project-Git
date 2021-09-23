
classdef DelayAligner < audioPlugin
    
    properties (Access = protected)
        Meter
    end
    
    methods
        function out = process(plugin, in)
            
            out = zeros(size(in));
            
            %r = xcorr(in(:,2), in(:,1));
            %delay = find(r==max(r))-size(in,1);
            delay = finddelay(in(:,1),in(:,2));
            
            if isempty(coder.target)
                % Update delay meter visualization
                if ~isempty(plugin.Meter)
                    delayDisplay  = sprintf('%0.1f',delay);
                    
                    update(plugin.Meter,delayDisplay);
                end
            end 
            
            out(:,1) = in(:,1)+in(:,2);
            out(:,2) = in(:,1)+in(:,2);
        end
        
        function reset(plugin)
            if isempty(coder.target) && ~isempty(plugin.Meter) && isFigureValid(plugin.Meter)
            	reset(plugin.Meter)
            end
        end
        
        function visualize(plugin)
            % VISUALIZE Visualize BPM decision
            %
            % VISUALIZE(bD) opens a meter that displays the current BPM
            %   estimate and the current analyzed time.
            
            if ~isempty(plugin.Meter) && isvalid(plugin.Meter) && isFigureValid(plugin.Meter)
                show(plugin.Meter);
            else
                plugin.Meter = audiopluginexample.private.MeterUI('Delay Aligner','Sample Delay');
            end
        end
        
    end
    
end