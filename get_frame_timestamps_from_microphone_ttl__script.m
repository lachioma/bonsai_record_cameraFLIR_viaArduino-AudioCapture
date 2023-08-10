
%% Select and load microphone file

clear

folder_root = 'Y:\Users\pernik\20230807\m1\trial5_rubber';

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
% xlim([0 Fs*2]) % first 2 seconds
% xlim([length(ttl)-[Fs*2, 0]]) % last 2 seconds

figure
histogram(diff(locs)/Fs*1000)
xlabel('Frame time (ms)')

%% Get number of video frames and check consistency with TTLs

path_vid     = path_mic;
filename_vid = [filename_datetime_tag '_cam1.avi'];

fprintf('Loading the video file to get the nr. of video frames, this will take a minute for long videos...\n');
v = VideoReader(fullfile(path_vid,filename_vid));
fprintf('Video file loaded, nr. of video frames: %d \n', v.NumFrames);

v.NumFrames;

if v.NumFrames ~= length(locs)
    fprintf('\n ! ! ! ! ! \n');
    fprintf(' The number of video frames is different from the number of TTL onsets extracted ! \n');
    fprintf(' The TTL onset extraction could have missed some TTLs, or some frames could have been dropped.\n')
    fprintf(' N.B. dropped frames do have a TTL (=camera sensor has been exposed) but they are not saved in the video file.\n')
    fprintf(' ! ! ! ! ! \n\n');
end


k = 0.05;
d_locs_sec = diff(locs)/Fs;
frametime_snd = mean(d_locs_sec);
nr_problematic_ttls = length( find(d_locs_sec > frametime_snd*(1+k) | d_locs_sec < frametime_snd*(1-k)) );
if nr_problematic_ttls
    fprintf('\n ! ! ! ! ! \n');
    fprintf(' Based on inter-TTL interval, %d TTLs were too close or too far apart compared to expected! \n', nr_problematic_ttls);
    fprintf(' Likely something is wrong with the TTL onset extraction... \n')
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

%% Check for dropped frames

% nr_dropped_frames_id = (T(end,3)+1) - v.NumFrames;
nr_dropped_frames_id = sum( diff(T(:,3)) > 1 );
if nr_dropped_frames_id
    fprintf('\n ! ! ! ! ! \n');
    fprintf(' Based on the frame IDs, %d frames were dropped ! \n', nr_dropped_frames_id);
    fprintf(' ! ! ! ! ! \n\n');
end
inds_dropped_id = find(diff(T(:,3)) > 1);
dt_dropped_frames_id = (T(inds_dropped_id+1,1)-T(inds_dropped_id,1))/1e9;

dt_cam_sec = diff(T(:,1)/1e9);
frametime_cam = mean(dt_cam_sec);
nr_dropped_frames_cam = length( find(dt_cam_sec > frametime_cam*1.5) );
if nr_dropped_frames_cam
    fprintf('\n ! ! ! ! ! \n');
    fprintf(' Based on inter-frame interval of camera timestamps, %d frames were dropped ! \n', nr_dropped_frames_cam);
    fprintf(' ! ! ! ! ! \n\n');
end
inds_dropped = find(dt_cam_sec > frametime_cam*1.5);
dt_dropped_frames_cam = (T(inds_dropped+1,1)-T(inds_dropped,1))/1e9;


dt_bon_sec = diff(T(:,2));
frametime_bon = mean(dt_bon_sec);
nr_dropped_frames_bon = length( find(dt_bon_sec > frametime_bon*1.9) );
% if nr_dropped_frames_bon
%     fprintf('\n ! ! ! ! ! \n');
%     fprintf(' Based on inter-frame interval of bonsai timestamps, %d frames were dropped ! \n', nr_dropped_frames_bon);
%     fprintf(' ! ! ! ! ! \n\n');
% end

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
