import ddf.minim.*;

public class Droplet extends Visualizer {
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
            if (revolve && this.index != 0) {
                for (int i = 0; i < rings[index - 1].points.length + 1; i++) {
                    Point curr = rings[index - 1].points[i % rings[index - 1].points.length];

                    // last index -> zero index
                    Point next = rings[index - 1].points[(i + 1) % rings[index - 1].points.length];

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
        // TODO
    }

    void revolve() {
        revolve = !revolve;
        rotater.autoSwitch();
        if (!revolve) {
            rotater.initRotate(0, 0, (int) frameRate * 10);    
        }
    }
    
    void frontView() {
        camera.initMoveCamera(new PVector(0, 0, 400), (int) frameRate * 2);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate * 2);
    }
    
    void rearView() {
        // TODO
    }
    
    void topView() { 
        camera.initMoveCamera(new PVector(0, -400, 0), (int) frameRate * 2);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate * 2);
    }
}
