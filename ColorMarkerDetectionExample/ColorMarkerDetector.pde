// not really commented yet. 

import gab.opencv.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.core.Core;
import org.opencv.imgproc.Moments;

import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.CvType;

import java.awt.Rectangle;

import org.opencv.core.Point;
import org.opencv.core.Size;

class ColorMarkerDetector {
  
  private OpenCV opencv;

  //PApplet applet; 
  
  private boolean foundRect = false;
  private int rectColorIndex = -1;
  
  // add the colors you'd like to detect. 
  // don't pick colors to close to eachother. When we find a rectangle marker we always return
  // the closest color. 
  public color [] colorHex    = { #ff0000, #ffff00,  #00ff00, #00ffff, #0000ff, #ff00ff };
  public String [] colorName  = { "red",   "yellow", "green", "cyan",  "blue", "purple" };
  public color markerColor;
  
  ColorMarkerDetector(PApplet p, int w, int h) {
    opencv = new OpenCV(p, w, h);
    opencv.gray();
  }
  
  
  void processFrame(PImage videoFrame, boolean showDetection) {
    
    foundRect = false;
    
    ArrayList<MatOfPoint> contours  = new ArrayList<MatOfPoint>();
    Mat hierarchy = new Mat();
    
    opencv.loadImage(videoFrame);
    
    if(showDetection) image(video, 0, 0);
    
    Mat thresholdMat = OpenCV.imitate(opencv.getGray());
     
    Imgproc.adaptiveThreshold(opencv.getGray(), thresholdMat, 255, Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C, Imgproc.THRESH_BINARY_INV, 451, -65);

    Imgproc.findContours(thresholdMat, contours, hierarchy, Imgproc.RETR_TREE, Imgproc.CHAIN_APPROX_SIMPLE); 
    
    ArrayList<Moments> mu = new ArrayList<Moments>(contours.size());
    
    for( int i = 0; i< contours.size(); i++) {   
      
      MatOfPoint c = contours.get(i);
      mu.add(i, Imgproc.moments(c, false));
      Moments p = mu.get(i);
      
      // hierarchy[][{0,1,2,3}]={next contour (same level), previous contour (same level), child contour, parent contour}
      // we only check the contours with a parent
      
      if(hierarchy.get(0,i)[3] != -1) {
        
        //if we would like to detect square we need to check the aspect ratio
        //however that limit markers in perspective. 
        //like this it's stable as well. 
        //Rectangle r = cont.getBoundingBox();
        //float aspect_ratio = float(r.width)/r.height;
        
        if(checkContourIsRectangle(c)) {
          
          foundRect = true;
          
          if(showDetection) {
            strokeWeight(5);
            stroke(0,0,255);
            
            beginShape();
            Point[] points = c.toArray();
            
            for (int j = 0; j < points.length; j++) {
              vertex((float)points[j].x, (float)points[j].y);
            }
            endShape();
          }

          int x = (int) (p.get_m10() / p.get_m00());
          int y = (int) (p.get_m01() / p.get_m00());
          
          markerColor = videoFrame.get(x,y);
          
          rectColorIndex = getClosestColorIndex(markerColor);
          
          if(showDetection) {
            fill(markerColor);
            noStroke();
            ellipse(x, y, 10, 10);
            noFill();
          }
          
        }
        else {
          if(showDetection) {
            strokeWeight(1);
            stroke(0, 255, 0);
          }
        }
      }
    }
  }
  
  public boolean frameHasMarker() {
    return foundRect;
  }
  
  public int foundColorIndex() {
    return rectColorIndex;
  }
  
  private boolean checkContourIsRectangle(MatOfPoint c) {
    
    boolean contourIsRect = false;
    
    //http://opencv-code.com/tutorials/detecting-simple-shapes-in-an-image/
    //https://code.google.com/p/scope-ocr/source/browse/trunk/+scope-ocr+--username+aravindh.shankar.91@gmail.com/Prototype/Scope/src/com/example/scope/EdgeDetection.java?r=22
    
    MatOfPoint2f approx = new MatOfPoint2f();
    MatOfPoint2f mMOP2f = new MatOfPoint2f(); 
    MatOfPoint   mMOP   = new MatOfPoint();
    
    c.convertTo(mMOP2f, CvType.CV_32FC2);
    Imgproc.approxPolyDP(mMOP2f, approx, Imgproc.arcLength(mMOP2f, true)*0.02, true);
    approx.convertTo(mMOP, CvType.CV_32S);
    
    // 4 points
    if( approx.rows()==4 && Imgproc.isContourConvex(mMOP) && Math.abs(Imgproc.contourArea(approx)) > 1000) 
    { 
      double maxcosine = 0;
      Point[] list = approx.toArray();
                              
      for (int j = 2; j < 5; j++) {
         double cosine =Math.abs(angle(list[j%4], list[j-2], list[j-1]));
         maxcosine = Math.max(maxcosine, cosine);
      }
                               
      if( maxcosine < 0.3 ) contourIsRect = true;
    }
    
    return contourIsRect;
  }
   
  private double angle( Point pt1, Point pt2, Point pt0 ) {
      double dx1 = pt1.x - pt0.x;
      double dy1 = pt1.y - pt0.y;
      double dx2 = pt2.x - pt0.x;
      double dy2 = pt2.y - pt0.y;
      return (dx1*dx2 + dy1*dy2)/Math.sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
  }
  
  // return the index number from our two arrays

  private int getClosestColorIndex(color inputColor) {
      
      int colorArrayIndex = -1; // not existing index 
      
      int closestColorDistance = 195075; // set this to the maximum distance, everything will be lower then
      
      for(int i = 0; i<colorHex.length; i++) {
         
         // check the distance from the input color, with the color from the array
         int thisColorDistance = calculateColorDistance(inputColor, colorHex[i]);
         
         // check if this is the closest if yes store it. 
         // if yes store it. 
         if(thisColorDistance < closestColorDistance) {
            closestColorDistance = thisColorDistance; 
            colorArrayIndex = i;
         }
      }
      
      return colorArrayIndex;  
  }

  // method used in the book learning Processing from Daniel Shiffman
  // another strategy might be simple comparing the hue of a color
  private int calculateColorDistance( int colour1, int colour2 ) 
  {
    int currR = (colour1 >> 16) & 0xFF; 
    int currG = (colour1 >> 8) & 0xFF;
    int currB = colour1 & 0xFF;
  
    int currR2 = (colour2 >> 16) & 0xFF; 
    int currG2 = (colour2 >> 8) & 0xFF;
    int currB2 = colour2 & 0xFF;
  
    int distance  = 0;
    distance += Math.pow(currR - currR2, 2);
    distance += Math.pow(currG - currG2, 2);
    distance += Math.pow(currB - currB2, 2);
    return distance ;
  }
}