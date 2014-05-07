// Geolocate with OSM Nominatim

import java.util.*;

import java.net.URLEncoder;

import org.apache.commons.io.IOUtils;

import com.mongodb.*;
import com.mongodb.io.*;
import com.mongodb.util.*;
import com.mongodb.gridfs.*;

import org.bson.*;
import org.bson.io.*;
import org.bson.util.*;
import org.bson.types.*;

Mongo m;
DB db;
DBCollection master;


Map<String,List<DBObject>> data;
int counter = 0;
int limit = 2000;

void setup(){
 
  try {
    m = new Mongo( "127.0.0.1", 27017 );
    db = m.getDB("atlas");
    master = db.getCollection("compressors");
    System.out.println("**** Connection Successful");
  } catch (Exception e) {
    System.out.println("**** Connection Failed");
    exit();
  }
  
  data = new HashMap();
  
  DBObject query = new BasicDBObject("loc",BasicDBObjectBuilder.start("$exists", false).get());
  DBCursor cursor = master.find(query);
  
  while (cursor.hasNext ()) {
    cursor.next();
    DBObject curObj = cursor.curr();
    String address = (String) curObj.get("Address");
    if(data.containsKey(address)){
      List<DBObject> dbObjs = (ArrayList) data.get(address);
      dbObjs.add(curObj);
    } else {
      List<DBObject> dbObjs = new ArrayList();
      dbObjs.add(curObj);
      data.put(address,dbObjs);
    }
  }
  
  println(data.size());
  
  for(String addr : data.keySet()){
    if(counter > limit) break;
    float[] loc = getLocation(addr);
    if(loc != null){
      if(loc[0] != 0.0 && loc[1] != 0.0){
        println(addr);
        DBObject location = new BasicDBObject();
        location.put("lat",loc[0]);
        location.put("lon",loc[1]);
        List<DBObject> storage = (ArrayList<DBObject>) data.get(addr);
        for(DBObject obj : storage){
          master.update(obj, new BasicDBObject("$set", new BasicDBObject("loc",location)));
        }
        counter++;
      } else {
        println("* - " + addr);
      }
    }
    
    delay(3000);
  }
  
  exit();
  
}



JSONArray geoLocate(String address){
  String URL = "http://nominatim.openstreetmap.org/search.php?q=";
  String encoded = null;
  try {
    encoded = URLEncoder.encode(address, "UTF-8");
  } catch (Exception e){
  }
  if(encoded != null){
    JSONArray output = loadJSONArray(URL + encoded + "&format=json");
    return output;
  } else {
    return null;
  }
}


float[] getLocation(String address){
  JSONArray res = geoLocate(address);
  if(res != null && res.size() > 0){
    float[] pos = new float[2];
    JSONObject geoCode = res.getJSONObject(0);
    pos[0] = geoCode.getFloat("lat");
    pos[1] = geoCode.getFloat("lon");
    return pos;
  } else {
    return null;
  }
}
