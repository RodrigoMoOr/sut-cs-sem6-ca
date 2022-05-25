/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.ak.lab;

import net.jini.space.JavaSpace;

/**
 *
 * @author Rodrigo Morales Jugen Mucaj
 */
public class Worker {
    
    public static Answer makeWorker(Task task) {
         return new Answer(task.index, task.aValue, task.bValue);
     }
    
    
    public static void main(String[] args) {
         
         Lookup finder = new Lookup(JavaSpace.class);
         JavaSpace space = (JavaSpace) finder.getService();
         
         Task temp = new Task();
         try{
            System.out.println("Rading incoming task from space");
            int counter = 0;
            while(true){
                 Task task = (Task) space.take(temp, null, Long.MAX_VALUE);
                 System.out.println("Task received. Task: " + task.toString());
                 counter++;
                 
                 
                 if(task.index.equals(-1)){
                     System.out.println("Death pill");
                     space.write(task, null, 10000);
                     break;
                 }
                 else{
                     Answer answer = new Answer();
                     answer.index = task.index;
                     answer.result = task.aValue + task.bValue;
                     System.out.println(task.aValue.toString() + " +  " + task.bValue.toString() + " = " + answer.result.toString());
                     space.write(answer, null, Long.MAX_VALUE);
                     System.out.println("Answer obj sent to space");
                 }
            }
            
            
         }catch(Exception ex){
             ex.printStackTrace();
         }
     }
}


/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.ak.lab;

import net.jini.core.entry.Entry;

/**
 *
 * @author Rodrigo Morales Jugen Mucaj
 */
public class Task implements Entry {
    
   
    public Integer aValue;
    public Integer bValue;
    public Integer index;
    
    public Task(){
        this.aValue = null;
        this.bValue = null;
        this.index = null;
    }
    
}

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.ak.lab;

import net.jini.core.entry.Entry;

/**
 *
 * @author Rodrigo Morales Jugen Mucaj
 */
public class Answer implements  Entry{
    
    public Integer index;
    public Integer result;
    
    public Answer(){
        this.index = null;
        this.result = null;
    }
    
    public Answer(int index, int a, int b) {
        this.index = index;
        this.result = a + b;
    }
    
    /**
     * Turns our Answer obj into a nicely formatted string
     * @return 
     */
    public String toString() {
        return "Answer: index " + this.index + " res: " + this.result;
    }
    
}

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.ak.lab;

import java.util.Random;
import net.jini.space.JavaSpace;

/**
 *
 * @author Rodrigo Morales Jugen Mucaj
 */
public class Master {

  
    public static void main(String[] args) {
       System.out.println("witam");
       int size = 1000;
       Integer[] a = new Integer[size];
       Integer[] b = new Integer[size];
       Integer[] c = new Integer[size];
        
       Random random = new Random();
       int maxValue = 100;

       Lookup finder = new Lookup(JavaSpace.class);
       JavaSpace space = (JavaSpace) finder.getService();      
        System.out.println("znalazlem space");
       try{
        for(
            int i = 0; i< size; i++){
            a[i] = random.nextInt(maxValue);
            b[i] = random.nextInt(maxValue); 
            Task task = new Task();
            task.aValue = a[i];
            task.bValue = b[i];
            task.index = i;
            space.write(task, null, Long.MAX_VALUE);
            System.out.println("tasks sent");
       }
        
        
        for(int i = 0; i < size; i++){
            Answer temp = new Answer();
            Answer answer = (Answer) space.take(temp, null, 100000);
            c[answer.index] = answer.result;               
               System.out.println("index: "+answer.index.toString() + " value: " + answer.result.toString());
        }
        
//        System.out.println("Results matrix: \n");
//        for (int i = 0; i < ; i++) {
//            System.out.println(c[i]);
//        }
        
        Task pill = new Task();
        pill.index = -1;
        space.write(pill,null, 10000);
        
       }
        catch(Exception ex){
           ex.printStackTrace();
       }
       
      }
       
        
 }
