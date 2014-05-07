import com.mongodb.*;
import com.mongodb.io.*;
import com.mongodb.util.*;
import com.mongodb.gridfs.*;

import org.bson.*;
import org.bson.io.*;
import org.bson.util.*;
import org.bson.types.*;


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
  
  void setCollection(String inputColName){
    try {
      this.c = this.db.getCollection(inputColName);
    }  catch (Exception e) {
      System.out.println("**** Connection Failed");
      System.out.println("**** Exit");
      exit();
    }
  }
  
  DBCursor getData(DBObject inputQuery){
    return this.c.find(inputQuery);
  }
  
  List<Object> getDistinct(String inputField){
    return this.c.distinct(inputField);
  }
  
  long getCount(DBObject inputQuery){
    return this.c.count(inputQuery);
  }
  
}


static float getFloat(DBObject obj, String inputKey){
  float floatVal = new Float(obj.get(inputKey).toString());
  return floatVal;
}
