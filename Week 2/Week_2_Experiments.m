close all
clear

C = 343; %Speed of sound m/s

[y1,Fs] = audioread('DrumDistant.wav'); %Loading in recordings
[y2,~] = audioread('DrumSpot.wav');

Distant = y1(:,1); %Converting Stereo signals to mono
Spot = y2(:,1);

Nsamples = size(Spot,1); %Sample Length of recordings
duration = Nsamples/Fs; %Recordings length in seconds



%%                                  Cross correlation of Entire Signals

r1 = xcorr(Spot, Distant); %Cross correlation
delay1 = find(r1==max(r1))-Nsamples;

figure(1)
hold on

plot(-1024:1024, r1(Nsamples-1024:Nsamples+1024)); %Plotting the cross correlation between the two signals 
axis([-1024 1024 -4 5])
grid on;
yline(0, 'r--', 'LineWidth', 1); 
title('Cross correlation between Spot and Distant mic signals');
xlabel('Sample Shift (bounded by +/-1024 sample shift)');
ylabel('Cross Correlation')

textLabel = sprintf('Max at Shift = %0.0f', delay1);
text(delay1+10, r1(delay1+Nsamples), textLabel);
plot(delay1,r1(delay1+Nsamples),'.','MarkerSize',10)

textLabel = sprintf('Correlation at shift = 0');
text(10, r1(Nsamples), textLabel);
plot(0,r1(Nsamples),'.','MarkerSize',10)
line([-1024,0],[r1(Nsamples),r1(Nsamples)],'color', 'green', 'linestyle', '--', 'LineWidth', 1);


delay2 = finddelay(Distant,Spot);

distance = abs(delay1)*C/Fs;% d = |samples|*C/fs


fprintf('\nCalculated delay between mic signals using cross correlation on entire signals = %0.0f samples\n\n', delay1);
fprintf('Calculated distance between mics = %fm\n\n', distance);



%%                             Windowing effect on cross correlation accuracy

frameSize = 1024; %Window size in samples
Nwindows = floor(Nsamples/frameSize); %Number of windows

SpotWin = zeros(frameSize, Nwindows);
DistantWin = zeros(frameSize, Nwindows);

rWin = zeros(frameSize*2-1,Nwindows);
delaysWin1 = zeros(Nwindows,1);
sigPower = zeros(Nwindows,1);

for i=1:Nwindows
    
    SpotWin(:,i) = Spot((i-1)*frameSize+1:i*frameSize); %Windowing Signals
    DistantWin(:,i) = Distant((i-1)*frameSize+1:i*frameSize);
    
    rWin(:,i) = xcorr(SpotWin(:,i),DistantWin(:,i)); %Cross correlation of windowed signals
    delaysWin1(i) = find(rWin(:,i)==max(rWin(:,i)),1)-frameSize; %Indice of cross corr max for each window
    
    sigPower(i) = rms(SpotWin(:,i))^2; %Average power of spot mic signal for each window (Pav = (Vrms)^2)
end

Ncorrect = sum(delaysWin1==delay1); 
accuracy = Ncorrect/Nwindows;

fprintf('Accuracy of cross correlation with windowing = %f (Window size = %0.0f)\n\n', accuracy, frameSize);

NnearCorrect = sum(delaysWin1==delay1|delaysWin1==delay1-1|delaysWin1==delay1+1);
nearAccuracy =NnearCorrect/Nwindows;

fprintf('Accuracy within +/- 1 sample of true delay = %f (Window size = %0.0f)\n\n', nearAccuracy, frameSize);


%%                                      Signal Power in Windows

threshold = 1*10^-5; 

figure(2)
plot(1:Nwindows, sigPower);
grid on;
title('Average Signal Power of Spot Mic Signal for each Window');
ylabel('Power in Watts');
xlabel('Windows');
yline(threshold, 'r--', 'LineWidth', 1);
textLabel = sprintf('Threshold');
text(0, threshold+1*10^-4, textLabel);

aboveThres = delaysWin1(sigPower > threshold); %Extracting values from delayWin1 of windows whos signal power are greater than threshold

NcorrectThres = sum(aboveThres==delay1); 
accuracyThres = NcorrectThres/size(aboveThres,1);

fprintf('Accuracy of windows with average power greater than %fW = %f (Window size = %0.0f)\n\n',threshold, accuracyThres, frameSize);


%%                                  Circular buffer Experiments

bufferLength = frameSize*30; %Sample length of Circular buffer
SpotBuff = zeros(bufferLength,1);
DistantBuff = zeros(bufferLength,1);

delaysBuff = zeros(Nwindows, 1);

writeIndex = 1;

for i=1:Nwindows
    
    SpotBuff(writeIndex:writeIndex+frameSize-1) = Spot((i-1)*frameSize+1:i*frameSize); %Writing to buffers
    DistantBuff(writeIndex:writeIndex+frameSize-1) = Distant((i-1)*frameSize+1:i*frameSize);
    
    rBuff = xcorr(SpotBuff, DistantBuff); %Crosscorr of buffers
    delaysBuff(i) = find(rBuff==max(rBuff),1)-bufferLength; %extracting indices of max value
    
    writeIndex = writeIndex + frameSize; %Incrementing write index
    
    if writeIndex > bufferLength
        writeIndex = 1;
    end
end

NcorrectBuff = sum(delaysBuff==delay1); 
accuracyBuff = NcorrectBuff/Nwindows;

fprintf('Accuracy using circular buffer of size %0.0f = %f\n\n', bufferLength, accuracyBuff);

