/* @pjs preload="black-world-map.jpg"; */

int num = 60;
float mouseStartX;
float mouseStartY;
float mouseEndX;
float mouseEndY;
int MOUSE_RESOLUTION = 10;
int BUCKET_MS = 50;
int RUN_IN_TIME = 1000;
color START_COLOR = color(200,200,0);
color END_COLOR = color(255,0,0);
ArrayList calls;
float lastBucket;
PImage bg;

int[] popXs = {320+57,550+38,1123,980};
int[] popYs = {360-62,160+73,567,335};

int[] spoints = {0,0,0,0};
int[] epoints = {0,0,0,0};
  
int bucketize(float time) {
  return int(time/BUCKET_MS)*BUCKET_MS;
}

void setup() {
  size(1280, 720);
  frameRate(45);
  bg = loadImage("black-world-map.jpg");
  calls = new ArrayList();
}

void draw() {
  background(bg);
  stroke(196);
  float time = millis();
  float curBucket = bucketize(time);
  text(""+int(frameRate)+"fps "+calls.size(), 5,15);
  if (time < RUN_IN_TIME) {
    return;
  }
  if (curBucket != lastBucket) {
      lastBucket = curBucket;
      if (calls.size() < 200) {
        for (int ix = int(random(0,8.0)); ix >= 0; ix--) {
          startPop = int(sqrt(random(0,16.0)));
          endPop = (1+int(sqrt(random(0,16.0))))%4;
          calls.add(new PhoneCall(millis(), startPop, endPop));
          spoints[startPop] += 1;
          epoints[endPop] += 1;
        }
      }
  }
  
  for(int jx=0; jx<4; jx ++) {
    noFill();
    stroke(START_COLOR,96);
    strokeWeight(5);
    ellipse(popXs[jx],popYs[jx],spoints[jx],spoints[jx]);
    strokeWeight(1);
    stroke(START_COLOR);
    ellipse(popXs[jx],popYs[jx],spoints[jx],spoints[jx]);
    stroke(END_COLOR,96);
    strokeWeight(5);
    ellipse(popXs[jx],popYs[jx],epoints[jx],epoints[jx]);
    strokeWeight(1);
    stroke(END_COLOR);
    ellipse(popXs[jx],popYs[jx],epoints[jx],epoints[jx]);
  }
  
  //draw call  
  for (int ix=0; ix<calls.size(); ix++) {
    PhoneCall call = (PhoneCall) calls.get(ix);
    call.update();
    if (call.finished()) {
      spoints[call.startPop] -= 1;
      epoints[call.endPop] -= 1;
      calls.remove(ix);
    }
    
  }
  
  // Save Movie Frame
  //saveFrame("fountain-####.tif"); 
}

class PhoneCall {
  float stime, sx, sy, ex, ey;
  float bezSx, bezSy, bezEx, bezEy;
  int draws = 0;
  int startPop, endPop;
  int MAX_DRAWS = 160;
  int BALL_WIDTH = 5;
  color curColor;
  
  PhoneCall(float a, int b, int c) {
    stime = a;
    startPop = b;
    endPop = c;
    sx = popXs[startPop];
    sy = popYs[startPop];
    ex = popXs[endPop];
    ey = popYs[endPop];
    MAX_DRAWS = int(160.0*frameRate/60.0);
    if (sx==ex && sy ==ey) {
      bezSx = -40.0-random(0,20.0);
      bezEx = 40.0+random(0,20.0);
      bezEy = 40.0+random(0,20.0);
      bezSy = 40.0+random(0,20.0);      
    } else {
      bezSx = 0.0;
      bezEx = 0.0;
      bezEy = random(-20,0) - 100.0;
      bezSy = random(-20,0) - 100.0;
    }
  }
  
  void update() {
    //noFill();
    //stroke(START_COLOR);
    //ellipse(sx,sy,BALL_WIDTH,BALL_WIDTH);
    //stroke(END_COLOR);
    //ellipse(ex,ey,BALL_WIDTH,BALL_WIDTH);
    // Calculate the current progress from 0.0 to 1.0.      
      float progress = draws / MAX_DRAWS;
      float tail = max(0.0, progress - 0.1);
      curColor = lerpColor(START_COLOR, END_COLOR, progress);
      //stroke(curColor);
      //bezier(sx,sy,sx+bezSx,sy+bezSy,ex+bezEx,ey+bezEy, ex, ey);
    
      // Calculate the 'call' dot position.
      float bezX = bezierPoint(sx,sx+bezSx, ex+bezEx, ex, progress);
      float bezY = bezierPoint(sy,sy+bezSy, ey+bezEy, ey, progress);
      // Calculate tail end.
      float tailX = bezierPoint(sx,sx+bezSx, ex+bezEx, ex, tail);
      float tailY = bezierPoint(sy,sy+bezSy, ey+bezEy, ey, tail);
      stroke(curColor);
      fill(curColor);
      ellipse(bezX,bezY, BALL_WIDTH, BALL_WIDTH);
      line(tailX, tailY, bezX, bezY);
    
    draws += 1;
  }
  
  
  boolean finished() {
    return (draws > MAX_DRAWS);
  }

}

