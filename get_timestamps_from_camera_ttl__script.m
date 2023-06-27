
%% Select and load microphone file

clear

folder_root = 'C:\Users\dailyuser\Documents\Bonsai\record_cameraFLIR_viaArduino-AudioCapture\data';

[filename_mic, path_mic] = uigetfile([folder_root filesep '*_mic.wav']);
filename_datetime_tag = filename_mic(1:end-8);

[y,Fs] = audioread(fullfile(path_mic,filename_mic));

%% Extract timestamps of camera TTLs (in microphone samples)

% First assess the shape of the TTL, i.e. the values of the HIGH and LOW
% levels. These values change depending on the camera frame rate and also
% on the resistance applied by the potentiometer.

ttl = single(y(:,2));

% Take a piece from the entire ttl trace, that is 2 seconds long:
nr_samps = Fs*2;
% Take this piece from the end of the trace, because in the beginning the
% ttl changes shape. Exclude the very last 1 second because there should be
% no ttl at the very end:
final_samps_toExclude = Fs*1;

ttl_piece = ttl(end-final_samps_toExclude-nr_samps+1:end-final_samps_toExclude);

val_low  = mean(ttl_piece(ttl_piece<0));
val_high = mean(ttl_piece(ttl_piece>0));
% val_low  = -0.02;
% val_high =  0.01;
dval_min = (val_high - val_low)/3;


%%% Extract timestamps of camera TTLs (in microphone samples)

min_dist = 200; % Minimum distance of ttl onsets, in Hz (set reasonably > than actual camera frame rate)

[pks,locs] = findpeaks(ttl, "MinPeakDistance",Fs/min_dist,...
    "MinPeakProminence",dval_min);

% locs contains the timestamps of the TTL onsets (in microphone samples)

figure;
hold on;
plot(ttl)
plot(locs,pks, 'v');
xlabel('Audio samples')

figure
histogram(diff(locs))
xlabel('Frame time (audio samples)')

%% Get number of video frames and check consistency with TTLs

path_vid     = path_mic;
filename_vid = [filename_datetime_tag '_cam1.avi'];

v = VideoReader(fullfile(path_vid,filename_vid));
v.NumFrames;

if v.NumFrames ~= length(locs)
    fprintf('\n ! ! ! ! ! \n');
    fprintf(' The number of video frames is different from the number of TTL onsets extracted ! \n');
    fprintf(' ! ! ! ! ! \n\n');
end

%% Load .csv camera timestamps

path_vidcsv     = path_mic;
filename_vidcsv = [filename_datetime_tag '_cam1.csv'];

% Column 1: camera timestamps (in Bonsai clock) of every time Bonsai received a frame from the camera
% Column 2: camera timestamps of each frame according to the FLIR camera internal clock
% Column 3: frame IDs as given by the FLIR camera processor (this might be useful to identify dropped frames)

T = readmatrix(fullfile(path_vidcsv,filename_vidcsv), ...
        'OutputType','double', 'Delimiter',',');
