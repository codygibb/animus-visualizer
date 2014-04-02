
class Droplet extends Visualizer {
    int OPTIMAL_FRAME_RATE = 35;
    int getOptimalFrameRate() {
        return OPTIMAL_FRAME_RATE;
    }

    ColorTracker tracker;
    ColorTracker tracker2;
    Ring[] rings;
    final int SPEC_SIZE = 50;
    final int SPEC_WIDTH = 7;
    final float DETAIL = 1.1; // DETAIL * radius of ring "i" = number of points in ring "i"
    final float DECAY = 0.3; // DECAY = -y per frame
    final int MAX_DECAY = 100;
    final int PEAK = 40;
    
    boolean dropLevel1 = false;
    boolean frontalView = true;
    boolean topDownView = false;
    RotationTracker rotater;

    Droplet(AudioInput input) {
        super(input, "Droplet");
        camera.pos = new PVector(0, 0, 400);
        float n = SPEC_SIZE * SPEC_WIDTH;
        camera.setOuterBounds(-n, -n * 1.2, -n, n, n * 1.2, n);
        camera.setInnerBounds(-n / 4, 0, - n / 4, n / 4, 0, n / 4);
        camera.viewSwitch();
        tracker = new ColorTracker();
        tracker2 = new ColorTracker();
        rotater = new RotationTracker();
        rings = new Ring[SPEC_SIZE];
//        strokeWeight(1.75);
        for (int i = 0; i < rings.length; i++) {
            rings[i] = new Ring(SPEC_WIDTH * (i + 1), i);  
        }
        
        for (int i = rings.length - 1; i >= 0; i--) {
            for (int j = 0; j < rings[i].points.length; j++) {
                if (i != 0) {
                    rings[i].points[j].next = rings[i].points[j].findNearestOneDeeper(i);
                }
            }
        }
        noCursor();
    }
    
    class Ring {
        int index, size;
        Point[] points;
        
        // 0 index Ring has a boost in detail
        Ring(int radius, int index) {
            this.index = index;
            size = (int) (radius * DETAIL + 1);
            if (index == 0) {
                size += 5;  
            }
            points = new Point[size];
            for (int i = 0; i < points.length; i++) {
                float angle = TWO_PI * i / points.length;
                EPVector pos = new EPVector(radius, 0, 0);
                pos.rotateY(angle);
                points[i] = new Point(pos, angle, size, index);
            }
        }
        
        void update() {
            for (int i = 0; i < points.length; i++) {
                points[i].update(index);
                points[i].colors = getColor(points[i].pos.y);
            }
        }
        
        // call twist before drawing
        void twist(float xRot, float yRot) {
            for (int i = 0; i < points.length; i++) {
                points[i].twist(xRot, yRot);
            }    
        }
        
        //call untwist after drawing (with same values for xRot and yRot as twist!!!);
        void untwist(float xRot, float yRot) {
            for (int i = 0; i < points.length; i++) {
                points[i].untwist(xRot, yRot);    
            }
        }
        
        // ydir is -1 or 1: determines y orientation
        void drawRing(int ydir) {
            noFill();
//            strokeWeight(0.1 + 2 * shift2);
//            stroke(255);
            strokeWeight(1 + ((float) index) / SPEC_SIZE * 4);
            beginShape(LINES);
            for (int i = 0; i < points.length + 1; i++) {
                Point curr = points[i % points.length];
                Point next = points[(i + 1) % points.length]; // last index -> zero index
                curr.setColor();
                vertex(curr.pos.x, curr.pos.y * ydir, curr.pos.z);
                vertex(next.pos.x, next.pos.y * ydir, next.pos.z);
                Point oneDeeper = points[i % points.length].next;
                if (this.index != 0) {
                    vertex(curr.pos.x, curr.pos.y * ydir, curr.pos.z);
                    oneDeeper.setColor();
                    vertex(oneDeeper.pos.x, oneDeeper.pos.y * ydir, oneDeeper.pos.z);
                    
                }
            }
            
            // if auto rotating, then draws an extra smaller ring before rotating again
            if (dropLevel1 && this.index != 0) {
                for (int i = 0; i < rings[index - 1].points.length + 1; i++) {
                    Point curr = rings[index - 1].points[i % rings[index - 1].points.length];
                    Point next = rings[index - 1].points[(i + 1) % rings[index - 1].points.length]; // last index -> zero index
                    curr.setColor();
                    vertex(curr.pos.x, curr.pos.y * ydir, curr.pos.z);
                    vertex(next.pos.x, next.pos.y * ydir, next.pos.z);
                }
            }

            endShape();
        }
        
        // returns float array of colors {r, g, b, alpha} given an intensity (should be y value of a point)
        float[] getColor(float intensity) {
    //        float intensity = 0.5 * getIntensity(index);
    //        float c = pow((PEAK - intensity) / PEAK, 5.0 / 6.0);
    //        float c = (PEAK - intensity) / PEAK;
            intensity = -intensity;
            float red1 = tracker.red;
            float green1 = tracker.green;
            float blue1 = tracker.blue;
            float red2 = 255 - tracker2.red;
            float green2 = 255 - tracker2.green;
            float blue2 = 255 - tracker2.blue;
            
            float shift2 = intensity / PEAK;
            float shift1 = 1 - shift2;
            
            float r = red1 * shift1 + red2 * shift2;
            float g = green1 * shift1 + green2 * shift2;
            float b = blue1 * shift1 + blue2 * shift2;
            float alpha = min(5 + 255 * shift2, 255);
            
    //        stroke(r, g, b, alpha);
            float[] result = {r, g, b, alpha};
            return result;
        }
    }
    
    class Point {
        EPVector pos;
        Point next;
        float angle;
        int size, index;
        float[] colors;
        
        Point(EPVector pos, float angle, int size, int index) {
            this.pos = pos;
            this.angle = angle;
            this.size = size;
            this.index = index;
            next = null;
            colors = new float[4];
        }
        
        void update(int index) {
            if (pos.y < 0) {
                pos.y += DECAY + abs(pos.y / 20);
                pos.y = min(0, pos.y);
            }
            float incomingSignal = -1.5 * getIntensity(index);
            if (pos.y > incomingSignal) {
                pos.y = incomingSignal;    
            }

        }
        
        //call twist before drawing
        void twist(float xRot, float yRot) {
            pos.rotateX(xRot);
            pos.rotateY(yRot);   
        }
        
        //call untwist after drawing (with same values for xRot and yRot as twist!!!);
        void untwist(float xRot, float yRot) {
            pos.rotateY(-yRot);
            pos.rotateX(-xRot);    
        }
        
        // ringIndex must not equal zero
        Point findNearestOneDeeper(int ringIndex) {
            int nearestIndex = 0;
            float closestDist = PVector.dist(pos, rings[ringIndex - 1].points[nearestIndex].pos);
            for (int i = 1; i < rings[ringIndex - 1].points.length; i++) {
                float currentDist = PVector.dist(pos, rings[ringIndex - 1].points[i].pos);
                if (currentDist < closestDist) {
                    nearestIndex = i;
                    closestDist = currentDist;
                }
            }
            return rings[ringIndex - 1].points[nearestIndex];
        }
        
        //converts alpha value to a ratio and multplies every color by that ratio (lets us use blend modes)
        void setColor() {
            float ratio = colors[3] / 255;
            stroke(colors[0] * ratio, colors[1] * ratio, colors[2] * ratio); 
        }
    }
    
    class RotationTracker {
        float xRot, yRot, xStart, yStart, xEnd, yEnd;
        boolean manualRotate, autoRotate, rotating;
        int currentTime, moveTime;
        
        RotationTracker() {
            xRot = 0;
            yRot = 0;
            manualRotate = false;
            autoRotate = false;
            rotating = false;    
        }
        
        void autoSwitch() {
            autoRotate = !autoRotate;
            manualRotate = false; 
        }
        
        void manualSwitch() {
            manualRotate = !manualRotate;
            autoRotate = false;
            rotating = false;  
        }
        
        void initRotate(float xDestination, float yDestination, int time) {
            xStart = xRot;
            yStart = yRot;
            xEnd = xDestination;
            yEnd = yDestination;
            moveTime = time; 
            currentTime = 0;
            rotating = true; 
        }
        
        void update() {
            if (manualRotate) {
                xRot = map(mouseX, 0, width, 0, PI);    
                yRot = map(mouseY, 0, height, 0, PI); 
            }   
            
            if (autoRotate && !rotating) {
                float x = random(0, PI);
                float y = random(0, PI);
                float dist = sqrt(sq(x) + sq(y));
                int baseLine = (int) random(5 * frameRate, 10 * frameRate);
                int time = baseLine + (int)(75 * frameRate * (dist / PI));
                initRotate(x, y, time);
            }
            
            if (rotating) {
                float angle = (currentTime*1.0 / moveTime) * PI;
    
                float xAmp = ((xEnd - xStart) * PI) / (2 * moveTime);
                float dx = xAmp * sin(angle);
                xRot += dx;
                
                float yAmp = ((yEnd - yStart) * PI) / (2 * moveTime);
                float dy = yAmp * sin(angle);
                yRot += dy;
                
                currentTime++;
                if (currentTime == moveTime) {
                    rotating = false;    
                }
            }
        } 
    }
    
    synchronized void draw() {
        retrieveSound();
        setBackground(contrast, 200);
        
        pushMatrix();
        rotater.update();
        camera.update();
        tracker.incrementColor();
        tracker2.incrementColor();
        for (int i = 0; i < rings.length; i++) {
            rings[i].update();
        }
        
        // if the camera is above the figure, the bottom rings are drawn last. If the camera is below the figure,
        // the top rings are drawn last.
        
        if (camera.pos.y > 0) { 
            drawInOrder(1, -1);
        } else {
            drawInOrder(-1, 1);
        } 

        popMatrix();
        
        if (showInterface) {
            displayDebugText();
            displayHelpMenu();
        }
    }
    
    void drawInOrder(int front, int behind) {
        int mult;
        int order;
        for (int i = (rings.length - 1) * 2; i >= 0; i--) {
            if (i > rings.length - 1) {
                order = front;    
            } else {
                order = behind;    
            }
            if (i % (rings.length - 1) > 5) {
                mult = i;
            } else {
                mult = 5;
            }
            rotateX(rotater.xRot * mult);
            rotateY(rotater.yRot * mult);
            rings[i % (rings.length - 1)].drawRing(order);
            rotateY(-rotater.yRot * mult);
            rotateX(-rotater.xRot * mult);
        }
    }
    
    // returns intensity of a certain index within the bandsize, and scales it with volumeScale 
    float getIntensity(int index) {
        return abs(fft.getBand(index) * 0.8 * volumeScale);
    }
    
    void displayDebugText() {
        fill(255 - contrast);
        stroke(255 - contrast);
        textSize(14);
        text("xRot: " + (int)(degrees(rotater.xRot) * 1000) / 1000.0, 5, height - 55);
        text("yRot: " + (int)(degrees(rotater.yRot) * 1000) / 1000.0, 5, height - 40);
        text("current frame rate: " + round(frameRate), 5, height - 25);    
        text(camera.pos.x + ", " + camera.pos.y + ", " + camera.pos.z, 5, height - 10);
    }
    
    void displayHelpMenu() {
        textSize(14);
        textAlign(LEFT, TOP);
        
        toggleTextColor(!showInterface);
        text("[h] hide interface", TEXT_OFFSET, 15);
        toggleTextColor(contrast == 0);
        text("[d] dark mode", TEXT_OFFSET, 30);
        toggleTextColor(frontalView);
        text("[f] frontal camera view", TEXT_OFFSET, 45);
        toggleTextColor(topDownView);
        text("[t] top-down camera view", TEXT_OFFSET, 60);
        toggleTextColor(dropLevel1);
        text("[1] drop level 1", TEXT_OFFSET, 75);
        toggleTextColor(camera.autoPanningMode);
        text("[a] auto panning mode", TEXT_OFFSET, 90);

    }
    
    void toggleTextColor(boolean toggled) {
        if (toggled) {
            fill(255, 100, 100);
        } else {
            fill(abs(150-contrast), abs(150-contrast), abs(150-contrast));
        }
    }
    
    void keyPressed() {
        switch (key) {
            case 'v': 
                camera.viewSwitch(); 
                break;
            case 'a':
                camera.autoPanSwitch();
                camera.dirSwitch();
                frontalView = false;
                topDownView = false;
                break;
            case '1':
                dropLevel1 = !dropLevel1;
                rotater.autoSwitch();
                if (!dropLevel1) {
                    rotater.initRotate(0, 0, (int) frameRate * 10);    
                }
                break;
            case 'd':
                contrast = 255 - contrast;
                break;
            case 'm': 
                dropLevel1 = false;
                rotater.manualSwitch();
                break;
            case 'f': 
                frontalView = true;
                topDownView = false;
                camera.disableAllModes();
                camera.initMoveCamera(new PVector(0, 0, 400), (int) frameRate * 2);
                camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate * 2);
                break;
            case 't':
                topDownView = true;
                frontalView = false;
                camera.disableAllModes();
                camera.initMoveCamera(new PVector(0, -400, 0), (int) frameRate * 2);
                camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate * 2);
                break;
            default:
                break;
        }
    }
}
