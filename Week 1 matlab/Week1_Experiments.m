close all
clear

%[y1,Fs] = audioread('Traploop.wav');
%[y2,~] = audioread('Traploop_32sampledelay.wav');

[audio,Fs] = audioread('SynthLR34delay.wav');
y1 = audio(:,1);
y2 = audio(:,2);

length = size(y1,1);

r1 = xcorr(y2(:,1), y1(:,1));
%r2 = xcorr(y2(:,2), y1(:,2));

delaych1 = find(r1==max(r1))-length;
%delaych2 = find(r2==max(r2))-length;

finddelay(y1,y2);


%% Plugin xcorr test

buffer = 1024*4;

windows = floor(size(y1,1)/buffer);
delays = zeros(windows,1);
delays2 = zeros(windows,1);
frame = zeros(buffer, 2);

for i = 1:windows
    
    frame(:,1) = y1((i-1)*buffer+1:i*buffer,1);
    frame(:,2) = y2((i-1)*buffer+1:i*buffer,1);
    
    cc = xcorr(frame(:,2), frame(:,1));
    delays(i) = find(cc==max(cc))-buffer;
    delays2(i) = finddelay(frame(:,1),frame(:,2));
    
    
end

Ncorrect = sum(delays==-32);
Ncorrect2 = sum(delays2==-32);



