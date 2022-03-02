close all
clear

C = 343; %Speed of sound m/s

home = cd('Elec_ORTF/');
mylist = ls('*.wav');

[Left, Fs] = audioread(strip(mylist(1,:)));
[Right, ~] = audioread(strip(mylist(2,:)));
[LeftORTF, ~] = audioread(strip(mylist(3,:)));
[RightORTF, ~] = audioread(strip(mylist(4,:)));
cd(home);

Nsamples = size(Left,1); %Sample Length of stereo source recordings
duration = Nsamples/Fs; %Recordings length in seconds

cd('Elec_Mono')
mylist = ls('*.wav');

[Spot, ~] = audioread(strip(mylist(1,:)));
[Dist, ~] = audioread(strip(mylist(2,:)));
cd(home);

NMsamples = size(Spot,1); %Sample Length of mono source recordings
Mduration = NMsamples/Fs; %Recordings length in seconds

%% Distance between mics


rL = xcorr(Left, LeftORTF); %Cross correlation between left mics
rR = xcorr(Right, RightORTF); %Cross correlation between Right mics

figure(1)
subplot(2,1,1)
plot(-1024:1024, rL(Nsamples-1024:Nsamples+1024))
title('Cross correlation between left mics');
axis([-1024 1024 -25 25])
grid on;

subplot(2,1,2)
plot(-1024:1024, rR(Nsamples-1024:Nsamples+1024))
title('Cross correlation between Right mics');
axis([-1024 1024 -25 25])
grid on;

delayL = find(rL==max(rL))-Nsamples;
delayR = find(rR==max(rR))-Nsamples;

distL = abs(delayL)*C/Fs;% d = |samples|*C/fs
distR = abs(delayR)*C/Fs;

fprintf('Calculated distance between left mics = %fm\n\n', distL);
fprintf('Calculated distance between Right mics = %fm\n\n', distR);


%% Mono Source

rM = xcorr(Spot, Dist); %Cross correlation between left mics

figure(2)

plot(-1024:1024, rM(NMsamples-1024:NMsamples+1024))
title('Cross correlation between mics (Mono Source)');
axis([-1024 1024 -320 320])
grid on;

delayM = find(rM==max(rM))-NMsamples;

distM = abs(delayM)*C/Fs;% d = |samples|*C/fs

fprintf('Calculated distance between mics (mono source) = %fm\n\n', distM);

%% Visualizing Phase effects due to Sample shift

PN = pinknoise(Fs/4);
PN_Fft = fft(PN); 
PN_Fft = fftshift(PN_Fft); 

N = length(PN);             % number of samples
f = [-N/2:N/2-1]/N;         % frequency range
power = abs(PN_Fft);        % power of the DFT

figure (3)
plot(f,power)
xlabel('Frequency')
ylabel('Power')




