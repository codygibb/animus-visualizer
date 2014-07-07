class RotationTracker {
    float xRot, yRot, zRot, xStart, yStart,zStart, xEnd, yEnd, zEnd;
    boolean manualRotate, autoRotate, rotating;
    int currentTime, moveTime;
    
    RotationTracker() {
        xRot = 0;
        yRot = 0;
        zRot = 0;
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
        initRotate(xDestination, xDestination, 0, time);
    }
    
    void initRotate(float xDestination, float yDestination, float zDestination, int time) {
        xStart = xRot;
        yStart = yRot;
        zStart = zRot;
        xEnd = xDestination;
        yEnd = yDestination;
        zEnd = zDestination;
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
            float z = random(0, PI);
            float dist = sqrt(sq(x) + sq(y)+sq(z));
            int baseLine = (int) random(5 * frameRate, 10 * frameRate);
            int time = baseLine + (int)(75 * frameRate * (dist / PI));
            initRotate(x, y, z, time);
        }
        
        if (rotating) {
            float angle = (currentTime*1.0 / moveTime) * PI;

            float xAmp = ((xEnd - xStart) * PI) / (2 * moveTime);
            float dx = xAmp * sin(angle);
            xRot += dx;
            
            float yAmp = ((yEnd - yStart) * PI) / (2 * moveTime);
            float dy = yAmp * sin(angle);
            yRot += dy;
            
            float zAmp = ((zEnd - zStart) * PI) / (2 * moveTime);
            float dz = zAmp * sin(angle);
            zRot += dz;
            
            currentTime++;
            if (currentTime == moveTime) {
                rotating = false;    
            }
        }
    } 
}
