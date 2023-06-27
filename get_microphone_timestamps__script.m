
%% Get microphone timestamps

% folder_root = pwd;
folder_root = 'Z:\Users\Jess\Data\20210826_M324';

[filename_csv, path_csv] = uigetfile([folder_root filesep '*mic.csv']);

T = readmatrix(fullfile(path_csv,filename_csv), ...
        'OutputType','double', 'Delimiter','');

% Check delay between consecutive timestamps:
% figure; histogram(diff(T))

%% Read the corresponding microphone audio file

% [filename_mic, path_mic] = uigetfile([folder_root filesep '*.wav']);
path_mic     = path_csv;
filename_mic = [filename_csv(1:end-4) '.wav'];

[y,Fs] = audioread(fullfile(path_mic,filename_mic));

%%
BufferLength = 0.1; % sec (in Bonsai, it is a property of AudioCapture node, in msec. Every BufferLength ms, the mic audio file is updated with the new samples and a single timestamp is also stored)
nr_samples_tot       = length(y);
nr_samples_eachBlock = Fs * BufferLength;

nr_blocks = nr_samples_tot / (Fs*BufferLength);
if nr_blocks - round(nr_blocks) > 1e-4
    warning('Blocks do not have a consistent number of samples')
    nr_blocks = round(nr_blocks);
else
end


% micSamps gives the audio file samples corresponding to the timestamps
% indicated in T:
micSamps     = nr_samples_eachBlock : nr_samples_eachBlock : nr_samples_tot;
micSamps_all = 1 : nr_samples_tot;

% T_all gives the timestamps of every sample in the audio file:
T_all = interp1(micSamps, T, micSamps_all, 'linear', 'extrap');
% Check delay between consecutive timestamps:
% figure; histogram(diff(T_all))

