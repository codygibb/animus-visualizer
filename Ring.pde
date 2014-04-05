import ddf.minim.*; 

class Ring extends Visualizer {
    final int OPTIMAL_FRAME_RATE = 48;
    
    @Override
    int getOptimalFrameRate() {
        return OPTIMAL_FRAME_RATE;
    }
    
    final int INSTANCE_NUM = 180; //180
    final int SPEC_SIZE = 50;
    final float REFRESH = 1; //3
    final int SAMPLE_NUM = 50; //50
    final float ROT_SPEED = PI / 2800;
    final float DIST = PHI; //2
    final float ADD_DIST = -10; //-10
    final float INIT_DIST = 10;
    final float MAX_TIME = 2000; //in milliseconds
    RotationTracker rotater;
    EPVector rotation; //handles rotating the verticies when revolve is turned on
    float xRot;
    float yRot;
    
    float deltaRotation = PI / 2000;
    
    ColorTracker tracker;
    ColorTracker tracker2;
    Instance[] instances;
    
    float start = 0;
    float stop = 0;
    float averageSpeed = 0;
    boolean throttlingOn = false;
    float maxSpeed = 0.2;
    
    public Ring(AudioInput input) {
        super(input, "Ring");
        tracker = new ColorTracker();
        tracker2 = new ColorTracker();
        rotater = new RotationTracker();
        camera.viewingMode = false;
        camera.pos = new PVector(0, 0, -800);
        camera.setOuterBounds(-2000, -2000, -2000, 2000, 2000, 2000);
        
        instances = new Instance[INSTANCE_NUM];
        for (int i = 0; i < instances.length; i++) {
            instances[i] = new Instance(i * REFRESH, REFRESH, INSTANCE_NUM * REFRESH, SAMPLE_NUM, SPEC_SIZE / SAMPLE_NUM, i);
        }
        rotation = new EPVector();
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
                    PVector temp2d = new PVector(0, INIT_DIST + DIST * pow((float)Math.E, angle));
                    temp2d.rotate(samples[i].rot);
                    samples[i].pos = new PVector(temp2d.x, temp2d.y, 0);
                    samples[i].updateSnd();                   
                }
            } 
        }
        
        void drawInstance() {
            if (pos > 0 && pos < stop - speed) {
                int prevIndex;
                if (index == 0) {
                    prevIndex = instances.length - 1;
                } else {
                    prevIndex = index - 1;
                }
                
                Instance currInstance = this;
                Instance prevInstance = instances[prevIndex];
                
                if (revolve) {
                    xRot += .000001;
                    yRot += .00001;
                } else{
                    xRot = 0;
                    yRot = 0;
                }                    
                
                if (particles) {
                   beginShape(POINTS); 
                } else { 
                    beginShape(LINES);
                }
                for (int i = 0; i < samples.length; i++) {
                    samples[i].drawSample(speed, pos, stop, prevInstance.samples[i], i);  
                }
                endShape();   
            } 
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
                avg += getIntensity(indexes[i]) * 1.1;
            }  
            avg = avg / indexes.length;
            size = avg * volumeScale;
        }
        
        void drawSample(float end, float zpos, float stop, Sample prevSample, int index) {
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
                    float tempMag = getIntensity(i) * 1.1;
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
            PVector prevPos = prevSample.pos;
            float theta = (10*PI*index)/instances.length;
            rotation.set(pos.x, pos.y, pos.z);
            rotation.rotateX(theta*rotater.xRot);
            rotation.rotateY(theta*rotater.yRot);
            vertex(rotation.x, rotation.y, rotation.z); 
            rotation.set(prevPos.x, prevPos.y, prevPos.z); //reuse the same EPVector for memory
            rotation.rotateX(theta*rotater.xRot);
            rotation.rotateY(theta*rotater.yRot);
            vertex(rotation.x, rotation.y, rotation.z);
            if (prevPos.z == 0) {
                pushMatrix();
                translate(prevPos.x, prevPos.y, prevPos.z);
                strokeWeight(1);
                stroke(150);
                popMatrix();
            }
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
        if (blur) {
            setBackground(contrast, 10);
        } else { 
            setBackground(contrast, 150);
        }
        
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
        rotater.update();
        scale(2);
        stroke(255);
        
        if (millis() - start < stop) {
            averageSpeed = incrRot(deltaRotation);
            if (averageSpeed > maxSpeed || averageSpeed < -maxSpeed) {
                throttlingOn = true;
                deltaRotation = -deltaRotation;
            } else if (((averageSpeed < 0.015 && averageSpeed > 0) || (averageSpeed > -0.015 && averageSpeed < 0))
                    && throttlingOn) {
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
        }
        popMatrix();
    }

    @Override
    void particles() {
        particles = !particles;
    }

    @Override
    void highlight() {
        highlight = !highlight;
    }

    @Override
    void expand() {
        expand = !expand;
    }
    
    @Override
    void revolve(){
        rotater.autoSwitch();
        if (!revolve) {
            rotater.initRotate(0, 0, (int) frameRate * 10);    
        }
    }
    
    @Override
    void frontView() {
        camera.initMoveCamera(new PVector(0, 0, -800), (int)frameRate);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }
    
    @Override
    void rearView() {
        camera.initMoveCamera(new PVector(0, 0, REFRESH * INSTANCE_NUM + 600), (int)frameRate);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }
    
    @Override
    void topView() { 
        // TODO
    }
}
