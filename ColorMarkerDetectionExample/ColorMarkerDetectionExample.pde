/*
Detects color markers. See illustrator file. For now 6 markers are supported. 
See illustrator file for the template. 

It assumes one marker at a time right now. 

It just checks the middle color inside a thick black border square. 

Install the OpenCV for Processing library (Sketch > Import library):
https://github.com/atduskgreg/opencv-processing
*/

import gab.opencv.*;
import processing.video.*;

Capture video;
ColorMarkerDetector markerDetector;

void setup() {
  size(320,240);
  frameRate(25);
  
  video = new Capture(this,320, 240);
  video.start();
  
  markerDetector = new ColorMarkerDetector(this, video.width, video.height);
}

void draw() {
  
  // Read last captured frame
  if (video.available()) {
    video.read();
    markerDetector.processFrame(video, true);
  }
  
  // do something based on the marker
  if(markerDetector.frameHasMarker()) {
    
    int index = markerDetector.foundColorIndex();
    
    fill(0);
    noStroke();
    rect(10, video.height-20, video.width-20, 15);
    fill(markerDetector.colorHex[index]);
    textAlign(CENTER, TOP);
    text("found index: " + index + " - color: " + markerDetector.colorName[index], video.width/2, video.height-20);
  }
  
}