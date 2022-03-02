close all
clear

C = 343; %Speed of sound m/s

[y1,Fs] = audioread('DrumDistant.wav'); %Loading in recordings
[y2,~] = audioread('DrumSpot.wav');

Distant = y1(1:4096,1); %Converting Stereo signals to mono and cropping to buffer size
Spot = y2(1:4096,1);

Nsamples = size(Spot,1); %Sample Length of recordings
duration = Nsamples/Fs; %Recordings length in seconds

%% Cross correlation by Convolution

r1 = xcorr(Distant, Spot); %Cross correlation

%Zero pad signals to size N1+N2-1
Dx = [Distant; zeros(length(Spot)-1,1)];
Sx = [Spot; zeros(length(Distant)-1,1)];

%FFT
F_Dx = fft(Dx);
F_Sx = fft(Sx);

%Complex conjugate of one signal
CF_Sx = conj(F_Sx);

%Multiply + IDFT
r2 = ifft(F_Dx.*CF_Sx);

%Plotting original and new
figure(1)
hold on;
plot(1:length(r1), r1);
plot(1:length(r2), r2);
legend('R1', 'R2');

% extrating max vals
max1 = find(r1==max(r1))-Nsamples;
max2 = find(r2==max(r2));



