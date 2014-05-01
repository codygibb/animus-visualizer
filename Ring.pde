import ddf.minim.*; 

class Ring extends Visualizer {
    @Override
    int getOptimalFrameRate() {
        return 48;
    }
    
    final int SAMPLE_NUM = 180;
    final int SPEC_SIZE = 50;
    final float REFRESH = 1;
    final float ROT_SPEED = PI / 2800;
    final float DIST = PHI * 2; //PHI
    final float ADD_DIST = -10; //-10
    final float INIT_DIST = 20; // 10
    final float MAX_TIME = 2000; //in milliseconds
    final float MAX_SPEED = 0.2;
    final float MIN_PART_SIZE = 2;
    final float MAX_PART_SIZE = 20;

    EPVector rotationVector; //handles rotating the verticies when revolve is turned on
    float xRot;
    float zRot;
    float explodeVal;

    // we will sample the framerate and adjust this as needed when particle mode is
    // initiated
    float particleDetailLoss = 1;
    
    float deltaRotation = PI / 2000;
    
    ColorTracker tracker;
    ColorTracker tracker2;
    Sample[] samples;
    
    float start = 0;
    float stop = 0;
    float averageSpeed = 0;
    boolean throttlingOn = false;

    boolean sampleParticleMode = false;
    
    public Ring(AudioInput input) {
        super(input, "RING");
        tracker = new ColorTracker(0.1, 0.8);
        tracker2 = new ColorTracker(0.1, 0.8);
        camera.viewingMode = false;
        camera.pos = new PVector(0, 0, -800);
        camera.setOuterBounds(-1000, -1000, -1000, 1000, 1000, 1000);
        
        samples = new Sample[SAMPLE_NUM];
        for (int i = 0; i < samples.length; i++) {
            samples[i] = new Sample(i * REFRESH, SAMPLE_NUM * REFRESH, SPEC_SIZE, i);
        }
        rotationVector = new EPVector();
        start = millis();
    }    
    
    // Samples are slices of the sound
    class Sample {
        Point[] points;
        float pos, stop, rot, rotSpeed;
        int index;
        
        Sample(float pos, float stop, int pointNum, int index) {
            this.pos = pos;
            this.stop = stop;
            this.index = index;
            
            points = new Point[pointNum];
            for (int i = 0; i < points.length; i++) {
                float angle = i * (TWO_PI / points.length);
                
                PVector p = new PVector(0, INIT_DIST + DIST * pow((float)Math.E, angle));
                int rotDir;
                if (i % 2 == 0) {
                    rotDir = 1;
                } else {
                    rotDir = -1;
                }
                
                points[i] = new Point(i, p, pow(points.length - i, 1.168) * ROT_SPEED, rotDir);
            }
        }
        
        void update() {
            pos += REFRESH;      
            
            boolean isNewPoint = false;
            float greatestMag = 0.0;
            if (pos >= stop) {
                pos = 0;
                isNewPoint = true;
                if (highlight) {
                    greatestMag = getGreatestMag(100);
                }
            }
            
            for (int i = 0; i < points.length; i++) {
                Point p = points[i];
                p.updateRot();
                p.pos.z = pos;
                if (isNewPoint) {
                    float angle = i * (TWO_PI / points.length);
                    PVector temp2d = new PVector(0, INIT_DIST + DIST * pow((float)Math.E, angle));
                    temp2d.rotate(p.rot);
                    p.pos = new PVector(temp2d.x, temp2d.y, 0);
                    p.updateSnd(greatestMag);
                    if (highlight) {
                        p.strokeWeight = min(0.3 + p.size, 8);
                    } else {
                        p.strokeWeight = min(0.3 + p.size * 3, 30);
                    }   
                }
            } 
        }
        
        void drawSample() {
            if (pos > 0 && pos < stop - REFRESH) {
                int prevIndex;
                if (index == 0) {
                    prevIndex = samples.length - 1;
                } else {
                    prevIndex = index - 1;
                }
                
                Sample prevSample = samples[prevIndex];
                
                if (revolve) {
                    xRot += .000001;
                    zRot += .00001;
                } else {
                    xRot = 0;
                    zRot = 0;
                }                    
                
                if (!particles) {
                    beginShape(LINES);
                }
                for (int i = 0; i < points.length; i++) {
                    points[i].drawPoint(pos, stop, prevSample.points[i], index);
                }
                if (!particles) {
                    endShape();
                } 
            } 
        }
    }
    
    class Point {
        int index, rotDir;
        PVector pos;
        float size, rotSpeed, rot, origMag, greatestMag, strokeWeight;
        float[] colors;
        
        Point(int index, PVector pos, float rotSpeed, int rotDir) {
            this.index = index;
            this.pos = pos;
            this.rotSpeed = rotSpeed;
            origMag = INIT_DIST + (new PVector(pos.x, pos.y)).mag();
            this.rotDir = rotDir;
            colors = new float[4];
        }
        
        void updateRot() {
            rot += rotSpeed * rotDir;
        }
        
        void updateSnd(float greatestMag) {
            this.greatestMag = greatestMag;
            size = getIntensity(index) * 0.9;
            colors = getColor(pos.mag(), 200, tracker, tracker2);
        }
        
        void drawPoint(float zpos, float stop, Point prevPoint, int sampleIndex) {
            float fade = pow((stop - zpos) / stop, 5.0 / 6.0);

            stroke(colors[0] * fade, colors[1] * fade, colors[2] * fade);

            float magnitude = zpos * (ADD_DIST / stop);
            
            if (prevPoint.pos.z == 0) {
                PVector p = new PVector(pos.x, pos.y);             
                if (highlight) {
                    float mag = origMag + abs(greatestMag);
                    p.setMag(mag);
                }
                pos.x = p.x;
                pos.y = p.y;    
            } else {
                pos.setMag(pos.mag() + magnitude);
            }

            strokeWeight(strokeWeight);
            PVector prevPos = prevPoint.pos;
            float theta = TWO_PI * index / SPEC_SIZE;
            if (expand) {
                pos.y -= index / 3.0;
            }
            rotationVector.set(pos.x, pos.y, pos.z);
            rotationVector.rotateX(theta * xRot);
            rotationVector.rotateZ(theta * zRot);

            if (!particles) {
                vertex(rotationVector.x, rotationVector.y, rotationVector.z);
            } else if (sampleIndex % particleDetailLoss == 0) {
                strokeWeight(bindRange(size * 10, MIN_PART_SIZE, MAX_PART_SIZE));
                point(rotationVector.x, rotationVector.y, rotationVector.z);
            }

            rotationVector.set(prevPos.x, prevPos.y, prevPos.z);
            rotationVector.rotateX(theta * xRot);
            rotationVector.rotateZ(theta * zRot);

            if (!particles) {
                vertex(rotationVector.x, rotationVector.y, rotationVector.z);
            } // else if (sampleIndex % particleDetailLoss == 0) {
                // strokeWeight(bindRange(size * 10, MIN_PART_SIZE, MAX_PART_SIZE));
                // point(rotationVector.x, rotationVector.y, rotationVector.z);
            // }
        }
    }

    synchronized void draw() {
        if (blur) {
            setBackground(contrast, 10);
        } else { 
            setBackground(contrast, 150);
        }
        if (sampleParticleMode) {
            float avgFr = sampleFrameRate();
            if (avgFr > 0) {
                adjustDetail(avgFr);
            }
        }
        hint(ENABLE_DEPTH_MASK);
        tracker.incrementColor();
        tracker2.incrementColor();
        pushMatrix();

        camera.update();
        
        if (millis() - start < stop) {
            averageSpeed = incrRot(deltaRotation);
            if (averageSpeed > MAX_SPEED || averageSpeed < -MAX_SPEED) {
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

        for (int i = 0; i < samples.length; i++) {
            samples[i].update();
        }

        hint(DISABLE_DEPTH_MASK);
        for (int i = 0; i < samples.length; i++) {
            samples[i].drawSample();
        }

        popMatrix();
    }

    void adjustDetail(float avgFr) {
        println(avgFr);
        if (avgFr < 30) {
            particleDetailLoss = 8;
        } else if (avgFr < 40) {
            particleDetailLoss = 6;
        } else if (avgFr < 45) {
            particleDetailLoss = 3;
        }
    }

    // returns avg rotation of all points
    float incrRot(float increment) {
        float total = 0;
        float count = 0;
        for (Sample sample : samples) {
            for (Point point : sample.points) {
                point.rotSpeed += increment;
                total += point.rotSpeed;   
                count++;     
            }
        }
        return total / count;
    }

    @Override
    void particles() {
        particles = !particles;
        if (!sampleParticleMode) {
            sampleParticleMode = true;
        }
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
        revolve = !revolve;
    }
    
    @Override
    void frontView() {
        camera.initMoveCamera(new PVector(0, 0, -800), (int)frameRate);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }
    
    @Override
    void rearView() {
        camera.initMoveCamera(new PVector(0, 0, REFRESH * SAMPLE_NUM + 600), (int)frameRate);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }
    
    @Override
    void topView() { 
        // TODO
    }
}
