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
    final float DECAY = PHI; // DECAY = -y per frame
    final int MAX_DECAY = 100;
    final int PEAK = 40;
    int dropletSize = 10;

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
        setupDroplet();
        noCursor();
    }
    

    void setupDroplet(){
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
    }
    
    class Ring {
        int index, size;
        Point[] points;
        
        // 0 index Ring has a boost in detail
        Ring(int radius, int index) {
            this.index = index;
//            size = (int) (radius * DETAIL + 1);
//            if (index == 0) {
//                size += 5;  
//            }
            size = dropletSize;
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
                points[i].colors = getColor(points[i].pos.y, tracker, tracker2, PEAK);
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
            if(particles){
                beginShape(POINTS);
            } else{
                beginShape(LINES);
            }
            for (int i = 0; i < points.length + 1; i++) {
                Point curr = points[i % points.length];
                Point next = points[(i + 1) % points.length]; // last index -> zero index
                curr.setColor();
                if(particles){
                    strokeWeight(max(abs(curr.pos.y/10), 1));
                }
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
                pos.y = lerp(pos.y, 0, .06180339887);
//                pos.y += DECAY + abs(pos.y / 20);
//                pos.y = min(0, pos.y);
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
    
    synchronized void draw() {
        retrieveSound();
        if(blur) {
            setBackground(contrast, 50);
        } else {
            setBackground(contrast, 150);
        }
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
    
    void revolve(){
        rotater.autoSwitch();
        if (!revolve) {
            rotater.initRotate(0, 0, (int) frameRate * 10);    
        }
    }
    void keyPressed() {
        super.keyPressed();
        switch (keyCode) {
            case 38 : dropletSize+=2;
                      setupDroplet();
                      break;
            case 40 : if(dropletSize>2){
                        dropletSize-=2;
                        setupDroplet();
                      }
                      break;
        }
    }
}
