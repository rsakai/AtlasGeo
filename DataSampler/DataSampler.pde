import java.util.*;


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

void setup(){
 
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
  color c1 = color(100,0,0);
  color c2 = color(255,0,0);
  colourRange = generateColourRange(c1,c2,10);
  
  
  // Get Overlap Range
  highest = colourRange.length-1;
  
 
  // Init Rendering Buffer
  buffer = createGraphics(width, height, JAVA2D);
  redrawBuffer();

}


void draw(){
  
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


void mouseMoved(){
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

void mouseDragged(){
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


void mousePressed(){
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


void mouseReleased(){ 
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


void mouseWheel(MouseEvent event){
  map.mouseWheel(event.getAmount());
}
