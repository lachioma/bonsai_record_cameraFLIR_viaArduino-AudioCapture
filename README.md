# bonsai_record_cameraFLIR_viaArduino-AudioCapture

The program provides simultaneous microphone audio recording and video recording from the FLIR camera.

## Usage
* Set the camera acquisition rate in the Arduino script (see section **Camera settings > Frame rate** below)
* Set the duration of the acquisition (i.e. trial) using the node “TimeSpan” (in the format hh:mm:ss).
* Run the program by clicking on Start.
* Stop and restart to initiate a new recording.
* Avoid interrupting the Bonsai program before the end of the trial (more details in the note "N.B.", section Saved data).

<img width="753" alt="image" src="https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/05a3eb52-c7f8-47bb-908f-fa3228006669">

&nbsp;

## Windows during acquisition

<img width="683" alt="Screenshot 2023-07-18 190222" src="https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/95dca692-8964-4d06-9d95-bac5574ebb20">

&nbsp;

While running, you will see this window updating every 0.1 seconds. The blue line is the audio signal from the microphone, the orange line is the frames' TTL.
When the trial is over, this trace will not update.

<img width="301" alt="image" src="https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/29b7bce3-30ad-4d2c-a2dc-3ce04e6c0f6d">

&nbsp;

In another window, you will see the camera view in real time. On the top left corner, the frame ID is also indicated. This is also reported in the file “_cam1.csv” along with the corresponding timestamps (see below).

There is also a plot to monitor the frame rate, and one plot counting the dropped frames.

&nbsp;


## Saved data

The data will be saved in the same path of the Bonsai program, subfolder \data:
```C:\Users\dailyuser\Documents\Bonsai\record_cameraFLIR_viaArduino+AudioCapture\data\```

The saved data consist of 4 files, with all filenames starting with the same date-time timestamp in the format “yyyymmdd_hhmmss”:
* Audio .wav file “_mic.wav” from the microphone. It contains 2 channels at 192000 Hz sampling rate. Channel 1 has the audio signal from the microphone (with mouse-produced sounds); Channel 2 has the frames TTLs. This audio file is updated with every incoming audio buffer (every 0.1 s, or 192000*0.1 samples).
* A .csv file “_mic.csv” with microphone timestamps (in Bonsai clock, seconds). A single timestamp is taken for every audio buffer (every 0.1 s, or 192000*0.1 samples). The script `get_microphone_timestamps__script.m` calculates the timestamps of every sample in the audio file.
* Video file .avi “_cam1.avi” from the FLIR camera. This file is updated with every new frame acquired.
* A .csv file “_cam1.csv” (see screenshot below), containing:
  1. camera timestamps of each frame for every time Bonsai received a frame from the camera (in Bonsai clock, seconds);
  2. camera timestamps of each frame according to the FLIR camera internal clock (microseconds);
  3. frame IDs as given by the FLIR camera processor, starting from 0 at each acquisition (this might be useful to identify dropped frames).

<img width="416" alt="Screenshot 2023-07-18 182308" src="https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/b0498183-af3e-4bbb-ac7a-bf483a2667ed">

&nbsp;

**N.B.** If you interrupt the Bonsai program before the end of the trial (trial duration set using the node "TimeSpan"), a few video frames at the end of the video file will not have the corresponding frame TTLs in the audio file. This happens because when you interrupt the trial, the audio file will be slighlty cut at the end with respect to the video file (because the last unsaved audio buffer (<0.1 seconds) will be lost).

 
## Camera settings
### Frame rate
The frame rate is controlled by Arduino. To change frame rate:
* open the arduino script `TTL_pulse_controlled_via_timer_serial.ino` with Arduino IDE, located in the Bonsai program folder;
* set the frame rate by changing the variable `ttl_freq` on top of the script;
* click on the rightward arrow to compile and upload the script on the Arduino board

If you change the camera acquisition frame rate (currently set at 50 fps), you might want to change the frame rate embedded in the video file metadata, i.e. the frame rate at which a video player (e.g. VLC) will play back the video. To change that, you need to change the node “Double -> Videofile FrameRate” that you find within the node “Some params” (see screenshot below). This node also affects the Dropped frames monitoring. 
**Important**: again, this node does not change the actual acquisition rate of the camera, which is controlled only by the TTL from Arduino. 

![InkedInkedScreenshot 2023-07-18 183523](https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/215b7b16-e572-411f-84e6-ed534907305b)


### Exposure time, gain, resolution, other camera settings
To change exposure time, gain, resolution, etc. use the camera's own software SpinView (see screenshot below). Close this software before running the Bonsai program, otherwise you will get an error.

<img width="936" alt="image" src="https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/237bd2f0-7e72-49e9-a326-1a312ca7c189">

&nbsp;

Use the tab “Settings” for exposure time, gain. 

Use the tab “Image Format” to change the resolution (binning and cropping).

Please do not change anything in the tab “GPIO” or anywhere else.



Within the node “Some params”, you can change:
* Frame rate embedded in the video file metadata (read above)
* Folder for data saving: use the node “String -> Folder data”
* Filenames of each file

<img width="134" alt="image" src="https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/6eb0f37a-60e6-4578-9a65-55426c3cb344">

### Camera trigger via Arduino

The Bonsai program uses an Arduino board (serially connected via USB) to trigger the acquisition of frames. Arduino runs the script `TTL_pulse_controlled_via_timer_serial.ino`. There is an led wired to the Arduino: light on indicates camera trigger on.

## Extracting frame timestamps from the TTLs in the audio signal

Use the Matlab script `get_frame_timestamps_from_microphone_ttl__script.m`.

This script will automatically give you the timestamps of the TTL onsets (in microphone samples) in the variable `locs`.

Make sure that the number of video frames (from the video file) are the same than the number of TTL timestamps. 
The same script has a section to verify this.

**N.B.** If the Bonsai program is interrupted before the end of the trial as set using the node "TimeSpan", the number of TTL timestamps will be very likely lower than the number of video frames in the video file, because the audio file will be slighlty cut at the end (the last unsaved audio buffer will be lost, corresponding to <0.1 seconds).

Note that the algorithm for extraction TTLs might need to be adapted if you use a camera acquisition rate different from 50 fps (especially >50, it should still work if <50).

There is also code to load the .csv camera file.

![image](https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/ad7576bc-e3d8-4bb4-a6a6-90c7f0797b3b)



&nbsp;

Just another screenshot of the Bonsai program.

<img width="956" alt="Screenshot 2023-07-18 182406" src="https://github.com/lachioma/bonsai_record_cameraFLIR_viaArduino-AudioCapture/assets/29898879/a92b11d4-cd17-46c2-b22d-8488d80d71e9">


