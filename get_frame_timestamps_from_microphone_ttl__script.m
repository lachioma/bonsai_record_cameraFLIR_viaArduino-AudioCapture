
%% Select and load microphone file

clear

folder_root = 'Y:\Users\pernik\20230807\m1\trial1_rubber';

ls_mic = dir([folder_root filesep '*_mic.wav']);
if length(ls_mic) == 1
    path_mic = ls_mic(1).folder;
    filename_mic = ls_mic(1).name;
else
    [filename_mic, path_mic] = uigetfile([folder_root filesep '*_mic.wav']);
end
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
dval_min = (val_high - val_low)/2;
val_min  = val_high;


%%% Extract timestamps of camera TTLs (in microphone samples)

min_dist = 200; % Minimum distance of ttl onsets, in Hz (set reasonably > than actual camera frame rate)

[pks,locs] = findpeaks(ttl, "MinPeakDistance",Fs/min_dist,...
    "MinPeakProminence",dval_min ...
    , "MinPeakHeight",val_min...
    );

% locs contains the timestamps of the TTL onsets (in microphone samples)

figure;
hold on;
plot(ttl)
plot(locs,pks, 'v');
xlabel('Audio samples')

figure
histogram(diff(locs)/Fs*1000)
xlabel('Frame time (ms)')

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

d_locs_sec = diff(locs)/Fs;
frametime_snd = mean(d_locs_sec);
nr_dropped_frames = length( find(d_locs_sec > frametime_snd*1.5) );
if nr_dropped_frames
    fprintf('\n ! ! ! ! ! \n');
    fprintf(' Based on inter-frame interval, %d frames were dropped ! \n', nr_dropped_frames);
    fprintf(' ! ! ! ! ! \n\n');
end

%% Load .csv camera timestamps

path_vidcsv     = path_mic;
filename_vidcsv = [filename_datetime_tag '_cam1.csv'];

% Column 1: camera timestamps of each frame according to the FLIR camera internal clock (in nanoseconds)
% Column 2: camera timestamps (in Bonsai clock) of every time Bonsai received a frame from the camera (in seconds)
% Column 3: frame IDs as given by the FLIR camera processor (this might be useful to identify dropped frames)

T = readmatrix(fullfile(path_vidcsv,filename_vidcsv), ...
        'OutputType','double', 'Delimiter',',');

df = (T(end,3)+1) - v.NumFrames;
if df
    fprintf('\n ! ! ! ! ! \n');
    fprintf(' Based on the frame IDs, %d frames were dropped ! \n', df);
    fprintf(' ! ! ! ! ! \n\n');
end


%% Get duration, frame time, and frame rate according to all clocks


dur_snd = (locs(end) - locs(1)) / Fs;
dur_cam = (T(end,1) - T(1,1)) / 1e9;
dur_bon = (T(end,2) - T(1,2));

frametime_snd = mean(diff(locs)/Fs);
frametime_cam = mean(diff(T(1:end,1))) / 1e9;
frametime_bon = mean(diff(T(1:end,2)));

framerate_snd = 1/frametime_snd;
framerate_cam = 1/frametime_cam;
framerate_bon = 1/frametime_bon;
