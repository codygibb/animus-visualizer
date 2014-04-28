public class Camera {
    PVector pos; //current position of camera
    PVector center; //center view for camera
    PVector dir; //"up" of camera;
    
    PVector moveStart; //saves the initial panning coordinates
    PVector moveEnd; //ending panning coordinates
    boolean movingCamera; //boolean storing whether camera is panning
    int moveTime; //total time to move from moveStart to moveEnd
    int currentTime; //current time while panning
    
    PVector dirStart;
    PVector dirEnd;
    boolean movingDir;
    int mDirTime;
    int mDirCurrTime;
    
    PVector mCenterStart;
    PVector mCenterEnd;
    boolean movingCenter;
    int mCenterTime;
    int mCenterCurrTime;
    
    boolean viewingMode; //true: free panning on
    boolean autoPanningMode; //true: auto panning on
    boolean autoDirChangeMode;
    
    PVector leftOuterBounds; //leftmost x, y, z auto panning bounds (generally negative)
    PVector rightOuterBounds; //rightmost x, y, z auto panning bounds (generally positive)
    PVector leftInnerBounds;
    PVector rightInnerBounds;
    
    Camera(float initX, float initY, float initZ) {
        pos = new PVector(initX, initY, initZ);
        dir = new PVector(0, 1, 0);
        center = new PVector(0, 0, 0);
        moveStart = new PVector(width/2, height/2, height/2);
        moveEnd = new PVector(width/2, height/2, height/2);
        movingCamera = false;
        autoPanningMode = false;
        leftOuterBounds = new PVector(-2000, -2000, -2000);
        rightOuterBounds = new PVector(2000, 2000, 2000);
        leftInnerBounds = new PVector(0, 0, 0);
        rightInnerBounds = new PVector(0, 0, 0);
        viewingMode = true;
        mCenterStart = new PVector(0, 0, 0);
        mCenterEnd = new PVector(0, 0, 0);
        dirStart = new PVector(0, 0, 0);
        dirEnd = new PVector(0, 0, 0);
        movingCenter = false;
        autoDirChangeMode = false;
    }
    
    Camera() {
        this(width/2, height/2, height/2);
    }
    
    void setCenter(float cx, float cy, float cz) {
        center = new PVector(cx, cy, cz);  
    }
    
    void setOuterBounds(float lx, float ly, float lz, float rx, float ry, float rz) {
        leftOuterBounds = new PVector(lx, ly, lz);
        rightOuterBounds = new PVector(rx, ry, rz);
    }
    
    void setInnerBounds(float lx, float ly, float lz, float rx, float ry, float rz) {
        leftInnerBounds = new PVector(lx, ly, lz);
        rightInnerBounds = new PVector(rx, ry, rz);
    }
    
    //switches autoPanningMode on/off, also turns viewingMode off
    void autoPanSwitch() {
        autoPanningMode = !autoPanningMode;
        viewingMode = false;
    }
    
    //switches dir on/off, also turns viewingMode off
    void dirSwitch() {
        autoDirChangeMode = !autoDirChangeMode;
        viewingMode = false;
    }
    
    //switches viewingMode on/off, also turns autoPanningMode off
    void viewSwitch() {
        viewingMode = !viewingMode;
        if (viewingMode) {  
            disableAllModes();
            viewingMode = true;
        } else {
            disableAllModes();
        }
    }
    
    // disables and mode that is affecting camera movement / orientation
    void disableAllModes() {
        viewingMode = false;
        autoPanningMode = false;
        autoDirChangeMode = false;
        movingCamera = false;
        movingDir = false;
        movingCenter = false;    
    }
    
    //pans camera to set destination at set time (100 apprx. equals 2 seconds)
    void initMoveCamera(PVector destination, int time) {
        moveStart.x = pos.x;
        moveStart.y = pos.y;
        moveStart.z = pos.z;
        moveEnd = destination;
        moveTime = time;
        currentTime = 0;
        
        movingCamera = true;    
    }
    
    
    void initMoveDir(PVector destination, int time) {
        dirStart.x = dir.x;
        dirStart.y = dir.y;
        dirStart.z = dir.z;
        dirEnd = destination;
        mDirTime = time;
        mDirCurrTime = 0;
        
        movingDir = true; 
    }
    
    void initMoveCenter(float dx, float dy, float dz, int time) {
        mCenterStart.x = center.x;
        mCenterStart.y = center.y;
        mCenterStart.z = center.z;
        mCenterEnd = new PVector(dx, dy, dz);
        mCenterTime = time;
        mCenterCurrTime = 0;
  
        movingCenter = true;      
    }
    
    void rotateCamera(float angleInc) {
        dir.rotate(angleInc);
    }
    
    PVector pickRandomPoint() {
        float xf, yf, zf;
        float x1 = random(leftOuterBounds.x, leftInnerBounds.x);
        float x2 = random(rightInnerBounds.x, rightOuterBounds.x);
        if (random(1) > 0.5)
            xf = x1;
        else
            xf = x2;
//            
//        float y1 = random(leftOuterBounds.y, leftInnerBounds.y);
//        float y2 = random(rightInnerBounds.y, rightOuterBounds.y);
//        if (random(1) > 0.5)
//            yf = y1;
//        else
//            yf = y2;
        yf = random(leftOuterBounds.y, rightOuterBounds.y);
            
        float z1 = random(leftOuterBounds.z, leftInnerBounds.z);
        float z2 = random(rightInnerBounds.z, rightOuterBounds.z);
        if (random(1) > 0.5)
            zf = z1;
        else
            zf = z2;
//        xf = random(leftOuterBounds.x, rightOuterBounds.x);
//        yf = random(leftOuterBounds.y, rightOuterBounds.y);
//        zf = random(leftOuterBounds.z, rightOuterBounds.z);

        return new PVector(xf, yf, zf);           
    }
    
    void integrate(int currentTime, int maxTime, PVector v, PVector start, PVector end) {
        float angle = (currentTime*1.0 / maxTime) * PI;

        float xAmp = ((end.x - start.x) * PI) / (2 * maxTime);
        float dx = xAmp*sin(angle);
        v.x += dx;
        
        float yAmp = ((end.y - start.y) * PI) / (2 * maxTime);
        float dy = yAmp*sin(angle);
        v.y += dy;
        
        float zAmp = ((end.z - start.z) * PI) / (2 * maxTime);
        float dz = zAmp*sin(angle);
        v.z += dz;
    }

    //must be called every frame
    void update() {        
        if (viewingMode) {
            pos.x = map(mouseX, 0, width, leftOuterBounds.x, rightOuterBounds.x);
            pos.y = map(mouseY, 0, height, leftOuterBounds.y, rightOuterBounds.y);
        }
        
        if (autoPanningMode && !movingCamera) {
            int time = (int)random(frameRate*8, frameRate*12);
            PVector nextPos = pickRandomPoint();
            initMoveCamera(nextPos, time);
        }
        
        if (autoDirChangeMode && !movingDir) {
            int time;
            if (!autoPanningMode) {
                time = (int)random(frameRate*8, frameRate*12);    
            } else {
                time = moveTime;
            }
            float x = random(-1, 1);
            float y = random(-1, 1);
            float z = random(-1, 1);
            initMoveDir(new PVector(x, y, z), time);
        }
        
        if (movingCamera) {
            integrate(currentTime, moveTime, pos, moveStart, moveEnd);
            currentTime++;
            if (currentTime == moveTime) {
                movingCamera = false;    
            } 
        }
        
        if (movingDir) {
            integrate(mDirCurrTime, mDirTime, dir, dirStart, dirEnd);
            mDirCurrTime++;
            if (mDirCurrTime == mDirTime) {
                movingDir = false;
            } 
        }
        
        if (movingCenter) {
            integrate(mCenterCurrTime, mCenterTime, center, mCenterStart, mCenterEnd);
            mCenterCurrTime++;
            if (mCenterCurrTime == mCenterTime) {
                movingCenter = false;    
            } 
        }
        
        camera(pos.x, pos.y, pos.z, center.x, center.y, center.z, dir.x, dir.y, dir.z);
    }
    
}
