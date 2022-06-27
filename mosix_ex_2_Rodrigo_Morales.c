// Rodrigo Morales
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

double computeTrapezoidArea(double x0, double step)
{
  double y1 = 8 * pow(x0, 5) - 2 * pow(x0, 4) + 15 * pow(x0, 2) - 24 * x0 + 18;

  double x1 = x0 + step;
  double y2 = 8 * pow(x1, 5) - 2 * pow(x1, 4) + 15 * pow(x1, 2) - 24 * x1 + 18;

  return ((y1 + y2) / 2) * step;
}

double computeRangeOfTrapezoids(double start, double end, double step)
{
  double j;
  double area = 0.0;
  for (j = start; j < end; j + step)
  {
    area += computeTrapezoidArea(j, step);
  }

  return area;
}

int main(int argc, char *argv[])
{
  if (argc < 0)
  {
    printf("Bad params num");
    return 0;
  }

  int n = atoi(argv[1]);
  int k = atoi(argv[2]);

  double area = 0.0;

  int pipeOne[2];

  int i;
  double childArea;

  for (i = 0; i < k; i++)
  {
    printf("Spawning child");
    if (fork() == 0)
    {
      printf("Child spawned");
      double x0 = -15 + (30 / k) * i;
      double x1 = -15 + (30 / k) * (i + 1);
      printf("Compute start and end x coordinates for child");
      childArea = computeRangeOfTrapezoids(x0, x1, n);
      // send back to parent
      printf("Child area computed");
      write(pipeOne[1], &childArea, sizeof(childArea));
      exit(0);
    }
  }

  while (wait(0) > 0)
  {
  }

  for (i = 0; i < k; i++)
  {
    read(pipeOne[0], &childArea, sizeof(childArea));
    area += childArea;
  }

  printf("Area under the curve: %f", area);

  return 0;
}