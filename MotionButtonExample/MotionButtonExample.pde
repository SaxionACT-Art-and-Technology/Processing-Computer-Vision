/*
Frame Differencing example:
- including mirror effect
- you can place motion buttons on the screen
- in the setup we place the buttons in a grid. 
- you probably need to tweak some variables in the MotionButton class. 

Install the OpenCV for Processing library (Sketch > Import library):
https://github.com/atduskgreg/opencv-processing

Check also the reference:
http://atduskgreg.github.io/opencv-processing/reference/

One OpenCV object is used to flip the image (so webcam acts like a mirror). 

We use OpenCV Mat objects for framedifferencing. See this issue if you'd like to know why
https://github.com/atduskgreg/opencv-processing/issues/79

kasperkamperman.com - 24-06-2015
*/

import gab.opencv.*;
import processing.video.*;
import org.opencv.core.Mat;

Capture video;

OpenCV cvFlip; 
OpenCV cv;     

Mat cvLastFrameMat;
Mat cvThisFrameMat;

PImage scaledImg;
PImage differenceImg;

// size of the webcam capture
// depends your camera
// also modifify the cvDivider if you change this
int captureWidth  = 1280;
int captureHeight = 720;

int cvDivider = 8; // the higher the smaller the cv resolution

int cvWidth; 
int cvHeight;

int rows = 3; // rows
int cols = 4; // cols

// array for the motionbutton objects
MotionButton [] buttons = new MotionButton[rows * cols];

//void settings() {
//  fullScreen(P2D);
//}

void setup() {
  // P2D uses OpenGL, probably it runs more fluent
  size(1280,720, P2D);
  smooth(4);
  
  // frame rate more then 25fps doesn't make much sense
  frameRate(25);
  
  // capture video from the webcam
  // check Processing examples for more options on capturing (selecting a camera for example)
  video = new Capture(this, captureWidth, captureHeight, 25);
  video.start();  
  
  // opencv object that is purely used to flip the video image
  cvFlip = new OpenCV( this, video.width, video.height); 
  cvFlip.useColor();
  
  // we will progress changed motion on a smaller image, this makes
  // calculations faster (and your computer running smoother). 
  cvWidth  = video.width/cvDivider;
  cvHeight = video.height/cvDivider;
  
  // opencv object for frame differencing
  cv = new OpenCV( this, cvWidth, cvHeight); 
  
  // image to store the resized video frame
  scaledImg     = createImage(cvWidth, cvHeight, RGB);
  
  // image to store the motion difference between two frames
  differenceImg = createImage(cvWidth, cvHeight, RGB);
  
  // opencv Matrix (used to check difference between frames)
  cvLastFrameMat = cv.getGray(); // init the cvLastFrameMatrix
  
  // places the buttons on the screen
  // we use a grid in this example with a for-loop
  // however you make separate buttons and place them where you want of course
  for(int i = 0; i<buttons.length; i++) {
    
    // give a size
    int buttonSize = 80;
    
    // calculate space between the buttons to spread them equally over the screen
    int xSpacing = (width - (cols*buttonSize)) / (cols+1); 
    int ySpacing = (height - (rows*buttonSize)) / (rows+1); 
    
    // calculate the x and y position of each button
    int x = xSpacing + buttonSize/2 + ((i%cols) * (xSpacing+buttonSize));
    int y = ySpacing + buttonSize/2 + ((i/cols) * (ySpacing+buttonSize));
    
    // create a button on position x, y, size, a number
    // we also pass the size of the differenceImage
    buttons[i] = new MotionButton(x, y, buttonSize, i, differenceImg.width, differenceImg.height);
    
    // when debugMode is true the number of the button (i) is shown
    buttons[i].debugMode = true;
    
    // give the button a color
    buttons[i].setColor(color(255,0,196));
  }
}

void draw() {
  
  background(0);
  
  // only process a video frame when there is a new one
  // this is because the draw() loop is mostly not in sync with webcam framerates
  if (video.available()) {
    
    // read the frame
    video.read();
    
    // store the frame in the cvFlip object 
    cvFlip.loadImage(video);
    // flip the frame horizontal so it behaves as a mirror 
    // (vertical doesn't make much sense)
    cvFlip.flip(OpenCV.HORIZONTAL);
    
    // in makeDifferenceImage function we check the difference between this video frame 
    // and the previous video frame
    makeDifferenceImage();
    
    // pass the differenceImg to each button to detect if the motion happened
    // on the location of the button
    for(int i = 0; i<buttons.length; i++) {
      buttons[i].detectMotion(differenceImg); 
    }
  }
  
  // show the flipped video frame and scale it to the whole screen
  // comment this to only see the difference in motion
  image( cvFlip.getOutput(), 0, 0, width, height); 
  
  // show the motion on top, you can turn this off of course
  // blend(src, sx, sy, sw, sh, dx, dy, dw, dh, mode)
  //blend(differenceImg, 0, 0, cvWidth, cvHeight, 0, 0, width, height, ADD);
  
  // loop through all the buttons and display them
  // we also check if a button is pressed
  for(int i = 0; i<buttons.length; i++) {
    
    buttons[i].display(); 
    
    // see if a button is triggered
    if(buttons[i].getPressedTrigger()) {
        // print something to the console
        // of course you can trigger sound and other cool stuff here
        // println("button "+i+" pressed");
    }
      
  } 
  
}

void makeDifferenceImage() {
  
  // copy and scale the cvFlip image to scaledImg for opencv
  scaledImg.copy(cvFlip.getOutput(), 0, 0, cvFlip.width, cvFlip.height, 0, 0, cv.width, cv.height);
  
  // load the scaled img in the cv object for frame differencing
  cv.loadImage(scaledImg);
  
  // convert the image to an OpenCV matrix
  cvThisFrameMat = cv.getGray();
  
  // difference with last matrix (previous video frame) and this matrix (current video frame)
  // the result is stored in the cv object
  OpenCV.diff(cvThisFrameMat, cvLastFrameMat);

  // use blur to emphasize differences
  cv.blur(3); 
  // use threshold to make it a black and white image
  cv.threshold(20);    
  
  // cv output in a differenceImg (this is what we use to check motion under the buttons)
  differenceImg = cv.getOutput();
  
  // now we store this frame because that will be used a the previous frame to
  // compare the differences
  // we load to scaledImg in the cv object and convert it to an OpenCV matrix
  cv.loadImage(scaledImg);
  cvLastFrameMat = cv.getGray();
}