
public class GuitarString {

    private RingBuffer buffer; // ring buffer
    private int tic; // records the total number of times tic() was called

    // create a guitar string of the given frequency
    public GuitarString(double frequency) {
        double sample_RATE = 44100.00;
        int N = (int) (sample_RATE / frequency);
        buffer = new RingBuffer(N);
        for (int i = 0; i < N; i++) {
            buffer.enqueue(0.0);
        }
        tic = 0;
    }

    // create a guitar string with size & initial values given by the array
    public GuitarString(double[] init) {
        buffer = new RingBuffer(init.length);
        for (int i = 0; i < init.length; i++) {
            buffer.enqueue(init[i]);
        }
        tic = 0;
    }

    // pluck the guitar string by replacing the buffer with white noise
    public void pluck() {
        for (int i = 0; i < buffer.size(); i++) {
            buffer.dequeue();
            buffer.enqueue(Math.random() - 0.5);
        }
    }

    // advance the simulation one time step
    public void tic() {
        double energy = 0.996;
        double first = buffer.dequeue();
        buffer.enqueue(energy * (first + buffer.peek()) / 2);
        tic++;
    }

    // return the current sample
    public double sample() {
        return buffer.peek();
    }

    // return number of times tic was called
    public int time() {
        return tic;
    }

}
