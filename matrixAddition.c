#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "pvm3.h"


int parent(){
	int w = 3;
	int h = 3;
	int matrixA[3][3] = {1,2,3,4,5,6,7,8,9};
	int matrixB[3][3] = {1,1,1,1,1,1,1,1,1};
	int matrixC[3][3] = {0, 0, 0, 0, 0, 0, 0, 0, 0};

	int i;
	int rowsSent = 0;
	int tidmaster, tid[5], ilhost, ilarch;
	struct pvmhostinfo *info;

	tidmaster = pvm_mytid();
	pvm_config (&ilhost, &ilarch, &info);
	//ilhost = 1;
	//tid = (int*) calloc (ilhost, sizeof(int));
	printf("Data prepared\n");

	for( i=0; i<ilhost; i++)
	{
		printf("Trying to create child %d \n", i);
		if(rowsSent >= h) break;
		pvm_spawn("/home/pvm/pvm3/lab8/matrixAddition",0, PvmTaskHost, info[i].hi_name, 1, &tid[i]);
		pvm_initsend(PvmDataDefault);

		pvm_pkint(&rowsSent, 1 ,1);
		pvm_pkint(&w, 1 , 1);
		pvm_pkint(matrixA[rowsSent], w, 1);
		pvm_pkint(matrixB[rowsSent], w, 1);

		rowsSent++;
		pvm_send(tid[i], 100);
		printf("Child created\n");
	}
	while(rowsSent < h)
	{
		printf("sending in while %d \n", rowsSent);
		int a = pvm_recv(-1, 200);
		int x, y, adr;
		int rowItr;
		pvm_bufinfo(a , &x , &y , &adr);

		pvm_upkint(&rowItr, 1 ,1 );
		pvm_upkint(matrixC[rowItr], w, 1);

		pvm_pkint(&rowsSent, 1, 1);
		pvm_pkint(&w, 1 ,1);
		pvm_pkint(matrixA[rowsSent], w, 1);
		pvm_pkint(matrixB[rowsSent], w, 1);
		rowsSent++;
		pvm_send(adr, 100);
	}


	for (i=0; i < ilhost; i++ ) {
		pvm_recv(-1, 200);
		int rowItr;
		pvm_upkint (&rowItr, 1, 1);
		pvm_upkint(matrixC[rowItr], w, 1);
		printf("Killing child with tid: %d \n", tid[i]);
		pvm_kill(tid[i]);
	}

	printf("Adding matrices\n");
	int x = 0, y = 0;
	for(y = 0; y < h; y++)
	{
		for( x = 0; x < w; x++)
		{
		printf("%d ",matrixC[y][x]);
		}
	printf("\n");
	}

	pvm_exit();
	exit(0);
}

void child()
{

	int masterid;
	int w, i, u;
	int a[50], b[50], c[50];
	int rowItr;

	masterid = pvm_parent();
	printf("I'm a child");
	while(1)
	{
		pvm_recv(-1,100);
		pvm_upkint(&rowItr, 1, 1);
		pvm_upkint(&w, 1, 1);
		pvm_upkint(a, w, 1);
		pvm_upkint(b, w, 1);
		pvm_initsend(PvmDataDefault);
		for(int i=0; i<w; i++)
		{
			c[i] = a[i] + b[i];
		}
		pvm_pkint(&rowItr, 1 ,1);
		pvm_pkint(c, w, 1);

		pvm_send(masterid, 200);
	}
}



int  main()
{
        if(pvm_parent() == PvmNoParent)
                parent();
        else
                child();
        return 0;
}

