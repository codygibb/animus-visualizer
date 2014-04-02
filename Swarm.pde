class Swarm extends Visualizer {
    int OPTIMAL_FRAME_RATE = 50;
    public int getOptimalFrameRate() {
        return OPTIMAL_FRAME_RATE;
    }
    
    SwarmColorTracker colorTracker;
    
    HotSpot[] hotSpots;
    Particle[] particles;
    boolean showParticles = false;
    
    Swarm(AudioInput input) {
        super(input, "Swarm");   
        camera.setOuterBounds(-800, -800, -800, 800, 800, 800);
        colorTracker = new SwarmColorTracker();
        hotSpots = new HotSpot[50];
        for (int i = 0; i < hotSpots.length; i++) {
            float x = random(-150, 150);
            float y = random(-150, 150);
            float z = random(-150, 150);
            hotSpots[i] = new HotSpot(x, y, z, i*2);
        }
    
        particles = new Particle[2700];
        for (int i = 0; i < particles.length; i++) {
            float x = random(-200, 200);
            float y = random(-200, 200);
            float z = random(-200, 200);
            particles[i] = new Particle(x, y, z, 8);
        }
    }

    class Particle {
        PVector position;
        PVector velocity;
        PVector acceleration;
        float topSpeed;
    
        Particle(float xStart, float yStart, float zStart, float topSpeed) {
            position = new PVector(xStart, yStart, zStart);
            velocity = new PVector(0, 0, 0);
            acceleration = new PVector(0, 0, 0);    
            this.topSpeed = topSpeed;
        }
    
        void update() {
            acceleration.setMag(0.15);
            velocity.add(acceleration);
            velocity.limit(topSpeed);
            position.add(velocity);
            if (showParticles) {
                pushMatrix();
                translate(position.x, position.y, position.z);
                colorTracker.setColor(true, true);
                box(1.3);
//                scale(50);
//                point(position.x, position.y, position.z);
                popMatrix();
            }
        }
    }
    
    class HotSpot {
        PVector position;
        float magnitude;
        int index;
    
        HotSpot(float xPos, float yPos, float zPos, int index) {
            position = new PVector(xPos, yPos, zPos);
            this.index = index;
            magnitude = 0;
        }
    
        void update() {
            magnitude = fft.getBand(index)/7 * volumeScale;
            if (showParticles) {
                pushMatrix();
                translate(position.x, position.y, position.z);
                noFill();
//                colorTracker.setComplementaryColor(true, false);
//                fill(255);
                stroke(75 + magnitude*30);
                strokeWeight(min(1 + magnitude, 5));
                box(5 + min(magnitude * 10, 20));
                popMatrix();
            }
        }
    }
    
    void draw() {
        if (showInterface) {
            displayHelpMenu();
            displayDebugText();
        }
        retrieveSound();
        if (showParticles)
            setBackground(contrast, 100);
        else
            setBackground(contrast, 20);
        
        pushMatrix();
        updateTopMag();
        camera.update();
        colorTracker.incrementColor();
        scale(3);
        float greatestMag = hotSpots[0].magnitude;
        int hotIndex = 0;
        for (int i = 0; i < hotSpots.length; i++) {
            hotSpots[i].update();
            float tempMag = hotSpots[i].magnitude;
            if (tempMag > greatestMag) {
                greatestMag = tempMag;    
                hotIndex = i;
            }
        }
    
        if (!showParticles) {
            strokeWeight(0.01 + greatestMag/5);
//                strokeWeight(0.01 + greatestMag*2);
        } else {
            strokeWeight(1);
        } 

        for (int pIndex = 0; pIndex < particles.length; pIndex++) {
            Particle currentP = particles[pIndex];    
            HotSpot h = hotSpots[hotIndex];
            currentP.acceleration = PVector.sub(h.position, currentP.position);
            currentP.update();
    
            Particle prevP;
            if (pIndex == 0) {
                prevP = particles[particles.length - 1];
            } else if (pIndex == particles.length - 1) {
                prevP = particles[0];
            } else {
                prevP = particles[pIndex - 1];
            }
    
            if (!showParticles) {
                colorTracker.setColor(true, false);
                line(prevP.position.x, prevP.position.y, prevP.position.z, 
                         currentP.position.x, currentP.position.y, currentP.position.z);
            } else {
//                stroke(50);
//                strokeWeight(0.1);
//                line(prevP.position.x, prevP.position.y, prevP.position.z, 
//                         currentP.position.x, currentP.position.y, currentP.position.z);
////                line(h.position.x, h.position.y, h.position.z,
////                         currentP.position.x, currentP.position.y, currentP.position.z);
            }
        }
        
        popMatrix();
    }
    
    void keyPressed() { 
        switch (key) {
            case 'v':
                camera.viewSwitch();
                break;
            case 'a':
                camera.autoPanSwitch();
                camera.dirSwitch();
                break;
            case 'd':
                contrast = 255 - contrast;
                break;
            case 'p':
                showParticles = !showParticles;
                break;
            default:
                break;
        }
    }
    
    float topMag;
    class SwarmColorTracker extends ColorTracker {
         void setColor(boolean strokeOn, boolean fillOn) {
            if (strokeOn)
                stroke(red / 4, green / 4, blue / 4);    
            if (fillOn) {
                fill(red / 4, green / 4, blue / 4);
            }
        }
    }
    
    void updateTopMag() {
        float top = 0;
        for (int i = 0; i < 50; i++) {
            if (fft.getBand(i) > top) {
                top = abs(fft.getBand(i));   
            }
        }
        topMag = top;
    }
    
    void displayDebugText() {
        fill(255 - contrast);
        stroke(255 - contrast);
        textSize(14);
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
        toggleTextColor(this.camera.viewingMode);
        text("[v] viewing mode", TEXT_OFFSET, 45);
        toggleTextColor(this.camera.autoPanningMode);
        text("[a] auto pan mode", TEXT_OFFSET, 60);
        toggleTextColor(this.showParticles);
        text("[p] particle mode", TEXT_OFFSET, 75);
    }
    
    void toggleTextColor(boolean toggled) {
        if (toggled) {
            fill(255, 100, 100);
        } else {
            fill(abs(150-contrast), abs(150-contrast), abs(150-contrast));
        }
    }
}
