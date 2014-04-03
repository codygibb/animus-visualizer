class EPVector extends PVector {
    EPVector(float x, float y, float z) {
        super(x, y, z);       
    }
    
    EPVector() {
        super(0, 0, 0);       
    }
    
    void rotateX(float angle) {
        PVector temp = new PVector(super.y, super.z);
        temp.rotate(angle);
        super.y = temp.x;
        super.z = temp.y;
    }
    
    void rotateY(float angle) {
        PVector temp = new PVector(super.x, super.z);
        temp.rotate(angle);
        super.x = temp.x;
        super.z = temp.y;
    }
    
    void rotateZ(float angle) {
        PVector temp = new PVector(super.x, super.y);
        temp.rotate(angle);
        super.x = temp.x;
        super.y = temp.y;
    }
    
    void set(int x, int y, int z){
        super.x = x;
        super.y = y;
        super.z = z;
    }
    
}
