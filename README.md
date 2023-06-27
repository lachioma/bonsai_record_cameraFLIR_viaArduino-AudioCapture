# bonsai_record_cameraFLIR_viaArduino-AudioCapture

The program provides simultaneous microphone audio recording and video recording from the FLIR camera.

## Usage
* Set the duration of the acquisition using the node “TimeSpan” (in the format hh:mm:ss).
* Run the program by clicking on Start.
* Stop and restart to initiate a new recording.

<img width="753" alt="image" src="https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/05a3eb52-c7f8-47bb-908f-fa3228006669">

&nbsp;

While running, you will see this window. The blue line is the audio signal from the microphone, the orange line is the frames' TTL.

<img width="301" alt="image" src="https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/29b7bce3-30ad-4d2c-a2dc-3ce04e6c0f6d">

&nbsp;

The data will be saved in the same path of the Bonsai program, subfolder \data:
```C:\Users\dailyuser\Documents\Bonsai\record_cameraFLIR_viaArduino+AudioCapture\data\```

The saved data consist of 4 files, with all filenames starting with the same date-time timestamp in the format “yyyymmdd_hhmmss”:
* Audio .wav file “_mic.wav” from the microphone. It contains 2 channels at 192000 Hz sampling rate. Channel 1 has the audio signal from the microphone (with mouse-produced sounds); Channel 2 has the frames TTLs. This audio file is updated with every incoming audio buffer (every 0.1 s, or 192000*0.1 samples).
* A .csv file “_mic.csv” with microphone timestamps (in Bonsai clock). A single timestamp is taken for every audio buffer (every 0.1 s, or 192000*0.1 samples). The script `get_microphone_timestamps__script.m` calculates the timestamps of every sample in the audio file.
* Video file .avi “_cam1.avi” from the FLIR camera. This file is updated with every new frame acquired.
* A .csv file “_cam1.csv”, containing:
  1. camera timestamps (in Bonsai clock) of every time Bonsai received a frame from the camera;
  2. camera timestamps of each frame according to the FLIR camera internal clock;
  3. frame IDs as given by the FLIR camera processor (this might be useful to identify dropped frames).
 
## Camera settings
To change frame rate, exposure time, gain, resolution, etc. use the camera's own software SpinView (see screenshot below). Close this software before running the Bonsai program, otherwise you will get an error.

<img width="936" alt="image" src="https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/237bd2f0-7e72-49e9-a326-1a312ca7c189">

&nbsp;

Use the tab “Settings” for frame rate, exposure time, gain. 

Use the tab “Image Format” to change the resolution (binning and cropping).

Please do not change anything in the tab “GPIO” or anywhere else.

If you change the camera acquisition frame rate (currently set at 50 fps), you might want to change the frame rate embedded in the video file metadata, i.e. the frame rate at which a video player (e.g. VLC) will play back the video. To change that, you need to change the node “Double -> Videofile FrameRate” that you find within the node “Some params” (see screenshot below). **Important**: again, this node does not change the actual acquisition rate of the camera, which is controlled only by SpinView. 

Within the node “Some params”, you can change:
* Frame rate embedded in the video file metadata (read above)
* Folder for data saving: use the node “String -> Folder data”
* Filenames of each file

<img width="134" alt="image" src="https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/6eb0f37a-60e6-4578-9a65-55426c3cb344">

## Extracting frame timestamps from the TTLs in the audio signal

Use the Matlab script `get_frame_timestamps_from_microphone_ttl__script.m`.

This script will automatically give you the timestamps of the TTL onsets (in microphone samples) in the variable `locs`.

Make sure that the number of video frames (from the video file) are the same than the number of TTL timestamps. 
The same script has a section to verify this.

Note that the algorithm for extraction TTLs might need to be adapted if you use a camera acquisition rate different from 50 fps (especially >50, it should still work if <50).

There is also code to load the .csv camera file.

![image](https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/ad7576bc-e3d8-4bb4-a6a6-90c7f0797b3b)
