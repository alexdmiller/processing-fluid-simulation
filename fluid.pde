import java.util.Arrays;

FluidGrid grid;
long lastTimeMillis;

float lastMouseX;
float lastMouseY;

int CELL_SIZE = 3;


void setup() {
  size(400, 400);
  grid = new FluidGrid(
      width / CELL_SIZE,
      height / CELL_SIZE,
      CELL_SIZE,
      0.000001,
      0.00001);
  grid.setSource(40, 50, 1);
  grid.setSource(20, 20, 0.2);
  lastTimeMillis = System.currentTimeMillis();
}

void draw() {
  long millis = System.currentTimeMillis();
  long delta = millis - lastTimeMillis;
  
  float vx = (mouseX - lastMouseX) / 100.0;
  float vy = (mouseY - lastMouseY) / 100.0;
  
  grid.setVelocity(mouseX / CELL_SIZE, mouseY / CELL_SIZE, vx, vy);
  
  grid.step(delta);
  
  lastTimeMillis = millis;
  background(255);
  noStroke();
  grid.render();
  
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}