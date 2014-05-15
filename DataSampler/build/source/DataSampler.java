import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.*; 
import com.mongodb.*; 
import com.mongodb.io.*; 
import com.mongodb.util.*; 
import com.mongodb.gridfs.*; 
import org.bson.*; 
import org.bson.io.*; 
import org.bson.util.*; 
import org.bson.types.*; 
import java.util.*; 
import java.awt.Rectangle; 
import com.modestmaps.*; 
import com.modestmaps.core.*; 
import com.modestmaps.geo.*; 
import com.modestmaps.providers.*; 

import org.bson.types.*; 
import com.mongodb.*; 
import com.mongodb.gridfs.*; 
import com.modestmaps.*; 
import com.mongodb.io.*; 
import org.bson.*; 
import org.bson.util.*; 
import com.modestmaps.core.*; 
import com.modestmaps.geo.*; 
import com.mongodb.util.*; 
import com.modestmaps.providers.*; 
import org.bson.io.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class DataSampler extends PApplet {




// Added this line for test

MongoDB m;
String ipAddress = "134.58.106.9";//"127.0.0.1";
String dbName = "atlas";
String colName = "compressors";


DraggableMap map;
int mapZoom = 1;
Location mapCentre = new Location(0,0);


int sleepTracker = 0;
int sleepThreshold = 120;
boolean isUpdate = true;


boolean isHist;
Map<String,Histogram> histograms;
Histogram active;


PGraphics buffer;
PImage render;
boolean isReplot;
int dotWeight = 3;
int highest;
int colourRange[];


Map<PVector,List<Map<String,Object>>> dots;







String[] fields = {
  "Warrenty",
  "Break Down Servicing",
  "Planned Servicing",
  "Fixed Price Servicing",
  "Product Status"
};

public void setup(){
 
  size(1024,720);
  background(0);
  
  
  // Init Map
  map = new DraggableMap(this, mapCentre, mapZoom);
  
  
  // Init MongoDB
  m = new MongoDB(ipAddress, dbName);
  m.setCollection(colName);


  // Init Histograms
  histograms = new LinkedHashMap();
  for(String fieldName : fields){
    List<Object> entries = m.getDistinct(fieldName);
    List<String> keys = new ArrayList();
    List<Integer> vals = new ArrayList();
    
    // Get Positive values
    for(Object o : entries){
      DBObject query = new BasicDBObject();
      query.put(fieldName, o);
      keys.add(o.toString());
      vals.add((int) m.getCount(query));
    }
    
    boolean isIntKey = isIntegerKey(keys);
    
    // Get N/A values
    DBObject query = new BasicDBObject(fieldName, BasicDBObjectBuilder.start("$exists", false).get());
    int NACount = (int) m.getCount(query);
    if(isIntKey){
      keys.add("0");
      vals.add(NACount);
    } else {
      keys.add("N/A");
      vals.add(NACount);
    }
    
    Histogram histogram = new Histogram(keys, vals, isIntKey);
    histograms.put(fieldName, histogram);
    histogram.name = fieldName;
  }


  int counter = 1;
  for(String fieldName : histograms.keySet()){
    Histogram h = (Histogram) histograms.get(fieldName);
    h.setup(50, 100 * counter, 250, 50);
    counter++;
    println(fieldName);
  }

 
  // Construct query
  BasicDBObject query = new BasicDBObject();
  query.put("loc", BasicDBObjectBuilder.start("$exists", true).get());


  // Query DB
  dots = new HashMap();
  DBCursor cursor = m.getData(query);
  println("Num Entries: " + cursor.size());
  
  
  // Parse Data
  while(cursor.hasNext()){
    cursor.next();
    DBObject curObj = cursor.curr();
    String serial = (String) curObj.get("serial");
    
    DBObject com = (DBObject) curObj.get("loc");
    float lat = getFloat(com,"lat");
    float lon = getFloat(com,"lon");
    PVector loc = new PVector(lat,lon);

    Map<String,Object> dot = new HashMap();
    dot.put("serial",serial);
    
    for(String fieldName : histograms.keySet()){
      Histogram hist = (Histogram) histograms.get(fieldName);
      if(curObj.containsField(fieldName)){
        Object obj = (Object) curObj.get(fieldName);
        if(obj instanceof Integer) {
          int val = (Integer) obj;
          dot.put(fieldName, val);
        } else {
          String val = (String) obj;
          dot.put(fieldName, val);
        }
      } else {
        if(hist.isIntKey){
          dot.put(fieldName, 0);
        } else {
          dot.put(fieldName, "N/A");
        }
      }
    }
    
    if(dots.containsKey(loc)){
      List<Map<String,Object>> dotList = (ArrayList) dots.get(loc);
      dotList.add(dot);
    } else {
      List<Map<String,Object>> dotList = new ArrayList();
      dotList.add(dot);      
      dots.put(loc,dotList);
    }
  }
  
  
  // Init Colour Spectrum
  int c1 = color(100,0,0);
  int c2 = color(255,0,0);
  colourRange = generateColourRange(c1,c2,10);
  
  
  // Get Overlap Range
  highest = colourRange.length-1;
  
 
  // Init Rendering Buffer
  buffer = createGraphics(width, height, JAVA2D);
  redrawBuffer();

}


public void draw(){
  
  if(sleepTracker >= sleepThreshold){
    isUpdate = false;
  }
  
  background(0);
//  tint(255, 255, 255, 130);
  map.draw();
  noTint();
  
  if(map.getWheelStatus() == 2){
    isReplot = true;
  }  
  
  if(isReplot){
    println("[Replot]");
    redrawBuffer();
    isReplot = false;
  }
  
  if(!map.isDrag() && map.getWheelStatus() != 1){
    image(render,0,0);
  }
  
  for(String fieldName : histograms.keySet()){
    Histogram h = (Histogram) histograms.get(fieldName);
    h.display();
  }
  
  if(!isUpdate){
    println("[Sleep]");
    noLoop();
  }
  
  sleepTracker++;
  
}


public void mouseMoved(){
  // Histogram
  cursor(ARROW);
  isHist = false;
  for(String fieldName : histograms.keySet()){
    Histogram h = (Histogram) histograms.get(fieldName);
    if(h.hover_area.contains(mouseX, mouseY)){
      cursor(HAND);
      isHist = true;
    }
  }
  // Wakeup mousemoved
  sleepTracker = 0;
  isUpdate = true;
  loop();
}

public void mouseDragged(){
  if(!isHist){
    // Map
    map.mouseDragged();
  } else {
    // Histogram
    if(active != null){
      active.onDrag(mouseX);
      // Wakeup mousemoved
      sleepTracker = 0;
      isUpdate = true;
      loop();
    }
  }
}


public void mousePressed(){
  // Histogram
  active = null;
  for(String fieldName : histograms.keySet()){
    Histogram h = (Histogram) histograms.get(fieldName);
    h.resetFlags();
  }
  if(isHist){
    for(String fieldName : histograms.keySet()){
      Histogram h = (Histogram) histograms.get(fieldName);
      if(h.hover_area.contains(mouseX, mouseY)){
        h.onPressed(mouseX);
        active = h;
      }
    }
  }
}


public void mouseReleased(){ 
  // Histogram
  if(isHist){
    if(active != null){
      active.onReleased();
      isReplot = true;
      println(active.getActiveKeys());
    }
    for(String fieldName : histograms.keySet()){
      Histogram h = (Histogram) histograms.get(fieldName);
      h.resetFlags();
    }
    active = null;
  }
  // Map
  if(map.isDrag()){
    isReplot = true;
  }
  map.mouseReleased();
}


public void mouseWheel(MouseEvent event){
  map.mouseWheel(event.getAmount());
}
public void redrawBuffer(){

  buffer.beginDraw();
  buffer.background(0,0,0,0);
  buffer.strokeWeight(dotWeight);
  buffer.stroke(255);
  
  Map<String,PVector> numericFields = new HashMap();
  Map<String,Set> textFields = new HashMap();
  
  for(String fieldName : histograms.keySet()){
    Histogram h = (Histogram) histograms.get(fieldName);
    List<String> activeKeys = h.getActiveKeys();
    boolean isNumeric = isNumeric(activeKeys.get(0));
    if(isNumeric){
      List<Integer> numericKeys = stringNumeric(activeKeys);
      int min = Collections.min(numericKeys);
      int max = Collections.max(numericKeys);
      PVector threshold = new PVector(min,max);
      numericFields.put(fieldName, threshold);
    } else {
      Set<String> active = new HashSet();
      for(String activeKey : activeKeys){
        active.add(activeKey);
      }
      textFields.put(fieldName,active);
    }
  }
  
  for(PVector loc : dots.keySet()){
    Location con = new Location(loc.x, loc.y);
    PVector pos = map.getScreenPosition(con);
    List<Map<String,Object>> dotList = (ArrayList) dots.get(loc);
    int numDots = 0;
    for(Map<String,Object> dot : dotList){
      boolean isValid = true;
      for(String fieldName : histograms.keySet()){
        Histogram hist = (Histogram) histograms.get(fieldName);
        if(dot.containsKey(fieldName)){
          if(numericFields.containsKey(fieldName)){
            PVector threshold = (PVector) numericFields.get(fieldName);
            int val = (Integer) dot.get(fieldName);
            if(val < threshold.x || val > threshold.y){
              isValid = false;
              break;
            }
          } else if(textFields.containsKey(fieldName)){
            Set<String> activeKeys = (HashSet) textFields.get(fieldName);
            String val = (String) dot.get(fieldName);
            if(!activeKeys.contains(val)){
              isValid = false;
              break;
            }
          }
        } else {
          isValid = false;
          break;
        }
      }
      if(isValid) numDots++;
    }
    if(numDots > 0){
      int colourRamp = (int) map(numDots, 1, highest, 0, colourRange.length-1);
      if(colourRamp > highest) colourRamp = highest;
      buffer.stroke(colourRange[colourRamp]);
      buffer.point(pos.x, pos.y);
    }
  }
  
  buffer.strokeWeight(1);
  buffer.endDraw();
  
  render = buffer.get();
  
}
public int[] generateColourRange(int inColor1, int inColor2, int inSize){
  
  int[] output = new int[inSize];
  for(int i=0; i<inSize; i++){
    float pos = map(i, 0, inSize, 0, 1);
    output[i] = lerpColor(inColor1, inColor2, pos);
  }
  return output;

}











class MongoDB {
  
  Mongo m;
  DB db;
  DBCollection c;
  
  MongoDB(String inputIP, String inputDBName){
    try {
      this.m = new Mongo( inputIP );
      this.db = this.m.getDB( inputDBName );
      System.out.println("**** Connection Successful");
    } catch (Exception e) {
      System.out.println("**** Connection Failed");
      exit();
    }
  }
  
  public void setCollection(String inputColName){
    try {
      this.c = this.db.getCollection(inputColName);
    }  catch (Exception e) {
      System.out.println("**** Connection Failed");
      System.out.println("**** Exit");
      exit();
    }
  }
  
  public DBCursor getData(DBObject inputQuery){
    return this.c.find(inputQuery);
  }
  
  public List<Object> getDistinct(String inputField){
    return this.c.distinct(inputField);
  }
  
  public long getCount(DBObject inputQuery){
    return this.c.count(inputQuery);
  }
  
}


public static float getFloat(DBObject obj, String inputKey){
  float floatVal = new Float(obj.get(inputKey).toString());
  return floatVal;
}



class Histogram{
  List<String> keys;
  List<Integer> values;
  boolean isIntKey = false;
  String name ="";

  int max_value = 0;
  int min_value = 0;

  int index_start = 0; //selected range
  int index_end = 0;

  Rectangle rect = null;
  Rectangle hover_area = null;
  float bar_width = 0f;
  float[] bar_height = null;
  int handle_height = 10;
  float handle_x_left = 0;
  float handle_x_right = 0; 
  float dist_to_left = 0; //distance to left handle

  //change color here
  int color_background = 60;
  int color_bar_selected = 200;
  int color_bar_unselected = 100;
  int color_text = color(25,230,255);
  int color_handle = 255;
  int color_blue = color(102, 217, 239);

  //flags
  boolean isLeftSelected = false;
  boolean isRightSelected = false;
  boolean isMiddleSelected = false;




  Histogram(List<String> keys, List<Integer> values, boolean isIntKey){
    this.keys = keys;
    this.values = values;
    this.isIntKey = isIntKey;
    //sort by keys
    ArrayList<String> temp = new ArrayList<String>(keys);
    Comparator<String> comparator = new KeyComp(isIntKey);
    Collections.sort(temp, comparator);
    for(int i = 0; i < keys.size(); i++){
      int new_index = keys.indexOf(temp.get(i));
      if(i != new_index){
        Collections.swap(keys, i, new_index);
        Collections.swap(values, i, new_index);
      }
    }
    //find max
    for(Integer i : values){
      max_value = max(i.intValue(), max_value);
    }
    //selected range
    index_start = 0;
    index_end = keys.size();

  }


  public Histogram setup(int x, int y, int w, int h){
    rect = new Rectangle(x, y, w, h);
    hover_area = new Rectangle(x, y - 10, w, 10);
    //bar width
    bar_width = (float) w / (float)keys.size();
    //bar height
    bar_height = new float[keys.size()];
    for(int i = 0; i < values.size(); i++){
      int value = values.get(i).intValue();
      bar_height[i] = map(value, min_value, max_value, 0, rect.height);
    } 

    //handle position
    handle_x_left = rect.x + (bar_width*index_start);
    handle_x_right = rect.x + (bar_width*index_end );
    return this;
  }

  //draw function
  public void display(){
    //background
    fill(color_background);
    noStroke();
    rect(rect.x, rect.y, rect.width, rect.height);

    //bars
    noStroke();
    float bar_x = rect.x;
    for(int i = 0; i < values.size(); i++){
      if(i >= index_start && i < index_end){
        fill(color_bar_selected);
      }else{
        fill(color_bar_unselected);
      }
      rect(bar_x, rect.y +rect.height- bar_height[i], bar_width, bar_height[i]);
      bar_x += bar_width;
    }

    //x axis
    fill(color_text);
    noStroke();
    float runningX = rect.x + bar_width/2;
    float runningY = rect.y + rect.height;
    for(int i = 0; i < keys.size(); i++){
      String label = keys.get(i);
      //rotating label if it is too long
      if(textWidth(label)+10 > bar_width){
        if(label.length()>10){ 
          label = label.substring(0,9)+"...";
        }
        pushMatrix();
        translate(runningX, runningY);
        rotate(- HALF_PI/2);
        textAlign(RIGHT, CENTER);
        text(label, 0, 0);
        popMatrix();
      }else{
        textAlign(CENTER, TOP);
        text(label, runningX, runningY);
      }
      runningX += bar_width;
    }

    //y axis
    fill(color_text);
    noStroke();
    runningX = rect.x;
    runningY = rect.y + rect.height;
    //min
    textAlign(RIGHT, BOTTOM);
    text(min_value, runningX, runningY);
    //max
    textAlign(RIGHT, TOP);
    runningY -= rect.height;
    text(max_value, runningX, runningY);
    //field name
    textAlign(RIGHT, BOTTOM);
    fill(color_background);
    text(name, rect.x+rect.width, rect.y);

    //draw selected range
    stroke(color_handle);
    line(handle_x_left, rect.y - handle_height, handle_x_left, rect.y + rect.height);
    line(handle_x_right, rect.y - handle_height, handle_x_right, rect.y + rect.height);

    //mouse hovering
    if(hover_area.contains(mouseX, mouseY)){
      if(isMiddleSelected){
        //range is selected
        noStroke();
        fill(color_blue);
        rect(handle_x_left, hover_area.y, (index_end-index_start)*bar_width, hover_area.height);
      }else{
        //draw triangle
        //left
        noStroke();
        fill(abs(mouseX - handle_x_left)< handle_height || isLeftSelected ? color_blue: color_handle);
        triangle(handle_x_left, hover_area.y, handle_x_left, hover_area.y+hover_area.height, handle_x_left+ handle_height, (float)hover_area.getCenterY());
        //right
        fill(abs(mouseX - handle_x_right)< handle_height || isRightSelected ? color_blue: color_handle);
        triangle(handle_x_right, hover_area.y, handle_x_right, hover_area.y+hover_area.height, handle_x_right - handle_height, (float)hover_area.getCenterY());        
      }

    }
  }

  //check if clicked near the handle
  public void onPressed(int mx){
    if(abs(mx - handle_x_left)< handle_height){
      isLeftSelected = true;
    }else if( abs(mx - handle_x_right)< handle_height){
      isRightSelected = true;
    }else{
      isMiddleSelected = true;
      dist_to_left = mx - handle_x_left; // how far from left handle
    }
  }

  //while dragging, evaluate the position of handle
  public void onDrag(int mx){
    if(isLeftSelected){
      handle_x_left = constrain(mx, rect.x, handle_x_right);
      //evaluate index_start
      index_start = constrain(round(map(mx, rect.x, rect.x+rect.width, 0, keys.size())), 0, index_end-1);
      // println("ind_start ="+index_start +"  index_end="+index_end);
    }else if(isRightSelected){
      handle_x_right = constrain(mx, handle_x_left, rect.x +rect.width);
      index_end = constrain(round(map(mx, rect.x, rect.x+rect.width, 0, keys.size())), index_start+1, keys.size());
      // println("ind_end ="+index_end);
    }else if(isMiddleSelected){
      //check the range
      int range = index_end- index_start;
      if(range < keys.size()){
        //slide
        handle_x_left = constrain(mx - dist_to_left, rect.x, rect.x+rect.width-(range*bar_width));
        index_start = constrain(round(map(handle_x_left, rect.x, rect.x+rect.width, 0, keys.size())), 0, keys.size()-range);
        index_end = index_start + range;
        handle_x_right = handle_x_left + range*bar_width;  
        // println("debug: range = "+range + " start:"+index_start+ "  end:"+index_end);    
      }
    }
  }

  //update handle posision
  public void onReleased(){
    handle_x_left = rect.x + (bar_width*index_start);
    handle_x_right = rect.x + (bar_width*index_end);
  }

  public void resetFlags(){
    isLeftSelected = false;
    isRightSelected = false;
    isMiddleSelected = false;
  }

  //get active keys
  public ArrayList<String> getActiveKeys(){
    ArrayList<String> result = new ArrayList<String>();
    for(int i = index_start; i < index_end; i++){
      result.add(keys.get(i));
    }
    return result;
  }
  //get inactive keys
  public ArrayList<String> getInactiveKeys(){
    ArrayList<String> result = new ArrayList<String>();
    for(int i = 0; i < index_start; i++){
      result.add(keys.get(i));
    }
    for(int i = index_end; i < keys.size(); i++){
      result.add(keys.get(i));
    }
    return result;
  }
}



class KeyComp implements Comparator<String>{
  boolean isInt = false;
  KeyComp(boolean b){
    this.isInt = b;
  }
  public int compare(String s1, String s2){
    if(isInt){
      int v1 = Integer.parseInt(s1);
      int v2 = Integer.parseInt(s2);
      return v1 - v2;
    }else{
      return s1.compareTo(s2);
    }
  }
}


//check if the key is Integer
public boolean isIntegerKey(List<String> keys){
  for(String key:keys){
    if(!isNumeric(key)){
      return false;
    }
  }
  return true;
}

//checks if it is a number
public boolean isNumeric(String str){
  Number num = null;
  try{
    num = Float.parseFloat(str);
  }catch(NumberFormatException e){
    return false;
  }
  return true;
}

// convert stringkeys to numeric keys
public List<Integer> stringNumeric(List<String> inputList){
  List<Integer> output = new ArrayList(inputList.size());
  for(String val : inputList){
    output.add(Integer.parseInt(val));
  }
  return output;
}






class DraggableMap {

  InteractiveMap map;
  
  boolean isDrag = false;
  
  double tx;
  double ty;
  double sc;
  
  int wheelTracker = 0;
  int frameTracker = 0;
  
  DraggableMap(PApplet inApplet, Location inCentre, int inZoom){
    String template = "http://c.tiles.mapbox.com/v3/examples.map-szwdot65/{Z}/{X}/{Y}.png";
    String[] subdomains = new String[] { "otile1", "otile2", "otile3", "otile4" };
    this.map = new InteractiveMap(inApplet, new TemplatedMapProvider(template, subdomains));
    this.map.setCenterZoom(new Location(51.230054f, 4.413371f), 9);
  }
  
  public void draw(){
    this.wheelStatus();
    this.map.draw();
  }
  
  public void wheelStatus(){
    if(this.wheelTracker == 2){
      this.wheelTracker = 0;
    } else if(this.wheelTracker == 1){
      if((frameTracker + (frameRate/2)) < frameCount){
        this.wheelTracker = 2;
      }
    }
  }
  
  public void mouseMoved(){
    sleepTracker = 0;
  }

  public void mouseDragged(){
    this.isDrag = true;
    this.map.mouseDragged();
  }
  
  public void mouseReleased(){
    if(this.isDrag){
      this.isDrag = false;
    }
  }
  
  public void mouseWheel(float inDelta){
    this.wheelTracker = 1;
    this.frameTracker = frameCount;
    
    float threshold = 1.0f;
    if (inDelta < 0) {
      threshold = 1.05f;
    } else if (inDelta > 0) {
      threshold = 1.0f/1.05f; 
    }
    
    float mx = mouseX - width/2;
    float my = mouseY - height/2;
    this.map.tx -= mx/this.map.sc;
    this.map.ty -= my/this.map.sc;
    this.map.sc *= threshold;
    this.map.tx += mx/this.map.sc;
    this.map.ty += my/this.map.sc;
  }
  
  public boolean isDrag(){
    return this.isDrag;
  }
  
  public int getWheelStatus(){
    return this.wheelTracker;
  }
  
  public PVector getScreenPosition(Location inputLoc){
    Point2f point = this.map.locationPoint(inputLoc);
    PVector output = new PVector(point.x, point.y);
    return output;
  }
  
}
public Map sortByEntry(Map unsortMap) {
  List list = new LinkedList(unsortMap.entrySet());
  Collections.sort(list, new Comparator() {
    public int compare(Object o1, Object o2) {
      return ((Comparable) ((Map.Entry) (o1)).getValue()).compareTo(((Map.Entry) (o2)).getValue());
    }
  }
  );
  Map sortedMap = new LinkedHashMap();
  for (Iterator it = list.iterator(); it.hasNext();) {
    Map.Entry entry = (Map.Entry) it.next();
    sortedMap.put(entry.getKey(), entry.getValue());
  }
  return sortedMap;
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "DataSampler" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
