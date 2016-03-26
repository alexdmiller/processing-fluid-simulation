import java.util.Arrays;

FluidGrid grid;
long lastTimeMillis;

void setup() {
  size(600, 600);
  grid = new FluidGrid(100, 100, 6, 0.000001);
  grid.setSource(40, 40, 0.1);
  lastTimeMillis = System.currentTimeMillis();
}

void draw() {
  long millis = System.currentTimeMillis();
  long delta = millis - lastTimeMillis;
  grid.step(delta);
  
  lastTimeMillis = millis;
  background(255);
  noStroke();
  grid.render();
}