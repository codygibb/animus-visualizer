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
    final float DECAY = 0.25; // DECAY = -y per frame
    final int MAX_DECAY = 100;
    final int PEAK = 40;
    final float EXPAND_RATE = 0.02;
    final float HIGHLIGHT_POINT_STOP = 80;

    int dropletSize = 2;
    
    float currExpand = 0;

    // since we need 4 different color trackers -- base and peak colors for both
    // bottom and top halves -- stored all dem in an array
    // colorTrackers[0] -> base tracker for bottom half
    // colorTrackers[1] -> peak tracker for bottom half
    // colorTrackers[2] -> base tracker for top half
    // colorTrackers[3] -> peak tracker for top half
    ColorTracker[] colorTrackers;
    
    Ring[] rings;
    RotationTracker rotater;

    Droplet(AudioInput input) {
        super(input, "DROPLET");
        camera.pos = new PVector(0, 0, 400);
        float n = SPEC_SIZE * SPEC_WIDTH;
        camera.setOuterBounds(-n, -n * 1.2, -n, n, n * 1.2, n);
        camera.setInnerBounds(-n / 4, 0, - n / 4, n / 4, 0, n / 4);
        camera.viewSwitch();
        colorTrackers = new ColorTracker[4];
        for (int i = 0; i < colorTrackers.length; i++) {
            colorTrackers[i] = new ColorTracker(0.5, 4);
        }
        rotater = new RotationTracker();
        rings = new Ring[SPEC_SIZE];
        setupDroplet();
    }
    
    void setupDroplet(){
        for (int i = 0; i < rings.length; i++) {
            int radius = SPEC_WIDTH * (i + 1);
            int pointNum = (particles) ?  dropletSize : dropletSize * (i + 1);
            int hpointNum = dropletSize * (i + 1) / 10;

            rings[i] = new Ring(radius, i, pointNum, hpointNum);
        }
        for (int i = rings.length - 1; i >= 0; i--) {
            for (int j = 0; j < rings[i].points.length; j++) {
                if (i != 0) {
                    rings[i].points[j].oneDeeper = rings[i].points[j].findNearestOneDeeper(i);
                }
            }
        }
    }
    
    class Ring {
        int index, expandTick;
        Point[] points;
        HighlightPoint[] hpoints;
        
        // allow HighlightPoints to access the same base fade that each ring has
        // (they will be doing some additional fading on top of that as well)
        float baseFade;
        
        // 0 index Ring has a boost in detail
        Ring(int radius, int index, int pointNum, int hpointNum) {
            this.index = index;
            expandTick = index;

            points = new Point[pointNum];
            for (int i = 0; i < points.length; i++) {
                float angle = TWO_PI * i / points.length;
                EPVector pos = new EPVector(radius, 0, 0);
                pos.rotateY(angle);
                points[i] = new Point(pos, index);
            }

            hpoints = new HighlightPoint[hpointNum];
            for (int i = 0; i < hpoints.length; i++) {
                float angle = random(0, TWO_PI);
                EPVector pos = new EPVector(radius, 0, 0);
                pos.rotateY(angle);
                float size = random(1, 3);
                float speed = random(0.8, 1.1);
                hpoints[i] = new HighlightPoint(pos, speed, size);
            }
        }

        //converts alpha value to a ratio and multplies every color by that ratio (lets us use blend modes)
        void setColor(float[] colors) {
            float fade = colors[3] / 255;
            fade += currExpand;
            fade = min(fade, 1);

            // slightly fades the outer edges of the plane
            fade *= pow((SPEC_SIZE - index) * 1.0 / SPEC_SIZE, 5.0 / 6.0);

            // set baseFade so that the HighlightPoints can access this fading when they have to set their
            // color
            baseFade = fade;
            
            stroke(colors[0] * fade, colors[1] * fade, colors[2] * fade); 
        }
        
        void update() {
            expandTick--;
            // expandTick %= SPEC_SIZE;
            for (int i = 0; i < points.length; i++) {
                points[i].update(index, expandTick);
                points[i].botColors = getColor(-points[i].naturalY, PEAK, colorTrackers[0], colorTrackers[1]);
                points[i].topColors = getColor(-points[i].naturalY, PEAK, colorTrackers[2], colorTrackers[3]);
            }

            float incomingSignal = getIntensity(index) / 2;
            // float incomingSignal = getGreatestMag(SPEC_SIZE) / 3;
            for (HighlightPoint hp : hpoints) {
                hp.update(incomingSignal);
            }
        }
        
        // ydir is -1 or 1: determines whether the figure is draw top up or top down
        void drawRing(int ydir) {
            noFill();

            // float strokeFactor = (expand) ? 4 : 2;
            // strokeWeight(1 + ((float) index) / SPEC_SIZE * strokeFactor);
            strokeWeight(1.5);

            if (particles) {
                beginShape(POINTS);
            } else {
                beginShape(LINES);
            }

            for (int i = 0; i < points.length; i++) {
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
                vertex(curr.pos.x, curr.pos.y * ydir, curr.pos.z);
                vertex(next.pos.x, next.pos.y * ydir, next.pos.z);

                Point oneDeeper = points[i % points.length].oneDeeper;
                if (this.index != 0) {
                    vertex(curr.pos.x, curr.pos.y * ydir, curr.pos.z);
                    if (ydir > 0) {
                        setColor(oneDeeper.botColors);
                    } else {
                        setColor(oneDeeper.topColors);
                    }
                    vertex(oneDeeper.pos.x, oneDeeper.pos.y * ydir, oneDeeper.pos.z); 
                }
            }
            
            // if auto rotating, then draws an extra smaller ring before rotating again
            // (this makes sure that we don't have unconnected lines showing)
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
                    vertex(curr.pos.x, curr.pos.y * ydir, curr.pos.z);
                    vertex(next.pos.x, next.pos.y * ydir, next.pos.z);  
                }
            }

            endShape();

            float baseY = points[0].pos.y;
            float[] c = (ydir > 0) ? points[0].botColors : points[0].topColors;
            for (HighlightPoint hp : hpoints) {
                hp.drawHighlightPoint(baseY, ydir, c, baseFade);
            }
        }
    }
    
    class Point {
        EPVector pos;

        // always use point.expandedY , the expandedY will
        // store the natural y position of the point + whatever expansion amt we need.
        // obviously the expansion amt is zero when not expanding, so during those times
        // expandedY will just hold the natural y position
        float naturalY;

        // we are re-using the same samples to draw both bottom and top - but bottom and top need
        // different NON-COMPLEMENTARY colors. so each point keeps track of the two set of colors
        // it will display as
        float[] botColors;
        float[] topColors;

        Point oneDeeper;
        int index;
 
        Point(EPVector pos, int index) {
            this.pos = pos;
            naturalY = pos.y;
            this.index = index;
            oneDeeper = null; 
            botColors = new float[4];
            topColors = new float[4];   
        }
        
        void update(int index, int expandTick) {
            if (naturalY < 0) {
                naturalY += DECAY + abs(naturalY / 20);
                naturalY = min(0, naturalY);
            }
            float incomingSignal = -1.5 * getIntensity(index);
            if (naturalY > incomingSignal) {
                naturalY = incomingSignal;    
            }
            pos.y = getExpandedY(expandTick);
        }
        
        // finds the equivalent Point to this Point that is located on a ring
        // one deeper than this Point's current ring
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

        float getExpandedY(int expandTick) {
            if (currExpand > 0) {
                // expandTick is decremented in update. keeps the sin wave moving forward.
                // "- currExpand * amp" shifts the planes vertically apart so the waves don't 
                // overlap
                float time = TWO_PI * expandTick / SPEC_SIZE * 1.3;
                float amp = 40 * sqrt(index * 1.0 / SPEC_SIZE);
                return naturalY - currExpand * amp * sin(time) - currExpand * amp;
            } else {
                return naturalY;
            }
        }
    }

    class HighlightPoint {
        float speed, size;
        EPVector pos;
        boolean continueHighlighting;

        HighlightPoint(EPVector pos, float speed, float size) {
            this.speed = speed;
            this.size = size;
            this.pos = pos;
        }

        void update(float intensity) {
            if (continueHighlighting) {
                pos.y -= intensity;
                pos.y -= speed;
            }
            if (abs(pos.y) >= HIGHLIGHT_POINT_STOP) {
                if (!highlight) {
                    continueHighlighting = false;
                }
                pos.y = 0;
                float angle = random(0, TWO_PI);
                pos.rotateY(angle);
            }
        }

        void drawHighlightPoint(float baseY, float ydir, float[] colors, float baseFade) {
            if (continueHighlighting) {
                float fade = 1 - abs(pos.y) / HIGHLIGHT_POINT_STOP;
                fade *= baseFade;
                stroke((255 - colors[0]) * fade, (255 - colors[1]) * fade, (255 - colors[2]) * fade);

                pushMatrix();
                // strokeWeight(size * 4);
                // point(pos.x, (baseY + pos.y) * ydir, pos.z);
                translate(pos.x, (baseY + pos.y) * ydir, pos.z);
                box(size);
                
                popMatrix();
            }
        }
    }
    
    @Override
    void draw() {
        if (blur) {
            setBackground(contrast, 50);
        } else {
            setBackground(contrast, 150);
        }

        if (expand && currExpand < 1) {
            currExpand += EXPAND_RATE;
        } else if (!expand && currExpand > 0) {
            currExpand -= EXPAND_RATE;    
        }

        if (!expand && currExpand < 0) {
            currExpand = 0;
        }

        if (expand && currExpand > 1) {
            currExpand = 1;
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

            // the first 5 rings are rotated together
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
        setupDroplet();
    }

    @Override
    void highlight() {
        for (Ring r : rings) {
            for (HighlightPoint hp : r.hpoints) {
                hp.continueHighlighting = true;
            }
        }
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
        camera.initMoveCamera(new PVector(0, 0, 400), (int) frameRate * 2);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate * 2);
    }
    
    @Override
    void rearView() {
        // TODO
    }
    
    @Override
    void topView() { 
        camera.initMoveCamera(new PVector(0, -400, 0), (int) frameRate * 2);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate * 2);
    }
    
    @Override
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
