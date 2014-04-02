import ddf.minim.*; 

public class Ring extends Visualizer {
    int OPTIMAL_FRAME_RATE = 48;
    int getOptimalFrameRate() {
        return OPTIMAL_FRAME_RATE;
    }
    
    final int INSTANCE_NUM = 180; //180
    final int SPEC_SIZE = 50;
    final float REFRESH = 1; //3
    final int SAMPLE_NUM = 50; //50
    final float ROT_SPEED = PI / 2800;
    final float DIST = 1.5; //2
    final float ADD_DIST = -10; //-10
    final float INIT_DIST = 10;
    final float MAX_TIME = 2000; //in milliseconds
    
    float deltaRotation = PI / 2000;
    
    ColorTracker tracker;
    ColorTracker tracker2;
    Instance[] instances;
    boolean expand = false;
    boolean frontalView = true;
    boolean rearView = false;
    
    float start = 0;
    float stop = 0;
    float averageSpeed = 0;
    boolean throttlingOn = false;
    float maxSpeed = 0.2;
    
    public Ring(AudioInput input) {
        super(input, "Ring");
        tracker = new ColorTracker();
        tracker2 = new ColorTracker();
        camera.viewingMode = false;
        camera.pos = new PVector(0, 0, -800);
//        camera.pos = new PVector(0, 0, INSTANCE_NUM*REFRESH + 600);
        camera.setOuterBounds(-2000, -2000, -2000, 2000, 2000, 2000);
        
        instances = new Instance[INSTANCE_NUM];
        for (int i = 0; i < instances.length; i++) {
            instances[i] = new Instance(i * REFRESH, REFRESH, INSTANCE_NUM * REFRESH, SAMPLE_NUM, SPEC_SIZE / SAMPLE_NUM, i);   
        }
        
        sphereDetail(1);
        start = millis();
    }    
    
    class Instance {
        Sample[] samples;
        float pos, speed, stop, rot, rotSpeed;
        int index;
        
        //sampleNum is number of orbs, indexRange is the number of fft indexes each orb will include
        Instance(float pos, float speed, float stop, int sampleNum, int indexRange, int index) {
            this.pos = pos;
            this.speed = speed;
            this.stop = stop;
            this.index = index;
            
            samples = new Sample[sampleNum];
            for (int i = 0; i < samples.length; i++) {
                float angle = i * (TWO_PI / samples.length);
                
                int[] indexes = new int[indexRange];
                for (int k = 0; k < indexes.length; k++) {
                    indexes[k] = i * indexes.length + k;    
                }
//                PVector p = new PVector(0, INIT_DIST + DIST * pow(i, 1.168));
                PVector p = new PVector(0, INIT_DIST + DIST * pow((float)Math.E, angle));
                int rotDir;
                if (i % 2 == 0) {
                    rotDir = 1;
                } else {
                    rotDir = -1;
                }
                
                samples[i] = new Sample(indexes, 5, p, pow(samples.length - i, 1.168) * ROT_SPEED, rotDir);

            }
        }
        
        void update() {
            pos += speed;
            
            
            boolean isNewSample = false;
            if (pos >= stop) {
                pos = 0;
                isNewSample = true;
            }
            
            for (int i = 0; i < samples.length; i++) {
                samples[i].updateRot();
                samples[i].pos.z = pos;
                if (isNewSample) {
                    float angle = i * (TWO_PI / samples.length);
//                    samples[i].pos = new PVector(0, (i + 1) * DIST, 0);
//                    PVector temp2d = new PVector(0, INIT_DIST + DIST * pow(i, 1.168));
                    PVector temp2d = new PVector(0, INIT_DIST + DIST * pow((float)Math.E, angle));
                    temp2d.rotate(samples[i].rot);
                   // temp2d.setMag(temp2d.mag() + src.left.get(i) * 15 * volumeScale);
                    samples[i].pos = new PVector(temp2d.x, temp2d.y, 0);
                    samples[i].updateSnd();                   
                }
            } 
        }
        
        void drawInstance() {
//            float c = 255 - pos * (255.0 / stop);
//            float c = pow((stop - pos) / stop, 5.0 / 6.0);
            
//            fill(c);

            

//            stroke((255 - tracker.red) * c, (255 - tracker.green) * c, (255 - tracker.blue) * c );
//            stroke(c, c, c, 1);

            if (pos > 0 && pos < stop - speed) {
                int prevIndex;
                if (index == 0) {
                    prevIndex = instances.length - 1;
                } else {
                    prevIndex = index - 1;
                }
                
                Instance currInstance = this;
                Instance prevInstance = instances[prevIndex];
                
                beginShape(LINES);
                for (int i = 0; i < samples.length; i++) {
//                    vertex(0, 0, 0);
                    samples[i].drawSample(speed, pos, stop, prevInstance.samples[i]);  
                    
                    
                }
                endShape();
                 
            } 
//            translate(0, 0, pos);
            
            
//            beginShape(POLYGON);
//            noFill();
//            for (int i = 0; i < samples.length; i++) {
//                vertex(samples[i].pos.x, samples[i].pos.y, pos);
//            }
//            endShape();
        }
    }
    
    class Sample {
        int[] indexes;
        float size;
        PVector pos;
        float rotSpeed, rot; 
        float origMag;  
        int rotDir;    
        
        Sample(int[] indexes, float size, PVector pos, float rotSpeed, int rotDir) {
            this.indexes = indexes;
            this.size = size;
            this.pos = pos;
            this.rotSpeed = rotSpeed;
            origMag = INIT_DIST + (new PVector(pos.x, pos.y)).mag();
            this.rotDir = rotDir;
        }
        
        void updateRot() {
            rot += rotSpeed * rotDir;
        }
        
        void updateSnd() {
            float avg = 0;
            for (int i = 0; i < indexes.length; i++) {
                avg += fft.getBand(indexes[i]) * 0.9;  
            }  
            avg = avg / indexes.length;
            size = avg * volumeScale;
        }
        
        void drawSample(float end, float zpos, float stop, Sample prevSample) {
            float c = pow((stop - zpos) / stop, 5.0 / 6.0);
            
            float red1 = tracker.red;
            float green1 = tracker.green;
            float blue1 = tracker.blue;
            float red2 = tracker2.red;
            float green2 = tracker2.green;
            float blue2 = tracker2.blue;
            
            float shift2 = pos.mag() / 100;
            float shift1 = 1 - shift2;
            
            float r = (255 - (red1 * shift1 + red2 * shift2)) * c;
            float g = (255 - (green1 * shift1 + green2 * shift2)) * c;
            float b = (255 - (blue1 * shift1 + blue2 * shift2)) * c;
            
            stroke(r, g, b);

            float magnitude = zpos * (ADD_DIST / stop);
            float greatestMag = 0;
            if (expand) {
                for (int i = 0; i < 50; i++) {
                    float tempMag = fft.getBand(i) * 0.9;
                    if (tempMag > greatestMag) {
                        greatestMag = tempMag;    
                    }    
                }
            }
            if (prevSample.pos.z == 0) {
                PVector p = new PVector(pos.x, pos.y);             
                if (expand) {
                    p.setMag(origMag + abs(greatestMag*volumeScale));
                }
                pos.x = p.x;
                pos.y = p.y;    
            } else {
                pos.setMag(pos.mag() + magnitude);
            }
            
            if (expand) {
                strokeWeight(min(0.3 + size, 7));
            } else {
                strokeWeight(min(0.3 + size*3, 25));
            }
            fill(tracker.red, tracker.green, tracker.blue, size*10);
//            sphereDetail(min((int)(size)+1, 10));
//            beginShape(LINE);
            PVector prevPos = prevSample.pos;
//            beginShape(LINES);
            
            vertex(pos.x, pos.y, pos.z);
//            bezierVertex(pos.x - size, pos.y - size, pos.z, pos.x + size, pos.y + size, pos.z, prevPos.x, prevPos.y, prevPos.z);
            vertex(prevPos.x, prevPos.y, prevPos.z);
//            endShape();
//            bezierVertex(prevPos.x, prevPos.y, prevPos.z);
//            endShape();
            if (prevPos.z == 0) {
                pushMatrix();
                translate(prevPos.x, prevPos.y, prevPos.z);
                strokeWeight(1);
                stroke(150);
//                sphere(2);
                popMatrix();
            }
//            pushMatrix();
//            translate(pos.x, pos.y, 0);
//            fill(255);
//            box(size / 20);
//            popMatrix();
            
        }
    }
    
    float incrRot(float increment) {
        float total = 0;
        float count = 0;
        for (int i = 0; i < instances.length; i++) {
            Instance foo = instances[i];
            for (int j = 0; j < foo.samples.length; j++) {
                Sample s = foo.samples[j];
                s.rotSpeed += increment;
                total += s.rotSpeed;   
                count++;     
            }
        }
        return total / count;
    }

    synchronized void draw() {
        retrieveSound();
        setBackground(contrast, 150);
        if (showInterface) {
            displayHelpMenu();    
            displayDebugText();    
        }
        hint(ENABLE_DEPTH_MASK);
        tracker.defineLights();
        tracker.incrementColor();
        tracker2.incrementColor();
        pushMatrix();

        camera.update();
        
        scale(2);
//        rotateX(PI/2);
        stroke(255);
//        noFill();
//        rotateZ(millis()/10000.0);
        
        
        if (millis() - start < stop) {
            averageSpeed = incrRot(deltaRotation);
            if (averageSpeed > maxSpeed || averageSpeed < -maxSpeed) {
//                println("HIT MAX SPEED, THROTTLING");
                throttlingOn = true;
                deltaRotation = -deltaRotation;
            } else if (((averageSpeed < 0.015 && averageSpeed > 0) || (averageSpeed > -0.015 && averageSpeed < 0)) && throttlingOn) {
//                println("RESET SUCCESSFUL");
                throttlingOn = false;   
            }
        } else {
            start = millis();
            stop = random(0, MAX_TIME);
            if (!throttlingOn) {
                deltaRotation = -deltaRotation;
            }
        }

        for (int i = 0; i < instances.length; i++) {
            instances[i].update();
        }
        hint(DISABLE_DEPTH_MASK);
        for (int i = 0; i < instances.length; i++) {
            instances[i].drawInstance();
            if (instances[i].pos == 0) {
                stroke(30);
//                beginShape(TRIANGLE_STRIP);
                strokeWeight(0.7);
                fill(100); //30
                for (int k = 0; k < instances[i].samples.length; k++) {
//                    vertex(0, 0, -200);
                    PVector p = instances[i].samples[k].pos;
//                    vertex(p.x, p.y, 0);
                }
//                endShape();    
            }
        }
        
        stroke(150);
//        rotateY(millis()/10000.0);
//        rotateX(millis()/10000.0);
        
        popMatrix();
        
        
    }
   
    void blur() {
        // TODO
    }

    void particles() {
        // TODO
    }
    
    void highlight() {
        // TODO
    }

    void expand() {
        expand = !expand;
    }

    void revolve() {
        // TODO
    }

// case 'f': 
//     frontalView = true;
//     rearView = false;
//     camera.disableAllModes();
//     camera.initMoveCamera(new PVector(0, 0, -800), (int)frameRate);
//     break;
// case 'r':
//     rearView = true;
//     frontalView = false;
//     camera.disableAllModes();
//     camera.initMoveCamera(new PVector(0, 0, REFRESH * INSTANCE_NUM + 600), (int)frameRate);
//     break;

}
