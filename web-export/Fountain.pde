/* @pjs preload="black-world-map.jpg"; */

/* ideas!

- export to VIDEO!? re-write in java to use saveFrame() function?

- Implement a "Nossle" class for ingress and egress...

   ------>  target
           pushed left and right by adjacent 

- have the red call dot terminate at the red circle, originate at the yellow.
  - almost. Fix the tails! Fix the loopbacks!
- max size of conc call rings.
- autocalculate spline directions for each adjacent pop, and adjust based on popularity of route.
- fading trails?
- experiment with adjustable lengths of call  (lognormal dist)
- play with mixed mode VoIP/TDM
- try adding text for total concurrent next to POP?  TDM 100:300   (in:out)

*/


int num = 60;
float mouseStartX;
float mouseStartY;
float mouseEndX;
float mouseEndY;
int MOUSE_RESOLUTION = 10;
int BUCKET_MS = 50;
int RUN_IN_TIME = 500;
int SEED_RATE = 10;
color SELECTED_COLOR = color(128,255,128);
color START_COLOR = color(200,200,0);
color END_COLOR = color(255,0,0);
ArrayList messages;
float lastBucket;
PImage bg;

Hub[] hubs = {new Hub(377,298,"NY"),
              new Hub(588,233,"LDN"),
              new Hub(1123,567,"HK"),
              new Hub(980,335,"SYD")};

int[][] sControlX = { {-40,0,  70,  40}, 
                      {-70,-40,  0,  0},
                      {-100,  0,-40,  70},
                      {-100,  0,  100,-40}  };
int[][] sControlY = { {-40,-100,70,-40}, 
                      {-70,40,-100,-100},
                      {0,-100,40,-70},
                      {0,-100,-100,40}  };
int[][] eControlX = { {-40, 0,-70, -40}, 
                      {30, 40,  0,  0},
                      {0,100, 40,  100},
                      {100,  0,  100, 40}  };
int[][] eControlY = { {40,-100,-70,-40}, 
                      {-70,40,-100,-100},
                      {100,0,40,0},
                      {0,-100,0,40}  };

// int[] spoints = {0,0,0,0};
// int[] epoints = {0,0,0,0};
  
int bucketize(float time) {
  return int(time/BUCKET_MS)*BUCKET_MS;
}

void setup() {
  size(1280, 720);
  frameRate(45);
  bg = loadImage("black-world-map.jpg");
  messages = new ArrayList();
}

void draw() {
  if (mousePressed) {
    for (int ix = 0; ix < hubs.length; ix++) {
      h = hubs[ix];
      if (dist(mouseX, mouseY, h.x, h.y) < 50) {
        h.toggle_select();
        return;
      }
    }
  }  
  background(bg);
  stroke(196);
  float time = millis();
  float curBucket = bucketize(time);
  text(""+int(frameRate)+"fps "+messages.size(), 5,15);
  if (time < RUN_IN_TIME) {
    return;
  }
  if (curBucket != lastBucket) {
    lastBucket = curBucket;
    if (messages.size() < 200) {
      for (int ix = int(random(0,SEED_RATE)); ix >= 0; ix--) {
        startHub = (int(time/5000)+int(sqrt(random(0,16.0))))%4;
        endHub = (int(time/10000)+int(sqrt(random(0,16.0))))%4;
        messages.add(new Message(millis(), startHub, endHub));
      }
    }
  }
  
  //draw hubs
  for(int jx=0; jx<4; jx ++) {
    hubs[jx].drawHub();
  }
  
  //draw message
  for (int ix=0; ix<messages.size(); ix++) {
    Message message = (PhoneCall) messages.get(ix);
    message.update();
    if (message.finished()) {
      message.untrack();
      messages.remove(ix);
    }
  }
}

class Hub {
  int x,y;
  int ingress,egress;
  ArrayList ingressHistory, egressHistory;
  int HIST_MEM = 40;
  String name;
  boolean selected;

  Hub(int a, int b, String n) {
    x = a;
    y = b;
    name = n;
    ingress = 0;
    egress = 0;
    ingressHistory = new ArrayList();
    egressHistory = new ArrayList();
    selected = false;
  }

  void drawHub() {
    noFill();
    strokeWeight(1);
    
    // Calculate history
    egressHistory.add(egress);
    ingressHistory.add(ingress);
    if (egressHistory.size() > HIST_MEM) {
      egressHistory.remove(0);
      ingressHistory.remove(0);
    }

    //draw bold rings for current egress/ingress
    strokeWeight(1);

    stroke(START_COLOR);
    ellipse(x,y,egress,egress);
    
    stroke(END_COLOR);
    ellipse(x,y,ingress,ingress);

    // Draw rings historic ingress/egress
    for (int ex=egressHistory.size()-1; ex>=1; ex-=1){
       // Draw historical egress circles, interpolating between historical points.
      int hist_egress = egressHistory.get(ex);
      int hist_egress_older = egressHistory.get(ex-1);
      float hist_egress_interp = (hist_egress + hist_egress_older) / 2;
      stroke(START_COLOR, int(20*(ex/HIST_MEM)*(ex/HIST_MEM)));
      strokeWeight(abs(hist_egress - hist_egress_older)*2);
      ellipse(x, y, hist_egress_interp, hist_egress_interp);
      
       // Draw historical ingress circles, interpolating between historical points.
      int hist_ingress = ingressHistory.get(ex);
      int hist_ingress_older = ingressHistory.get(ex-1);
      float hist_ingress_interp = (hist_ingress + hist_ingress_older) / 2;
      stroke(END_COLOR, int(20*(ex/HIST_MEM)*(ex/HIST_MEM)));
      strokeWeight(abs(hist_ingress - hist_ingress_older)*2);
      ellipse(x, y, hist_ingress_interp, hist_ingress_interp);
    }

    // If selected, draw a circle around the hub
    if (selected) {
      stroke(SELECTED_COLOR);
      strokeWeight(2);
      ellipse(x,y,10,10);
    }
  }

  void toggle_select() {
    if (selected == false) {
      selected = true;
    } else {
      selected = false;
    }
  }
}

class Message {
  float stime, sx, sy, ex, ey;
  int sHubIx,eHubIx;
  float bezSx, bezSy, bezEx, bezEy;
  int draws = 0;
  int MAX_DRAWS = 160;
  int BALL_WIDTH = 2;
  color curColor;
  Hub sHub,eHub;
  
  Message(float st, int sh, int eh) {
    stime = st;
    sHub = hubs[sh];
    sHubIx = sh;
    sHub.egress += 1;
    eHub = hubs[eh];
    eHubIx = eh;
    eHub.ingress += 1;
    sx = sHub.x;
    sy = sHub.y;
    ex = eHub.x;
    ey = eHub.y;
    MAX_DRAWS = int(160.0*frameRate/60.0);
    bezSx = sControlX[sHubIx][eHubIx]*random(1.0,1.2);
    bezEx = eControlX[sHubIx][eHubIx]*random(1.0,1.2);
    bezEy = eControlY[sHubIx][eHubIx]*random(1.0,1.2);
    bezSy = sControlY[sHubIx][eHubIx]*random(1.0,1.2);
  }
  
  void update() {
    float progress = draws / MAX_DRAWS;
    // Calculate the 'call' dot position.
    float bezX = bezierPoint(sHub.x,sHub.x+bezSx, eHub.x+bezEx, eHub.x, progress);
    float bezY = bezierPoint(sHub.y,sHub.y+bezSy, eHub.y+bezEy, eHub.y, progress);
    
    //only draw the call if it's outside the start/end rings
    if (dist(bezX,bezY,sHub.x,sHub.y) > (sHub.egress / 2)  &&
        dist(bezX,bezY,eHub.x,eHub.y) > (eHub.ingress / 2)) {
          
      // Calculate tail1 end.
      float tail1 = max(0.0, progress - 0.025);
      float tail1X = bezierPoint(sHub.x,sHub.x+bezSx, eHub.x+bezEx, eHub.x, tail1);
      float tail1Y = bezierPoint(sHub.y,sHub.y+bezSy, eHub.y+bezEy, eHub.y, tail1);
      // Calculate tail2 end.
      float tail2 = max(0.0, progress - 0.05);
      float tail2X = bezierPoint(sHub.x,sHub.x+bezSx, eHub.x+bezEx, eHub.x, tail2);
      float tail2Y = bezierPoint(sHub.y,sHub.y+bezSy, eHub.y+bezEy, eHub.y, tail2);      
      curColor = lerpColor(START_COLOR, END_COLOR, progress);
      stroke(curColor);
      strokeWeight(1);
      fill(curColor);
      ellipse(bezX,bezY, BALL_WIDTH, BALL_WIDTH);
      stroke(curColor, 128);
      line(tail1X, tail1Y, bezX, bezY);
      stroke(curColor, 64);
      line(tail2X, tail2Y, tail1X, tail1Y);
    }

    draws += 1;
  }

  void untrack() {
    sHub.egress -= 1;
    eHub.ingress -= 1;
  }

  boolean finished() {
    return (draws > MAX_DRAWS);
  }
}
