public class RingBuffer {
    private double[] rb;          // items in the buffer
    private int first;            // index for the next dequeue or peek
    private int last;             // index for the next enqueue
    private int size;             // number of items in the buffer
    
    
    // create an empty buffer, with given max capacity
    public RingBuffer(int capacity) {
        rb = new double[capacity];
        first = 0;
        last = 0;
        size = 0;
    }
    
    // return number of items currently in the buffer
    public int size() {
        return size;
    }
    
    // is the buffer empty (size equals zero)?
    public boolean isEmpty() {
        return size == 0;
    }
    
    // is the buffer full (size equals array capacity)?
    public boolean isFull() {
        return size == rb.length;
    }
    
    // add item x to the end
    public void enqueue(double x) {
        if (isFull()) {
            throw new RuntimeException("Ring buffer overflow");
        }
        rb[last] = x; 
        last = (last + 1) % rb.length;
        size++;
        if(last == rb.length)  {
            last = 0;
        }
    }
    
    // delete and return item from the front
    public double dequeue() {
        if (isEmpty()) {
            throw new RuntimeException("Ring buffer underflow");
        }
        double d = rb[first];
        first = first + 1;
        if(first == rb.length) {
            first = 0;
        }
        size--;
        return d;
    }
    
    // return (but do not delete) item from the front
    public double peek() {
        if (isEmpty()) {
            throw new RuntimeException("Ring buffer underflow");
        }
        return rb[first];
    }
    
    
}
