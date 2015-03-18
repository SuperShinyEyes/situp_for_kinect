import guru.ttslib.*;
import KinectPV2.KJoint;
import KinectPV2.*;

//text to speech
TTS tts;

// kinect class
KinectPV2 kinect;

//skeleton recognition and status messages (debug)
Skeleton [] skeleton;

Skeleton closestSkeleton;
boolean someoneIsSitting = false;
boolean someoneLeftseat = true;

float zVal = 300;
float rotX = PI;

String message = "";             // Debugging purpose
String postureMessage = "";      // Are you sitting in good posture or not?
String sittingTimeMessage = "";  // Describes how long you've been sitting for
int secondWhenStartedSitting = 0;
int minuteWhenStartedSitting = 0;
int hourWhenStartedSitting = 0;
int sittingTimeTotalSecond = 0;

//GUI element images
PImage bg;
PImage buttonImg;
PImage buttonHover;
boolean hoverOver;

//GUI element variables
int BImgX, BImgY;
int rectX, rectY;      // Position of square button
int rectSize = 90;   
color rectColor, baseColor;



void setup() {
  size(1024, 700, P3D);
    
  hoverOver = false;
  bg = loadImage("situp-window-3-background.jpg");
  buttonImg = loadImage("close-button-1.png");
  buttonHover = loadImage("close-button-2.png");
  
  BImgX = width/2 - buttonImg.width/2;
  BImgY = height - (buttonImg.height/2 * 3);
  
  //Rectangle options to be changed into a picture
  rectX = width/2-rectSize-10;
  rectY = height/2-rectSize/2;
 
  tts = new TTS();

  kinect = new KinectPV2(this);

  kinect.enableColorImg(true);

  kinect.enableSkeleton(true );
  //enable 3d Skeleton with (x,y,z) position
  kinect.enableSkeleton3dMap(true);

  kinect.init();
}

void draw() {
  
  //background and buttons
  background(bg);
  
  if(hoverOver){
    image(buttonHover, BImgX, BImgY);
  }else{
    image(buttonImg, BImgX, BImgY);
  }
  
  if (mouseX > BImgX && mouseX < BImgX + buttonImg.width && mouseY > BImgY && mouseY < BImgY + buttonImg.height) {
      hoverOver = true;
  } else {
      hoverOver = false;
  }

  image(kinect.getColorImage(), width-(width/3), height-(height/3), width/3, height/3);

  skeleton =  kinect.getSkeleton3d();

  //translate the scene to the center 
  pushMatrix();
  translate(width/2, height/2, 0);
  scale(zVal);
  rotateX(rotX);

  // This should always be false in the beginning.
  // Otherwise there will always be old skeleton even though there is no one.
  someoneIsSitting = false; 
  /* Observe only one person. By default, Kinect tries to detect six people.
   * As you can see the following for-loop, skeleton array is always length of more than one
   * at any time. When there is no one, the array will be filled with null.
   * We try to observe the person the person that is nearest to Kinect. */
  for (int i = 0; i < skeleton.length; i++) {
       if (skeleton[i].isTracked()) {
          if(!someoneIsSitting) { closestSkeleton = skeleton[i]; }
          else{ updateClosest(skeleton[i]); }
          someoneIsSitting = true;
       }
  }

  if (someoneIsSitting) {
      KJoint[] joints = closestSkeleton.getJoints();

      //Draw body
      color col  = getIndexColor(0);
      stroke(col);
      drawBody(joints);
      checkPosture(joints);
  } else {
    postureMessage = "Waiting to recognize";
  }
  popMatrix();
  if (postureMessage.equals("Good posture!")) {
     //If posture is good, text is green (acceptable)
     fill(0,255,0);
  } else {
     //If there is something wrong with posture, text will be red.
     fill(255, 0, 0);
  }
  //text(frameRate, 50, 50);
  //text(message, 50,300);
  textSize(26);
  text(postureMessage, width-(width/3), height-(height/2));
  /* !!ATTENTION!!
   * The following conditions should be located at the very end of this function!
   * Otherwise it won't be able to detect empty seat. Seyoung doesn't know why. */
  // Write time on the display
 
  if(someoneIsSitting){
    checkSittingTime();
    fill(0,0,0);
    text(sittingTimeMessage, width-(width/3), height-(height/3) - 50);
  }else{
    someoneLeftseat = true;
    postureMessage = "";
  }
}

boolean isNoOneSitting(){ return closestSkeleton == null; }

void checkSittingTime(){
  // Records the initial time when you sitted. The time counting will be based on this record.
  // I initially tried to get only "second" data but not this is the most reliable but a good way
  // to record each time unit.
  if(someoneLeftseat){
    hourWhenStartedSitting = hour();
    minuteWhenStartedSitting = minute();
    secondWhenStartedSitting = second();
    someoneLeftseat = false;
  }
  // For the demonstration purpose, show "second".
  sittingTimeTotalSecond = (hour() - hourWhenStartedSitting) * 3600 + (minute() - minuteWhenStartedSitting) * 60 + (second() - secondWhenStartedSitting);
  sittingTimeMessage = "You've been sitting \nfor " + sittingTimeTotalSecond + " seconds.";
}

void updateClosest(Skeleton newSkeleton) {
    KJoint[] newJoints = newSkeleton.getJoints();
    KJoint[] closestJoints = closestSkeleton.getJoints();
  
    if(closestJoints[KinectPV2.JointType_Head].getZ() > newJoints[KinectPV2.JointType_Head].getZ()) {
      closestSkeleton = newSkeleton;
    }
}

void mousePressed() {
    if(hoverOver){
        exit(); 
    }
}

void postureNotification(boolean goodPosture) {
 if (goodPosture) {
  tts.speak("Good posture!");
 } else {
  tts.speak("Bad posture, sit straight!"); 
 }
}

//use different color for each skeleton tracked
color getIndexColor(int index) {
  color col = color(255);
  if (index == 0)
    col = color(255, 0, 0);
  if (index == 1)
    col = color(0, 255, 0);
  if (index == 2)
    col = color(0, 0, 255);
  if (index == 3)
    col = color(255, 255, 0);
  if (index == 4)
    col = color(0, 255, 255);
  if (index == 5)
    col = color(255, 0, 255);

  return col;
}


void drawBody(KJoint[] joints) {
  drawBone(joints, KinectPV2.JointType_Head, KinectPV2.JointType_Neck);
  drawBone(joints, KinectPV2.JointType_Neck, KinectPV2.JointType_SpineShoulder);
  drawBone(joints, KinectPV2.JointType_SpineShoulder, KinectPV2.JointType_SpineMid);

  drawBone(joints, KinectPV2.JointType_SpineMid, KinectPV2.JointType_SpineBase);
  drawBone(joints, KinectPV2.JointType_SpineShoulder, KinectPV2.JointType_ShoulderRight);
  drawBone(joints, KinectPV2.JointType_SpineShoulder, KinectPV2.JointType_ShoulderLeft);
  drawBone(joints, KinectPV2.JointType_SpineBase, KinectPV2.JointType_HipRight);
  drawBone(joints, KinectPV2.JointType_SpineBase, KinectPV2.JointType_HipLeft);
  

  drawJoint(joints, KinectPV2.JointType_Head);
}

void drawJoint(KJoint[] joints, int jointType) {
  strokeWeight(2.0f + joints[jointType].getZ()*8);
  point(joints[jointType].getX(), joints[jointType].getY(), joints[jointType].getZ());
}

void drawBone(KJoint[] joints, int jointType1, int jointType2) {
  strokeWeight(2.0f + joints[jointType1].getZ()*8);
  point(joints[jointType2].getX(), joints[jointType2].getY(), joints[jointType2].getZ());
}

float getAvg(float[] coords){
  int i;
  float sum = 0;
  for (i = 0; i < coords.length; i++) {
    sum += coords[i];
  }
  return sum / i;
}

float getVariance(float[] coords, float avg){
  int i;
  float sum = 0;
  for (i = 0; i < coords.length; i++) {
    sum += pow(coords[i] - avg, 2);
  }
  return sum / i;
}


boolean isTorsoGoodPosture(KJoint[] joints){
  float[] zTorsoValues = {joints[KinectPV2.JointType_Head].getZ(), joints[KinectPV2.JointType_Neck].getZ(), joints[KinectPV2.JointType_SpineShoulder].getZ(), joints[KinectPV2.JointType_SpineMid].getZ(), joints[KinectPV2.JointType_SpineBase].getZ()};
  float zValuesAvg = getAvg(zTorsoValues);
  float zValuesVariance = getVariance(zTorsoValues, zValuesAvg);
  float zValuesStandardDeviation = sqrt(zValuesVariance);
  message = "" + zValuesStandardDeviation + "";  // Debugging purpose
  return zValuesStandardDeviation < 0.026;
}

boolean isShoulderBalanced(KJoint[] joints){
  return abs(joints[KinectPV2.JointType_ShoulderRight].getY() - joints[KinectPV2.JointType_ShoulderLeft].getY()) < 0.015;
}

// Has the same structure as isTorsoGoodPosture but the zJointValues  and the thresholds are different.
boolean isBackGoodPosture(KJoint[] joints){
  float[] zJointValues = {joints[KinectPV2.JointType_SpineShoulder].getZ(), joints[KinectPV2.JointType_SpineMid].getZ(), joints[KinectPV2.JointType_SpineBase].getZ()};
  float zValuesAvg = getAvg(zJointValues);
  float zValuesVariance = getVariance(zJointValues, zValuesAvg);
  float zValuesStandardDeviation = sqrt(zValuesVariance);
  message = "" + zValuesStandardDeviation + "";  // Debugging purpose
  return zValuesStandardDeviation < 0.015;
}

boolean isLeaningBackward(KJoint[] joints){
  float[] zJointValues = {joints[KinectPV2.JointType_SpineShoulder].getZ(), joints[KinectPV2.JointType_SpineMid].getZ(), joints[KinectPV2.JointType_SpineBase].getZ()};
  return zJointValues[0] > zJointValues[2] + 0.045;
}

/* Imagine how your mom would correct your posture
 * First, "Sit up!"
 * Second, "Chest out!"
 * Third, "Straighten your neck!"
*/
void checkPosture(KJoint[] joints){
  /* First your back. We also check whether you are leaning backward.
   * If you don't check the leaning, the second condition won't have a chance. */
  if(!isTorsoGoodPosture(joints) && isLeaningBackward(joints)){
    postureMessage = "Sit up!";
  }else if(!isTorsoGoodPosture(joints)){
    postureMessage = "Straighten your neck!";
  }else{
    postureMessage = "Good posture!";
  }
}

