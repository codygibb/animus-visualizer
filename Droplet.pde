import ddf.minim.*;

class Droplet extends Visualizer {
    final int OPTIMAL_FRAME_RATE = 35;

    @Override
    int getOptimalFrameRate() {
        return OPTIMAL_FRAME_RATE;
    }

    
    final int SPEC_SIZE = 50;
    final int SPEC_WIDTH = 7;
    final float DETAIL = 1.1; // DETAIL * radius of ring "i" = number of points in ring "i"
    final float DECAY = 0.3; // DECAY = -y per frame
    final int MAX_DECAY = 100;
    final int PEAK = 40;
    final float MAX_EXPAND = 0.6;
    final float EXPAND_RATE = 0.02;

    int dropletSize = 10;
    
    float currExpand = 0;
    

    // since we need 4 different color trackers -- base and peak colors for both
    // bottom and top halves -- stored all dem in an array
    // colorTrackers[0] -> base tracker for bottom half
    // colorTrackers[1] -> peak tracker for bottom half
    // colorTrackers[2] -> base tracker for top half
    // colorTrackers[3] -> peak tracker for top half
    ColorTracker[] colorTrackers;

    // ColorTracker tracker;
    // ColorTracker tracker2;
    Ring[] rings;
    RotationTracker rotater;

    Droplet(AudioInput input) {
        super(input, "Droplet");
        camera.pos = new PVector(0, 0, 400);
        float n = SPEC_SIZE * SPEC_WIDTH;
        camera.setOuterBounds(-n, -n * 1.2, -n, n, n * 1.2, n);
        camera.setInnerBounds(-n / 4, 0, - n / 4, n / 4, 0, n / 4);
        camera.viewSwitch();
        // tracker = new ColorTracker();
        // tracker2 = new ColorTracker();
        colorTrackers = new ColorTracker[4];
        for (int i = 0; i < colorTrackers.length; i++) {
            colorTrackers[i] = new ColorTracker();
        }
        rotater = new RotationTracker();
        rings = new Ring[SPEC_SIZE];
        setupDroplet();
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
            size = dropletSize;
            points = new Point[size];
            for (int i = 0; i < points.length; i++) {
                float angle = TWO_PI * i / points.length;
                EPVector pos = new EPVector(radius, 0, 0);
                pos.rotateY(angle);
                points[i] = new Point(pos, angle, size, index);
            }
        }

        //converts alpha value to a ratio and multplies every color by that ratio (lets us use blend modes)
        void setColor(float[] colors) {
            float ratio = colors[3] / 255;
            stroke(colors[0] * ratio, colors[1] * ratio, colors[2] * ratio); 
        }
        
        void update() {
            for (int i = 0; i < points.length; i++) {
                points[i].update(index);
                points[i].botColors = getColor(-points[i].pos.y, colorTrackers[0], colorTrackers[1], PEAK);
                points[i].topColors = getColor(-points[i].pos.y, colorTrackers[2], colorTrackers[3], PEAK);
            }
        }
        
        // ydir is -1 or 1: determines whether the figure is draw top up or top down
        void drawRing(int ydir) {
            noFill();
            if (expand) {
                strokeWeight(1 + ((float) index) / SPEC_SIZE * 10);
            } else {
                strokeWeight(1 + ((float) index) / SPEC_SIZE * 4);
            }
            if (particles) {
                beginShape(POINTS);
            } else {
                beginShape(LINES);
            }
            for (int i = 0; i < points.length + 1; i++) {
                Point curr = points[i % points.length];
                Point next = points[(i + 1) % points.length]; // last index -> zero index
                if (ydir > 0) {
                        setColor(curr.botColors);
                    } else {
                        setColor(curr.topColors);
                    }
                if (particles) {
                    strokeWeight(max(abs(curr.pos.y / 10), 1));
                }
                vertex(curr.pos.x, getExpandedY(curr) * ydir, curr.pos.z);
                vertex(next.pos.x, getExpandedY(next) * ydir, next.pos.z);
                if (currExpand > 0) {
                    vertex(curr.pos.x, curr.pos.y * ydir, curr.pos.z);
                    vertex(next.pos.x, next.pos.y * ydir, next.pos.z);
                }
                Point oneDeeper = points[i % points.length].next;
                if (this.index != 0) {
                    vertex(curr.pos.x, curr.pos.y * ydir, curr.pos.z);
                    if (ydir > 0) {
                        setColor(oneDeeper.botColors);
                    } else {
                        setColor(oneDeeper.topColors);
                    }
                    vertex(oneDeeper.pos.x, getExpandedY(oneDeeper) * ydir, oneDeeper.pos.z); 
                }
            }
            
            // if auto rotating, then draws an extra smaller ring before rotating again
            if (revolve && this.index != 0) {
                for (int i = 0; i < rings[index - 1].points.length + 1; i++) {
                    Point curr = rings[index - 1].points[i % rings[index - 1].points.length];

                    // last index -> zero index
                    Point next = rings[index - 1].points[(i + 1) % rings[index - 1].points.length];
                    
                    if (ydir > 0) {
                        setColor(curr.botColors);
                    } else {
                        setColor(curr.topColors);
                    }
                    vertex(curr.pos.x, getExpandedY(curr) * ydir, curr.pos.z);
                    vertex(next.pos.x, getExpandedY(next) * ydir, next.pos.z);  
                }
            }

            endShape();
        }
        
        float getExpandedY(Point p) {
            if (currExpand > 0) {
                return p.pos.y - currExpand * sqrt(sq(p.pos.x) + sq(p.pos.z));
            } else {
                return p.pos.y;
            }
        }
    }
    
    class Point {
        EPVector pos;
        Point next;
        float angle;
        int size, index;

        // we are re-using the same samples to draw both bottom and top - but bottom and top need
        // different NON-COMPLEMENTARY colors. so each point keeps track of the two set of colors
        // it will display as
        float[] botColors;
        float[] topColors;
        
        Point(EPVector pos, float angle, int size, int index) {
            this.pos = pos;
            this.angle = angle;
            this.size = size;
            this.index = index;
            next = null;
            botColors = new float[4];
            topColors = new float[4];
        }
        
        void update(int index) {
            if (pos.y < 0) {
                pos.y = lerp(pos.y, 0, .06180339887);
            }
            float incomingSignal = -1.5 * getIntensity(index);
            if (pos.y > incomingSignal) {
                pos.y = incomingSignal;    
            }
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
    }
    
    @Override
    void draw() {
        retrieveSound();
        if(blur) {
            setBackground(contrast, 50);
        } else {
            setBackground(contrast, 150);
        }
        
        if (expand && currExpand < MAX_EXPAND) {
            currExpand += EXPAND_RATE;
        } else if (!expand && currExpand > 0) {
            currExpand -= EXPAND_RATE;    
        }

        pushMatrix();
        rotater.update();
        camera.update();
        for (ColorTracker ct : colorTrackers) {
            ct.incrementColor();
        }
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
    void revolve() { 
        revolve = !revolve;
        rotater.autoSwitch();
        if (!revolve) {
            rotater.initRotate(0, 0, (int) frameRate * 10);    
        }
    }
    
    @Override
    void frontView() {
        camera.initMoveCamera(new PVector(0, 0, 400), (int) frameRate);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }
    
    @Override
    void rearView() {
        // TODO
    }
    
    @Override
    void topView() { 
        camera.initMoveCamera(new PVector(0, -400, 0), (int) frameRate);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }
 
    void keyPressed() {
        super.keyPressed();
        switch (keyCode) {
            case 38:
                dropletSize += 2;
                setupDroplet();
                break;
            case 40:
                if (dropletSize > 2) {
                    dropletSize -= 2;
                    setupDroplet();
                }
                break;
            default:
                break;
        }
    }
}
