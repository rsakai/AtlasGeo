import java.util.*;
import java.awt.Rectangle;

class Histogram{
  List<String> keys;
  List<Integer> values;
  boolean isIntKey = false;

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


  Histogram setup(int x, int y, int w, int h){
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
  void display(){
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
  void onPressed(int mx){
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
  void onDrag(int mx){
    if(isLeftSelected){
      handle_x_left = constrain(mx, rect.x, handle_x_right);
      //evaluate index_start
      index_start = constrain(round(map(mx, rect.x, rect.x+rect.width, 0, keys.size())), 0, index_end-1);
      // println("ind_start ="+index_start +"  index_end="+index_end);
    }else if(isRightSelected){
      handle_x_right = constrain(mx, handle_x_left, rect.x +rect.width);
      index_end = constrain(round(map(mx, rect.x, rect.x+rect.width, 0, keys.size())), index_start, keys.size());
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
  void onReleased(){
    handle_x_left = rect.x + (bar_width*index_start);
    handle_x_right = rect.x + (bar_width*index_end);
  }

  void resetFlags(){
    isLeftSelected = false;
    isRightSelected = false;
    isMiddleSelected = false;
  }

  //get active keys
  ArrayList<String> getActiveKeys(){
    ArrayList<String> result = new ArrayList<String>();
    for(int i = index_start; i < index_end; i++){
      result.add(keys.get(i));
    }
    return result;
  }
  //get inactive keys
  ArrayList<String> getInactiveKeys(){
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
boolean isIntegerKey(List<String> keys){
  for(String key:keys){
    if(!isNumeric(key)){
      return false;
    }
  }
  return true;
}

//checks if it is a number
boolean isNumeric(String str){
  Number num = null;
  try{
    num = Float.parseFloat(str);
  }catch(NumberFormatException e){
    return false;
  }
  return true;
}

// convert stringkeys to numeric keys
List<Integer> stringNumeric(List<String> inputList){
  List<Integer> output = new ArrayList(inputList.size());
  for(String val : inputList){
    output.add(Integer.parseInt(val));
  }
  return output;
}
