class Gravity extends Visualizer {
    int OPTIMAL_FRAME_RATE = 40;
    public int getOptimalFrameRate() {
        return OPTIMAL_FRAME_RATE;
    }
    
    final int PARTICLE_NUM = 500;
    final float MAX_RADIUS = 400;
    final float MAX_VELOCITY = 5;
    final int HOTSPOT_NUM = 5;
    final int SPEC_SIZE = 50;
    final float MAX_WEIGHT = 0.1;
    
    Particle[] particles;
    HotSpot[] hotSpots;
    ColorTracker tracker;

    Gravity(AudioInput input) {
        super(input, "Gravity");    
        tracker = new ColorTracker();
        particles = new Particle[PARTICLE_NUM];
        for (int i = 0; i < particles.length; i++) {
            PVector pos = PVector.random3D();
            pos.setMag(random(0, MAX_RADIUS));
            particles[i] = new Particle(pos.x, pos.y, pos.z, MAX_VELOCITY);
            PVector velocity = PVector.random3D();
            velocity.setMag(random(0, MAX_VELOCITY));
//            particles[i].velocity = velocity;
        }
        
        hotSpots = new HotSpot[HOTSPOT_NUM];
        for (int i = 0; i < hotSpots.length; i++) {
//            PVector pos = PVector.random3D();
//            pos.setMag(random(0, MAX_RADIUS));
            PVector pos = PVector.random3D();
            pos.setMag(i * (MAX_RADIUS / HOTSPOT_NUM));
            int[] freqs = new int[SPEC_SIZE / HOTSPOT_NUM];
            for (int j = 0; j < freqs.length; j++) {
                freqs[j] = i * freqs.length + j;
            }
            hotSpots[i] = new HotSpot(pos.x, pos.y, pos.z, freqs);
        }
    }
    
    class Particle {
        PVector pos;
        PVector velocity;
        PVector acceleration;
        float topSpeed;
    
        Particle(float initX, float initY, float initZ, float topSpeed) {
            pos = new PVector(initX, initY, initZ);
            velocity = new PVector(0, 0, 0);
            acceleration = new PVector(0, 0, 0);  
            this.topSpeed = topSpeed;
        }
    
        void update(float weight) {
            acceleration.setMag(weight);
            velocity.add(acceleration);
            velocity.limit(topSpeed);
            pos.add(velocity);
        }
        
        void drawParticle() {
            pushMatrix();
            translate(pos.x, pos.y, pos.z);
            fill(255);
            stroke(255);
            strokeWeight(1);
            box(1.3);
            popMatrix();
        }
    }
    
    class HotSpot {
        PVector pos;
        float weight;
        int[] freqs;
        
        HotSpot(float initX, float initY, float initZ, int[] freqs) {
            this.pos = new PVector(initX, initY, initZ);
            this.weight = 0;  
            this.freqs = freqs;
        }
        
        void update() {
            float avg = 0;
            for (int i = 0; i < freqs.length; i++) {
                avg += fft.getBand(freqs[i]) * volumeScale;
            }
            avg = avg / freqs.length;
            weight = avg / 500;
            weight = min(weight, MAX_WEIGHT);
        }
        
        void drawHotSpot() {
            pushMatrix();
            translate(pos.x, pos.y, pos.z);
            noFill();
            tracker.setColor(false, true);
            strokeWeight(2.5);
            box(weight * 1000);
            popMatrix();    
        }
    }

    synchronized void draw() {
        retrieveSound();
        setBackground(contrast, 255);
        pushMatrix();
        camera.update();
        tracker.incrementColor();
        noFill();

        float topFreq = 0;
        for (int i = 0; i < 100; i++) {
            if (fft.getBand(i) < topFreq) {
                topFreq = fft.getBand(i);
            }
        }
        
        for (HotSpot h : hotSpots) {
            h.update();
            h.drawHotSpot();
        }
        
        for (Particle p : particles) {
            for (int i = 0; i < hotSpots.length; i++) {
                p.acceleration = PVector.sub(hotSpots[i].pos, p.pos);
                p.update(hotSpots[i].weight);
            }
            
            p.drawParticle();
        }

        popMatrix();
    }

    void keyPressed() {
    }
    
}

