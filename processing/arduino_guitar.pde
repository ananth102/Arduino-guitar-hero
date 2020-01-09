
import processing.serial.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import processing.sound.*;


//Storage Variables
int current_note_index = 0;
int bands = 512;
long start_time = 0;
long last_call = 0;
long rec_start = 0;
long arriving_note_end_time = 0;

//Arrays/Maps
String[] spect = new String[5];
int[][] positions = new int[5][100];
int[] test = new int[5];
float[] spectrum = new float[bands];
ArrayList<Note> notes;
HashMap<String,Integer> noteHash;



boolean start = false;
int state = 0; // 0 is start screen 1 is guitar hero mode and 2 is freeplay
final String serialName = "/dev/tty.wchusbserial1410";
boolean firstPlay = true;
int x  = 100;

SoundFile inputSong;
final int BAUD_RATE = 9600;//230400;  // serial baud rate
FFT freq_analyze;

Serial port;
WhiteNoise noise;
Sound s;

SinOsc sin;
GuitarString e1;
GuitarString a ;
GuitarString d;
GuitarString g;
GuitarString b;
GuitarString e2;


void setup(){
  size(500, 300);
  noteHash = new HashMap();
  noteHash.put("a",0);
  noteHash.put("d",1);
  noteHash.put("g",2);
  noteHash.put("b",3);
  noteHash.put("e2",4);
  
  notes = new ArrayList<Note>();
  freq_analyze = new FFT(this);
  port = new Serial(this, serialName, BAUD_RATE); 
  //notes = initSimpleTone();
  e1 = new GuitarString(123.7);
  a = new GuitarString(164.7);
  d = new GuitarString(220.7);
  g = new GuitarString(293.7);
  b = new GuitarString(369.99);
  e2 = new GuitarString(493.88);
  sin = new SinOsc(this);
  spect[0] = "a";
  spect[1] = "d";
  spect[2] = "g";
  spect[3] = "b";
  spect[4] = "e2";
  
}

public void initSimpleTone(){
  
  Note one = new Note("a",2000,1000);
  Note two = new Note("e2",3000,2000);
  Note three = new Note("g",5000,1000);
  Note four = new Note("b",6000,1000);
  notes.add(one);
  notes.add(two);
  notes.add(three);
  notes.add(four);
}

public void initScale(){
  Note one = new Note("a",3000,1000);
  Note two = new Note("d",4000,1000);
  Note three = new Note("g",5000,1000);
  Note four = new Note("b",6000,1000);
  notes.add(one);
  notes.add(two);
  notes.add(three);
  notes.add(four);
  notes.add(new Note("e2",7000,1000));
  notes.add(new Note("b",8000,1000));
  notes.add(new Note("g",9000,1000));
  notes.add(new Note("d",10000,1000));
  notes.add(new Note("a",11000,1000));
}

public void initOhDonna(){
  //main
  notes.add(new Note("d",3000));
  notes.add(new Note("g",4000));
  notes.add(new Note("a",4500));
  
  notes.add(new Note("d",5500));
  notes.add(new Note("g",6500));
  notes.add(new Note("a",7000));
  notes.add(new Note("d",8000));
  notes.add(new Note("g",9000));
  notes.add(new Note("a",10000));
  notes.add(new Note("d",10500));
  notes.add(new Note("g",11500));
  notes.add(new Note("a",12000));
  notes.add(new Note("d",12500));
  notes.add(new Note("g",13000));
  notes.add(new Note("a",13500));
  notes.add(new Note("d",14500));
  notes.add(new Note("g",15000));
  notes.add(new Note("a",16000));
  
}


void draw(){
  //State 0 is first
  //State 1 is the choose song state
  //State 2 is free style
  //State 3+ is game states
  background(0);
  if(millis() - last_call > arriving_note_end_time)sin.stop(); //max amount a sound can go
  if(state == 1){
    textSize(20);
    text("Chose a tune",150,100);
    text("1 Simple Scale",150,140);
    text("2 intermediate tune",150,160);
    text("3 california song you have probably never heard of",150,180);
    
  }
  if(state  > 2){
  fill(100);
  textSize(20);
  for(int i=0;i<5;i++){
    text(spect[i],75,90 + i*30);
    rect(100,75 + i*30,350,20);
    fill(69 + (i*10));
  }
  fill(255);
  textSize(32);
  text("Guitar View",100,40);
  drawNotes();
  portProccess();
  
  }else if(state == 0){
    textSize(27);
    text("Press 1 to start guitarhero mode",60,150);
    text("Press 2 to start freestyle mode",60,190);
  }else if(state == 2){
    portProccess();
  }
  
}
/*
checks if note is within 5 seconds of play draws it if it is
*/
void drawNotes(){
  //int full = 0;
  long curr = millis() - start_time;
  
  for(int i =current_note_index;i<notes.size();i++){
    //notes are in chronogical order so if a note is above 5 then we break;
    
    long local_time = notes.get(i).getBeatTime() - curr;
    
    if(local_time > 5000)break;
    if(local_time < 0 && local_time > -50 && notes.get(i).getNoteStatus() != 1){notes.get(i).setCorrect(2);}
    if(local_time < -50)current_note_index++;
    int x_pos =  (int)((1-((double)(local_time))/5000.0)*350);
    if(i == 0)System.out.println(local_time/5000.0);
    int y_offset = noteHash.get(notes.get(i).getBeatName())*30;
    int note_status = notes.get(i).getNoteStatus();
    if(note_status == 2){
     //System.out.println(i);
    }
    if(note_status ==0)fill(200);
    else if(note_status == 1)fill(67,197,61);
    else if(note_status == 2) fill(221,63,90);
    
    ellipse(80 + x_pos,85 + y_offset,25,25);
  }
  
}

void variableStop(GuitarString gu,float freq){
  long dif = millis() - last_call; // likley to be in the 100s
  int len = (int)(dif/2) * 2; // reverb
  //System.out.println(len);
  //double curr_amp = Math.abs(gu.sample());
  //double decrement = curr_amp
  float sam = (float)Math.abs(gu.sample());
  for(int i = 0;i<len;i++ ){
    sin.play(freq,(float)sam);
    if(sam > 0)sam-=0.01f;
    //System.out.println(sam);
  }
  sin.stop();
  
}

//If not is valid this returns true
//TODO add duration
/*
Pre-conditions : function is called after note fired
Input Note :  
*/
boolean isValid(String beatName){
  System.out.println(start_time);
  long curr  = millis();
  for(Note a :notes){
    long local_time = (a.getBeatTime() + start_time) - curr;
    //System.out.println(local_time);
    if(Math.abs(local_time)  < 500){
      if(a.getBeatName().equals(beatName)){
        a.setCorrect(1);
        System.out.println(a +" "+ a.getNoteStatus());
        return true;
      }
    }
  }
  
  
  return false;
}

void portProccess(){

  if(port.available() > 0){
    char inByte = port.readChar();
    System.out.println(inByte);
    if((millis() - last_call) > 100){
      last_call = millis();
    //if(inByte == '0'){
    //  if(isValid("E1")){
    //    System.out.println("E1 is right");
    //  }
    //  playNote(e1,123.7f);
      
    //}
    if(inByte == '0'){
      rec_start = millis();
      if(isValid("a")){
        System.out.println("A is right");
      }
      playNote(a,164.7f);
    }
    if(inByte == '1'){
      rec_start = millis();
      if(isValid("d")){
        System.out.println("D is right");
      }
      playNote(d,220.7f);
    }
    if(inByte == '2'){
      rec_start = millis();
      if(isValid("g")){
        System.out.println("G is right");
      }
      playNote(g,293.7f);
    }
    if(inByte == '3'){
      rec_start = millis();
      if(isValid("b")){
        System.out.println("B is right");
      }
      playNote(b,369.7f);
    }
    if(inByte == '4'){
      rec_start = millis();
      if(isValid("e2")){
        System.out.println("E2 is right");
      }
      playNote(e2,493.7f);
    }
    
    if(inByte == 'a'){
      long duration = millis() - rec_start;
      arriving_note_end_time = duration * 2; // * 3 < 500 ? duration * 5 : 500;
      //downward slope maybe
      //sin.stop();
      System.out.println("Stopped");
      //long duration = millis() - last_call;
      
    }
    if(inByte == 'b'){
      long duration = millis() - rec_start;
      arriving_note_end_time = duration * 2; // * 3 < 500 ? duration * 5 : 500;
      //sin.stop();
      System.out.println("Stopped");
    
    }
    if(inByte == 'c'){
      long duration = millis() - rec_start;
      arriving_note_end_time = duration * 2; // * 3 < 500 ? duration * 5 : 500;
      //sin.stop();
      System.out.println("Stopped");
      
    }
    if(inByte == 'd'){
      long duration = millis() - rec_start;
      arriving_note_end_time = duration * 2;// * 3 < 500 ? duration * 5 : 500;
      //sin.stop();
      System.out.println("Stopped");
    
    }
    if(inByte == 'e'){
      long duration = millis() - rec_start;
      arriving_note_end_time = duration * 2;// * 3 < 500 ? duration * 5 : 500;
      //sin.stop();
      System.out.println("Stopped");
      
    }
    
    
  }
  }
  
}


void keyPressed() {
//  if(millis() - last_call < 100){
//  return;
//}
arriving_note_end_time = 500;
 sin = new SinOsc(this);
 //sin.play();
 if(state > 1){
 if(key == 'z'){
    variableStop(e1,123.7f);
    System.out.println("ze");
  }
last_call = millis();
 // delay(100);
  if(key == 'a'){
      playNote(e1,123.7f);
      System.out.println("down");
  }
  if(key == 's'){
    
      playNote(a,164.7f);
      if(isValid("a")){
        System.out.println("Valid a");
      }else{
        System.out.println("Wrong lul");
      }
  }
  if(key == 'd'){
      playNote(d,220.7f);
      if(isValid("d")){
        System.out.println("Valid d");
      }else{
        System.out.println("Wrong lul");
      }
  }
  if(key == 'f'){
      playNote(g,293.7f);
      if(isValid("g")){
        System.out.println("Valid g");
      }else{
        System.out.println("Wrong lul");
      }
  }
  if(key == 'g'){
      playNote(b,369.7f);
      if(isValid("b")){
        System.out.println("Valid b");
      }else{
        System.out.println("Wrong lul");
      }
  }
  if(key == 'h'){
      playNote(e2,493.7f);
      if(isValid("e2")){
        System.out.println("Valid e2");
      }else{
        System.out.println("Wrong lul");
      }
  }
  
  
}
if(state == 0){
  if(key == '1'){
    state = 1;
    //start_time = millis();
  }
  if(key == '2')state = 2;
}else if(state == 1){
  if(key == '1'){
      state = 3;
      //System.out.println(notes);
      initScale();
      start_time = millis();
   }else if(key == '2'){
      state = 4;
      initSimpleTone();
      start_time = millis();
   }else if(key == '3'){
     state = 5;
     initOhDonna();
     start_time = millis();
   }
   
}
  
}

void playNote(GuitarString gu, float freq){
  //if(firstPlay)start_time = millis();
  firstPlay = false;
  long start = millis();
  
   gu.pluck();
   
  double sam = gu.sample();
  for(int i=0;i<2000;i++){
    
    
    if(gu.time() % 1 == 0){
      sam = gu.sample();
     //System.out.println(sam);
     
    }
    sin.play(freq,(float)sam);
    
    gu.tic();
    
    
  }
  //sin = new SinOsc(this);
  long end = millis();
  
  //System.out.println("Durtion of note "+ (end - start));
}

class Note{

  //private int level;
  private String beatName;
  private long note_time; //probably in the order of millis
  private int beat_duration; //amount of millis beat takes place for
  private int note_status = 0; //0 - not played but in queue, 1 - correct - 2 - incorrect
  
  
  public Note(String name,long n,int b){
    beatName = name;
    note_time = n;
    beat_duration = b;
    
    
  }
  
  public Note(String name,long n){
    beatName = name;
    note_time = n;
    beat_duration = 1000;
  }
  
  public void setCorrect(int c){note_status = c;}
  private int getNoteStatus(){return note_status;}
  public long getBeatTime(){return note_time;}
  public int getDuration(){return beat_duration;}
  public String getBeatName(){
    return beatName;
  }
  @Override
  public String toString(){
    return beatName + " @ "+ note_time + " for " + beat_duration + " seconds.";
  }
  
}
