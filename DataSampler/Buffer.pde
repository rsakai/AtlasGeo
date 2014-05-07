void redrawBuffer(){

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
