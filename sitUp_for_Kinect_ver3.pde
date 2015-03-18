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

float zVal = 300;
float rotX = PI;

String message = "";
String postureMessage = "";
boolean existingPosture = true;

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
  
  //closestSkeleton = null;
  someoneIsSitting = false;
  for (int i = 0; i < skeleton.length; i++) {
       if (skeleton[i].isTracked()) {
          //KJoint[] joints = skeleton[i].getJoints();
          if(!someoneIsSitting) {
            closestSkeleton = skeleton[i];
          }else{
            updateClosest(skeleton[i]);
          }
          someoneIsSitting = true;
       }
  }

  //for (int i = 0; i < skeleton.length; i++) {
 if (someoneIsSitting) {
      KJoint[] joints = closestSkeleton.getJoints();

      //Draw body
      color col  = getIndexColor(0);
      stroke(col);
      drawBody(joints);
      checkPosture(joints);
      /*
      if (checkPosture(joints)) {
         postureMessage = "Good Posture!";
         //checkPostureChanged(true);
      } else {
         postureMessage = "Bad Posture!";
         //checkPostureChanged(false);
      }
      */
      
   }
  //}
  popMatrix();


  fill(255, 0, 0);
  //text(frameRate, 50, 50);
  //text(message, 50,300);
  textSize(26);
  text(postureMessage, width-(width/3), height-(height/2));
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

void checkPostureChanged(boolean newPosture) {
  if (newPosture != existingPosture) {
    postureNotification(newPosture);
    existingPosture = newPosture;  
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

// Get the distance between two joints
float getDistance(KJoint aJoint, KJoint bJoint){
  float xDistanceSquared = pow(aJoint.getX() - bJoint.getX(), 2);
  float yDistanceSquared = pow(aJoint.getY() - bJoint.getY(), 2);
  float zDistanceSquared = pow(aJoint.getZ() - bJoint.getZ(), 2);
  return sqrt(xDistanceSquared + yDistanceSquared + zDistanceSquared);
}

// Get the angle between of a, b, c
// cosB = (a^2 + c^2 - b^2) / 2ac


/* What is a good posture? 
 * Torso, Shoulder-align
*/
boolean isTorsoGoodPosture(KJoint[] joints){
  float[] zTorsoValues = {joints[KinectPV2.JointType_Head].getZ(), joints[KinectPV2.JointType_Neck].getZ(), joints[KinectPV2.JointType_SpineShoulder].getZ(), joints[KinectPV2.JointType_SpineMid].getZ(), joints[KinectPV2.JointType_SpineBase].getZ()};
  float zValuesAvg = getAvg(zTorsoValues);
  float zValuesVariance = getVariance(zTorsoValues, zValuesAvg);
  float zValuesStandardDeviation = sqrt(zValuesVariance);
  message = "" + zValuesStandardDeviation + "";
  return zValuesStandardDeviation < 0.03;
}

boolean isShoulderAligned(KJoint[] joints){
  return abs(joints[KinectPV2.JointType_ShoulderRight].getY() - joints[KinectPV2.JointType_ShoulderLeft].getY()) < 0.01;
}

boolean areJointsStraight(KJoint aJoint, KJoint bJoint, KJoint cJoint){
  float sumLength = getDistance(aJoint, bJoint) + getDistance(bJoint, cJoint);
  float aToCLength = getDistance(aJoint, cJoint);
  return sumLength / aToCLength > 1.1;
}

boolean isBackGoodPosture(KJoint[] joints){
  float[] zJointValues = {joints[KinectPV2.JointType_SpineShoulder].getZ(), joints[KinectPV2.JointType_SpineMid].getZ(), joints[KinectPV2.JointType_SpineBase].getZ()};
  float zValuesAvg = getAvg(zJointValues);
  float zValuesVariance = getVariance(zJointValues, zValuesAvg);
  float zValuesStandardDeviation = sqrt(zValuesVariance);
  message = "" + zValuesStandardDeviation + "";
  return zValuesStandardDeviation < 0.02;
}

boolean isLeaningBackward(KJoint[] joints){
  float[] zJointValues = {joints[KinectPV2.JointType_SpineShoulder].getZ(), joints[KinectPV2.JointType_SpineMid].getZ(), joints[KinectPV2.JointType_SpineBase].getZ()};
  return zJointValues[1] > zJointValues[2] + 0.05;
}

/* Imagine how your mom would correct your posture
 * First, "Sit up!"
 * Second, "Chest out!"
 * Third, "Straighten your neck!"
*/
void checkPosture(KJoint[] joints){
  // First your back
  if(!isBackGoodPosture(joints) && isLeaningBackward(joints)){
    postureMessage = "Sit up!";
  }else if(!isTorsoGoodPosture(joints)){
    postureMessage = "Straighten your neck!";
  }else{
    postureMessage = "Good posture!";
  }
}
