import com.modestmaps.*;
import com.modestmaps.core.*;
import com.modestmaps.geo.*;
import com.modestmaps.providers.*;


class DraggableMap {

  InteractiveMap map;
  
  boolean isDrag = false;
  
  double tx;
  double ty;
  double sc;
  
  int wheelTracker = 0;
  int frameTracker = 0;
  
  DraggableMap(PApplet inApplet, Location inCentre, int inZoom){
    this.map = new InteractiveMap(inApplet, new Microsoft.AerialProvider());
    this.map.setCenterZoom(inCentre, inZoom);      
  }
  
  void draw(){
    this.wheelStatus();
    this.map.draw();
  }
  
  void wheelStatus(){
    if(this.wheelTracker == 2){
      this.wheelTracker = 0;
    } else if(this.wheelTracker == 1){
      if((frameTracker + (frameRate/2)) < frameCount){
        this.wheelTracker = 2;
      }
    }
  }
  
  void mouseMoved(){
    sleepTracker = 0;
  }

  void mouseDragged(){
    this.isDrag = true;
    this.map.mouseDragged();
  }
  
  void mouseReleased(){
    if(this.isDrag){
      this.isDrag = false;
    }
  }
  
  void mouseWheel(float inDelta){
    this.wheelTracker = 1;
    this.frameTracker = frameCount;
    
    float threshold = 1.0;
    if (inDelta < 0) {
      threshold = 1.05;
    } else if (inDelta > 0) {
      threshold = 1.0/1.05; 
    }
    
    float mx = mouseX - width/2;
    float my = mouseY - height/2;
    this.map.tx -= mx/this.map.sc;
    this.map.ty -= my/this.map.sc;
    this.map.sc *= threshold;
    this.map.tx += mx/this.map.sc;
    this.map.ty += my/this.map.sc;
  }
  
  boolean isDrag(){
    return this.isDrag;
  }
  
  int getWheelStatus(){
    return this.wheelTracker;
  }
  
  PVector getScreenPosition(Location inputLoc){
    Point2f point = this.map.locationPoint(inputLoc);
    PVector output = new PVector(point.x, point.y);
    return output;
  }
  
}
