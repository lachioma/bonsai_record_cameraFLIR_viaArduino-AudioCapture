function Files = get_frame_timestamps_from_microphone_ttl__fun(folder_root, ShowFigures)

if nargin < 1 || isempty(folder_root)
    folder_root = 'Y:\Users\pernik\';
end
if nargin < 2 || isempty(ShowFigures)
    ShowFigures = false;
end
funstr = which('uipickfiles');
if isempty(funstr)
    p = mfilename("fullpath");
    addpath(fileparts(p));
end

folder_dialogbox    = folder_root;

FilesOrFolders = uipickfiles(...
    'FilterSpec',folder_dialogbox,... starting folder
    'REFilter', '\.avi$|\.mp4$|\.mpg$',... $ = end of the word
    ...'REFilter', '(\.csv$)',...
    'Prompt','Select video files or folders',...
    'Output','cell');

if isempty(FilesOrFolders) || (isnumeric(FilesOrFolders) && FilesOrFolders==0)
    fprintf('No video files of folders selected.\n\n')
    return
end

Files = struct;
cnt = 0;


for f = 1 : length(FilesOrFolders)
    if isfile(FilesOrFolders{f})
        [filepath,name,ext] = fileparts(FilesOrFolders{f}); %#ok<ASGLU> 
        listing = dir(FilesOrFolders{f});
        if strcmpi(ext,'.avi') || strcmpi(ext,'.mp4') || strcmpi(ext,'.mpg')
            cnt = cnt + 1;
            i = 1; % listing has only 1 file
            Files(cnt).folder         = listing(i).folder;
            Files(cnt).filename_vid   = listing(i).name;
            Files(cnt).fullpath_vid   = fullfile(listing(i).folder, listing(i).name);
        end
    elseif isfolder(FilesOrFolders{f})
        listing1 = dir([FilesOrFolders{f} '/**/*.avi']);
        listing2 = dir([FilesOrFolders{f} '/**/*.mp4']);
        listing3 = dir([FilesOrFolders{f} '/**/*.mpg']);
        listing  = [listing1; listing2; listing3];
        for i = 1 : length(listing)
            cnt = cnt + 1;
            Files(cnt).folder         = listing(i).folder;
            Files(cnt).filename_vid   = listing(i).name;
            Files(cnt).fullpath_vid   = fullfile(listing(i).folder, listing(i).name);
        end
    else
        % fprintf(' No avi/mp4/mpg files found.\n')
    end
end
if isempty(fieldnames(Files))
    fprintf('\n No .avi files found! Exit.\n\n')
    return
end

n_files = length(Files);


for f = 1 : n_files

    Files(f).datetime_tag   = regexp(Files(f).filename_vid, '\d{8}_\d{6}','match','once'); % use 'once' to have char output instead of cell array with 1 element.
    ls_mic1 = dir( fullfile(Files(f).folder, [Files(f).datetime_tag '*.wav']) );
    ls_mic2 = dir( fullfile(Files(f).folder, [Files(f).datetime_tag '*.flac']) );
    ls_mic  = [ls_mic1; ls_mic2];
    if isempty(ls_mic)
        fprintf('\n ! ! ! No mic file found in %s \n', Files(f).folder);
        Files(f).filename_mic = '';
        Files(f).fullpath_mic = '';
    else
        Files(f).filename_mic = ls_mic(1).name;
        Files(f).fullpath_mic = fullfile(ls_mic(1).folder, ls_mic(1).name);
    end
    [filepath,name,~] = fileparts(Files(f).fullpath_vid);
    vid_csv_ls = dir( fullfile(filepath, [name '.csv']) );
    if length(vid_csv_ls)==1
        Files(f).fullpath_vid_csv = fullfile(vid_csv_ls(1).folder, vid_csv_ls(1).name);
    else
        Files(f).fullpath_vid_csv = '';
    end

end




%%

fprintf('\nNr. exps to process: %d \n\n', n_files);

for f = 1 : n_files

    fprintf('Exp %d/%d : %s \n', f, n_files, Files(f).folder);

    fullpath_mic = Files(f).fullpath_mic;

    if isempty(fullpath_mic) || ~isfile(fullpath_mic)
        fprintf(' Skipping exp because no mic file found! \n\n');
        continue
    end

    [y,Fs] = audioread(fullpath_mic);
    fprintf(' Audio file loaded. \n');

    %% Extract timestamps of camera TTLs (in microphone samples)

    fprintf(' Extracting timestamps of camera TTLs (in microphone samples) \n');

    % First assess the shape of the TTL, i.e. the values of the HIGH and LOW
    % levels. These values change depending on the camera frame rate and also
    % on the resistance applied by the potentiometer.
    
    ttl = single(y(:,2));
    
    % Take a piece from the entire ttl trace, that is 2 seconds long:
    nr_samps = Fs*2;
    % Take this piece from the end of the trace, because in the beginning the
    % ttl changes shape. Exclude the very last 1 second because there should be
    % no ttl at the very end:
    final_samps_toExclude = Fs*10;
    
    ttl_piece = ttl(end-final_samps_toExclude-nr_samps+1:end-final_samps_toExclude);
    
    % val_low  = mean(ttl_piece(ttl_piece<0));
    val_low  = prctile(ttl_piece(ttl_piece<0), 25);
    val_high = mean(ttl_piece(ttl_piece>0));
    % val_low  = -0.02;
    % val_high =  0.01;
    dval_min = (val_high - val_low)/2;
    val_min  = val_high;
    
    
    %%% Extract timestamps of camera TTLs (in microphone samples)
    
    min_dist = 100; % Minimum distance of ttl onsets, in Hz (set reasonably > than actual camera frame rate)
    
    [pks,locs] = findpeaks(ttl, "MinPeakDistance",Fs/min_dist,...
        "MinPeakProminence",dval_min ...
        , "MinPeakHeight",val_min...
        );
    
    % locs contains the timestamps of the TTL onsets (in microphone samples)
    Files(f).vid_NumTTLs = length(locs);
    fprintf(' Timestamps extracted, nr. of frame TTLs: %d \n', length(locs));
    
    if ShowFigures
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
    end




    %% Get number of video frames and check consistency with TTLs

    fullpath_vid = Files(f).fullpath_vid;
    
    fprintf(' Loading the video file to get the nr. of video frames (this will take a minute for long videos or when loading from the server)...\n');
    v = VideoReader( fullpath_vid ); %#ok<TNMLP> 
    fprintf(' Video file loaded, nr. of video frames: %d \n', v.NumFrames);
    
    nr_dropped_frames = length(locs) - v.NumFrames;

    Files(f).vid_NumFrames        = v.NumFrames;
    Files(f).vid_NumDroppedFrames = nr_dropped_frames;

    if nr_dropped_frames ~= 0

        Files(f).Problematic = true;

        fprintf('\n ! ! ! ! ! \n');
        fprintf(' There are %d dropped frames ! \n', nr_dropped_frames);
        fprintf(' The number of video frames is %d, the number of TTL onsets extracted is %d \n', v.NumFrames, length(locs));
        fprintf(' The TTL onset extraction could have missed some TTLs, or some frames could have been dropped.\n')
        fprintf(' N.B. dropped frames do have a TTL (=camera sensor has been exposed) but they are not saved in the video file.\n')
        fprintf(' ! ! ! ! ! \n');

        thr_dt = 0.003; % how many sec a frame has to be offset to detect a dropped frame
        d_locs_sec = diff(locs)/Fs;
        frametime_snd = mean(d_locs_sec);
        problematic_ttls =  find(d_locs_sec > (frametime_snd+thr_dt) | d_locs_sec < (frametime_snd-thr_dt)) ;
        nr_problematic_ttls = length( problematic_ttls );
        if nr_problematic_ttls
            fprintf('\n ! ! ! ! ! \n');
            fprintf(' Based on inter-TTL interval, %d TTLs were too close or too far apart compared to expected! \n', nr_problematic_ttls);
            fprintf(' There might be something wrong with the TTL onset extraction (but not necessarily). \n')
            fprintf(' ! ! ! ! ! \n');
        end

    
    %     T = readmatrix( Files(f).fullpath_vid_csv, ...
    %         'OutputType','double', 'NumHeaderLines',1, 'Delimiter',',');
    
        Ttable = readtable(Files(f).fullpath_vid_csv, ...
          'Delimiter',',');
        T = table2array(Ttable);
        frameID_col = find( contains(Ttable.Properties.VariableNames, 'frameID','IgnoreCase',true) );
    
    
        %%% Get duration, frame time, and frame rate according to all clocks
    
        dur_snd = (locs(end) - locs(1)) / Fs;
        dur_cam = (T(end,1) - T(1,1)) / 1e9;
        dur_bon = (T(end,2) - T(1,2));
        
        frametime_snd = mean(diff(locs)/Fs);
        frametime_cam = mean(diff(T(1:end,1))) / 1e9;
        frametime_bon = mean(diff(T(1:end,2)));
        
        framerate_snd = 1/frametime_snd;
        framerate_cam = 1/frametime_cam;
        framerate_bon = 1/frametime_bon;
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
        inds_dropped_frames_id = find(diff(T(:,frameID_col)) > 1); %#ok<FNDSB> 
        nr_dropped_frames_id = length( inds_dropped_frames_id );
        if nr_dropped_frames_id
            fprintf('\n ! ! ! ! ! \n');
            fprintf(' Based on the frame IDs, %d frames were dropped ! \n', nr_dropped_frames_id);
            fprintf(' ! ! ! ! ! \n');
        end
        dt_dropped_frames_id = (T(inds_dropped_frames_id+1,1)-T(inds_dropped_frames_id,1))/1e9;
        
        
        thr_dt = 0.005; % how many sec a frame has to be offset to detect a dropped frame
        dt_cam_sec = diff(T(:,1)/1e9);
        frametime_cam = mean(dt_cam_sec);
        inds_dropped_cam = find( (dt_cam_sec > (frametime_cam+thr_dt)) | (dt_cam_sec < (frametime_cam-thr_dt)));
        nr_dropped_frames_cam = length( inds_dropped_cam );
        if nr_dropped_frames_cam
            fprintf('\n ! ! ! ! ! \n');
            fprintf('Based on inter-frame interval of camera timestamps, %d frames were dropped ! \n', nr_dropped_frames_cam);
            fprintf(' ! ! ! ! ! \n');
        end
        dt_dropped_frames_cam = (T(inds_dropped_cam+1,1)-T(inds_dropped_cam,1))/1e9;
        
        
        dt_bon_sec = diff(T(:,2));
        frametime_bon = mean(dt_bon_sec);
        inds_dropped_frames_bon =  find(dt_bon_sec > frametime_bon*1.9);
        nr_dropped_frames_bon   = length( inds_dropped_frames_bon );
        % if nr_dropped_frames_bon
        %     fprintf('\n ! ! ! ! ! \n');
        %     fprintf(' Based on inter-frame interval of bonsai timestamps, %d frames were dropped ! \n', nr_dropped_frames_bon);
        %     fprintf(' ! ! ! ! ! \n\n');
        % end
    
    
    
        if ~isempty(inds_dropped_frames_id) && isequal(inds_dropped_frames_id, inds_dropped_cam)
            fprintf('  Dropped frames based on frame IDs and based on inter-frame interval of camera timestamps are matching. This is good, we can fix the problem with dropped frames ... \n')
        else
            fprintf('\n ! ! ! ! ! \n');
            fprintf('Dropped frames based on frame IDs and based on inter-frame interval of camera timestamps are empty or NOT matching. \n')
            fprintf('You need to decide which dropped frames to take. By default we take Dropped frames based on frame IDs \n')
            fprintf(' ! ! ! ! ! \n');
        end
    
    
        if length(inds_dropped_frames_id) == nr_dropped_frames
            inds_dropped_frames = inds_dropped_frames_id + 1;

            Files(f).Problematic = false;
    
        % If inds_dropped_frames_id has one frame less than the actual
        % nr_dropped_frames, take also the very last ttl as dropped frame:
        elseif length(inds_dropped_frames_id) == nr_dropped_frames-1
            inds_dropped_frames = [inds_dropped_frames_id + 1; length(locs)];
            Files(f).Problematic = false;
        else
            fprintf('\n ! ! ! ! ! \n');
            fprintf('Dropped frames based on frame IDs are too few compared to nr_dropped_frames \n')
            fprintf('Something is wrong (more than usual), check manually what is going on... \n')
            fprintf(' ! ! ! ! ! \n');
            Files(f).Problematic = true;

            % inds_dropped_frames = inds_dropped_frames_bon;
        end
    
    else

        Files(f).Problematic = false;
        fprintf(' Great! The number of video frames matches the number of TTL onsets extracted ! \n');
        inds_dropped_frames = [];
    
    end



    if Files(f).Problematic == false
        locs_final = locs;
        locs_final(inds_dropped_frames) = [];

        if length(locs_final) ~= Files(f).vid_NumFrames
            warning('The number of video frames is different from the number of TTL onsets extracted !!!')
            fprintf(' Skipping exp because dropped frames problem could not be solved! \n\n');
            Files(f).Problematic = true;
            continue
        else
            if ~isempty(inds_dropped_frames)
                Files(f).DroppedFramesCorrected = true;
            end
        end

        %%
        
        % Time vector of microphone audio data (in sec)
        t_mic = [1 : length(y)]' / Fs;
        
        % Time vector of video frames (in sec, aligned to microphone audio data)
        t_vid = t_mic(locs_final);
        
        % k = 1:1000000;
        % figure;
        % hold on;
        % plot(t_mic(k), y(k,1))
        % plot(t_vid, zeros(length(t_vid),1), 'v')
        % xlim([0 t_mic(k(end))])
    
        %% Save timestamps in .mat file
        
        datamat_fullpath = fullfile(Files(f).folder, Files(f).datetime_tag);
        try
            save(datamat_fullpath, 't_mic', 't_vid');
            Files(f).MatSaved = true;
            fprintf(' Timestamps saved in .mat file! \n');
            fprintf(' Done with this exp! \n');
        catch
            Files(f).MatSaved = false;
            printf('\n ! ! ! ! ! \n');
            fprintf(' .mat file with timestamps did NOT save! \n');
            printf('\n ! ! ! ! ! \n');
            continue
        end
    


    else % Files(f).Problematic == true
        fprintf(' Skipping exp because dropped frames problem could not be solved! \n\n');
        continue
    end

end

nr_problematic_files = sum([Files.Problematic]);

if  nr_problematic_files > 0
    fprintf('Number of problematic files is: %d\n\n', sum([Files.Problematic]));
end

if nargout < 1
    assignin("caller","Files");
end
