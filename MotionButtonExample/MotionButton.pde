/*

In the function detectMotion we get a picture with pixels that changed (because something
was moving in front of the camera). 

We count the white pixels in the rectangle (surface) below the circle. 
With a threshold we can decide when we think there is enough motion. For example
10% of the pixels in the button area need to be white. 

We don't what to trigger something directly, because maybe someone was just walking by. That's
we would like to see see motion over several frames. 

When we see motion we add for example 0.25 to the 'progressRawValue' variable. 
When there was no motion we substract for example a lower number from the 'progressRawValue' variable. 
So if there is enough motion the 'progressValue' will reach 1.0 or higher (depending on the charge factor) 

When that happens ('progressRawValue>=1.0') we see it as a press (isPressed == true). 

The 'progressValue' variable is visualized in the progressbar and the alpha of the button. 

*/

class MotionButton {
  
  // show the number of the MotionButton when it's true
  public boolean debugMode = false;
  
  // progress bar weight
  public int progressWeight = 8;
  
  // how much percent of the area need to have motion
  // to see it as a trigger (for the slider)
  // value between 0.0 - 1.0 (towards 0 is more sensitive for motion)
  public float detectionSurfacePercent = 0.10;
  
  // the higher the number the more time we need to see motion in the button area.
  public int progressAddFactor = 4;
  
  // the higher the number the more we can charge the button so it stays pressed even if there is no motion
  public int progressChargeFactor = 4;
  
  // button appearance
  private int x;
  private int y;
  private int size; 
  private int number;
  private color buttonColor = color(255,0,0);
  
  // variables for motion detection
  private int differenceImgW;
  private int differenceImgH;
  private int detectionAreaX1; 
  private int detectionAreaY1; 
  private int detectionAreaX2;
  private int detectionAreaY2;
  private int detectionAreaWidth;
  private int detectionAreaHeight;
  
  // variables for counting pixels and values for the progress bar
  private int amountOfPixels;
  private int detectionPixelThreshold = 0;
  private int detectionPixelCounter;
  
  // progress bar variables
  public  float progressValue;          
  private float progressAddValue;
  private float progressSubstractValue;
  private float progressChargeLimit;
  private float progressRawValue;
  
  public boolean isPressed = false;
  
  // for state change
  private boolean lastPressed = false;
  
  private boolean isPressedTrigger = false;
  private boolean isReleasedTrigger = false;
  
  MotionButton(int _x, int _y, int _s, int _n, int _diffW, int _diffH) {
    this.x      = _x; 
    this.y      = _y;
    this.size   = _s;
    this.number = _n;
    
    this.differenceImgW = _diffW;
    this.differenceImgH = _diffH;
    
    // we draw a rectangle around our ellipse and scale it according to the
    // difference image size
    
    // calculate the scaling of the differenceImg compared with the screen
    // for example image width is 640 pixels, screen is 1280 pixels, factor is 0.5 
    float scaleFactorW = differenceImgW/(float)width;
    float scaleFactorH = differenceImgH/(float)height;
    
    detectionAreaWidth  = (int) (size * scaleFactorW);
    detectionAreaHeight = (int) (size * scaleFactorH);
    
    // the four corner points from the area covered by this button
    // x-(size/2):  because the x is the center of the ellipse. So size/2 gives us the edge
    detectionAreaX1 = (int) ( (x-(size/2)) * scaleFactorW );
    detectionAreaY1 = (int) ( (y-(size/2)) * scaleFactorH );
    detectionAreaX2 = detectionAreaX1 + detectionAreaWidth;
    detectionAreaY2 = detectionAreaY1 + detectionAreaHeight;
    
    // amount of pixels in this area
    amountOfPixels = detectionAreaWidth * detectionAreaHeight;
     
    // calculate the amount of pixels that have to be white before we see it as a motion
    // for example of the size is 100 pixels then 10 pixels have to be white
    detectionPixelThreshold = (int) (amountOfPixels * detectionSurfacePercent); 
    
    // calculate how big the values are that need to be added or substracted when there is motion
    // make the addFactor (see above) lower if you want a faster reaction on motion 
    progressAddValue       = 1.0/progressAddFactor;
    progressSubstractValue = progressAddValue/4.0;
    
    // our threshold limit for a trigger/press and full progressbar is 1.0. 
    // however we can make the value higher, so when there is no motion for a few frames
    // the button still seems pressed. 
    progressChargeLimit    = 1.0 + (progressSubstractValue*progressChargeFactor);
  }
  
  // set the color of the button
  void setColor(color c) {
    buttonColor = c;
  }
  
  // call this to detect if there was motion below the button
  // if you don't call to button doesn't work...
  void detectMotion(PImage differenceImg) {
    
    // reset the pixel counter
    detectionPixelCounter = 0;
    
    // walk through the area below the button 
    for( int y = detectionAreaY1; y < detectionAreaY2; y++ ){   
      for( int x = detectionAreaX1; x < detectionAreaX2; x++ ){
        
          // safety check if a button is half off the screen, there isn't any
          // image data
          if ( x < differenceImg.width && x > 0 && y < differenceImg.height && y > 0 ) { 
            
            // If the brightness in the black and white image is above 127 (in this case, if it is white)
            // -8421505 is equal to color(127)
            if (differenceImg.pixels[x + (y * differenceImg.width)] > -8421505) { 
              // Add 1 to the movementAmount variable.
              detectionPixelCounter++;                                         
            }
          }
          else {
            // if the button is partly outside of the image, we need to lower the threshold.
            // because there are no pixels that can be white (or black) at that point
            detectionPixelThreshold = detectionPixelThreshold--;
          }
      }
    }
    
    // if there is motion, we make 'value' higher, otherwise lower.
    if(detectionPixelCounter>detectionPixelThreshold) { 
      progressRawValue = progressRawValue + progressAddValue;
    }
    else {
      progressRawValue = progressRawValue - progressSubstractValue; 
    }
    
    // the progressRawValue can be higher then 1.0 (used to 'charge' the button)
    // constrain the Raw Value between 0.0 and the charge limit
    progressRawValue = constrain(progressRawValue, 0.0, progressChargeLimit);
    
    // our progressValue (for the progress bar) should be between 0.0 and 1.0
    if(progressRawValue > 1.0) progressValue = 1.0;
    else                       progressValue = progressRawValue;
    
    // if the value is high enough the button is pressed otherwise not. 
    if(progressRawValue >= 1.0) {   
      isPressed = true;
    }
    else {
      isPressed = false;
    }
    
    // check if the button changed state (pressed true/false)
    // more about state change check this tutorial:
    // http://www.kasperkamperman.com/blog/arduino/arduino-programming-state-change/
    if(lastPressed != isPressed) {
      
      // when the is not pressed it's released
      if(isPressed) isPressedTrigger = true;
      else          isReleasedTrigger = true;
    }
    else {
      isPressedTrigger = false;
      isReleasedTrigger = false;
    }
    
    // remember this button state for the next check
    lastPressed = isPressed;
    
  }
  
  // get the amount of motion within the button
  // a value between 0.0 and 1.0. 1.0 all pixels changed, 0.0 no movement at all
  float getMotionAmount() {
      return detectionPixelCounter/float(amountOfPixels);
  }
  
  // get a trigger (just one time true) when the button is pressed
  boolean getPressedTrigger() {
      boolean tempTrigger = isPressedTrigger;
      // make it false after we call it, otherwise we can receive true the next frame as well
      isPressedTrigger = false; 
      return tempTrigger;
  }
  
  // get a trigger (just one time true) when the button is released
  boolean getReleasedTrigger() {
      boolean tempTrigger = isReleasedTrigger;
      isReleasedTrigger = false; 
      return tempTrigger;
  }
  
  
  // call this if you'd like to display the button. 
  // this is not necessary if you just want to have spots to detect motion
  void display() {
    
    // button fill with alpha change based on value
    noStroke();
    fill(buttonColor, progressValue * 255);
    ellipse(x, y, size-(progressWeight*2), size-(progressWeight*2));
    
    // black circle outline for progressbar
    noFill();
    strokeWeight(progressWeight);
    stroke(0);
    ellipse(x, y, size, size); 
    
    // circular progressbar to show the value
    stroke(buttonColor);
    arc(x, y, size, size, -HALF_PI, map(progressValue, 0.0, 1.0, -HALF_PI, TWO_PI-HALF_PI));
    
    // show the number of the button in debugmode
    // the number gets bigger when isPressed is true
    if(debugMode) { 
      if(isPressed) textSize(44); 
      else          textSize(32);
      
      textAlign(CENTER, CENTER);
      fill(255);
      text(number,x,y-5);
    }
  }
}