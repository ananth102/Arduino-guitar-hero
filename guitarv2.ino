#define TRIG 9
#define ECHO 10


int val = 0;  // variable to store the value read
int pins[5];
int count = 0;
int sec_count = 0;
bool strummed = false;
int last_note = -1;
unsigned long last_rec = 0;
int buf_size = 30;
double buf[30];

int buf_index = 0;
unsigned long last_send = 0;
int cummulative = 0;




void setup() {
  pinMode(TRIG, OUTPUT); // set up distance sensor pins
  pinMode(ECHO, INPUT);
  digitalWrite(TRIG, LOW);
  Serial.begin(9600);
  for(int i=0;i<5;i++){
    pins[i] = -1;
    pinMode(i + 2, OUTPUT);//  setup serial
    digitalWrite(i + 2, 1);
  }  
  
}

void loop() {
  // put your main code here, to run repeatedly:
  
  for(int i=0;i<5;i++){
    val = digitalRead(i + 2);  // read the input pin
    pins[i] = val;
  }
  buf[buf_index % buf_size] = readDistance();
  buf_index = ++buf_index % buf_size;
  float avgDist = avg();
  if(millis() < 200)return;
  //Serial.println(avgDist);
  
  if(avgDist < 11 && !strummed ){
    //if(millis() - last_rec)
    strummed = true;
    last_rec = millis();
    //Serial.println(avgDist);
    int countStrum = 0;
    for(int i =0;i<5;i++){
      
      if(pins[i] == 0){
       Serial.print(i);
       last_note = i;
       break; 
       }
       countStrum++;  
    }
    if(countStrum == 5)strummed = false;
    
    
      
  }else {
    if(strummed && avgDist > 11.5){
        //Serial.println("woof");
        long duration = millis() - last_rec;
        //Serial.println(duration);
        strummed = false;
        char toPrint = (char)(97 + last_note);
        Serial.print(toPrint);
        
    }  
  }
}


float avg(){
  double sum = 0;
  for(int i=0;i<buf_size;i++){
    sum+=buf[i];
  }
  return sum/((double)buf_size);  
}

float readDistance() {
  digitalWrite(TRIG, LOW); delayMicroseconds(2);
  digitalWrite(TRIG, HIGH); delayMicroseconds(10);
  digitalWrite(TRIG, LOW);
  unsigned long timeout=micros()+26233L;
  while((digitalRead(ECHO)==LOW)&&(micros()<timeout));
  unsigned long start_time = micros();
  timeout=start_time+26233L;
  while((digitalRead(ECHO)==HIGH)&&(micros()<timeout));
  unsigned long lapse = micros() - start_time;
  return lapse*0.01716f;
}
