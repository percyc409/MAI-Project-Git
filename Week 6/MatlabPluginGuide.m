%Made by following the tutorial in https://uk.mathworks.com/help/audio/gs/audio-plugins-in-matlab.html

classdef MatlabPluginGuide < audioPlugin
    
    properties
        gain = 1.5;
        delay = 0.5;
    end
    
    properties (Access = private)
        CircularBuffer = zeros(192001,2);
        BufferIndex = 1;
        NSamples = 0;
    end
    
    properties (Constant)
       PluginInterface = audioPluginInterface(...
       audioPluginParameter('gain', 'DisplayName','Echo Gain', 'Mapping', {'lin',0,3}),...
       audioPluginParameter('delay', 'DisplayName', 'Echo Delay', 'Label', 'seconds')...
       )
    end
    
    methods
        function out = process(plugin,in)
            out = zeros(size(in));
            writeIndex = plugin.BufferIndex;
            readIndex = writeIndex - plugin.NSamples;
            
            if(readIndex <= 0)
                readIndex = readIndex + 192001;
            end
            
            for i=1:size(in,1)
                plugin.CircularBuffer(writeIndex,:) = in(i, :);
                
                echo = plugin.CircularBuffer(readIndex,:);
                out(i,:) = in(i,:) + echo*plugin.gain;
                
                writeIndex = writeIndex + 1;
                if(writeIndex > 192001)
                    writeIndex = 1;
                end
                readIndex = readIndex + 1;
                if(readIndex > 192001)
                    readIndex = 1;
                end
                
            end
            plugin.BufferIndex = writeIndex;
        end
        function set.delay(plugin, val)
            plugin.delay = val;
            plugin.NSamples = floor(getSampleRate(plugin)*val);
        end
        function reset(plugin)                                          
            plugin.CircularBuffer = zeros(192001,2);                    
            plugin.NSamples = floor(getSampleRate(plugin)*plugin.delay);
        end 
    end    
end