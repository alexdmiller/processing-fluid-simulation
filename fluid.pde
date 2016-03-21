import java.util.Arrays;

FluidGrid grid;
long lastTimeMillis;

void setup() {
  size(600, 600);
  grid = new FluidGrid(20, 20, 10, 0.00001);
  grid.setSource(4, 5, 0.01);
  lastTimeMillis = System.currentTimeMillis();
}

void draw() {
  long millis = System.currentTimeMillis();
  long delta = millis - lastTimeMillis;
  grid.step(delta);
  
  lastTimeMillis = millis;
  background(255);
  grid.render();
}