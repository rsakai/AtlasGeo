color[] generateColourRange(color inColor1, color inColor2, int inSize){
  
  color[] output = new color[inSize];
  for(int i=0; i<inSize; i++){
    float pos = map(i, 0, inSize, 0, 1);
    output[i] = lerpColor(inColor1, inColor2, pos);
  }
  return output;

}
