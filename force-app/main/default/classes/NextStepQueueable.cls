/*
 * NextStepQueueable Class Description:
 * 
 * Implement the Queueable interface to process records asynchronously.
 * This example processes up to 10 accounts at a time.
 * It removes the Next Step from the accounts and related opportunities.
 *  
 * Benefits of using Queueable methods:
 * 
 * 1. Chaining Jobs: Allows for the chaining of jobs, meaning you can add another job to the queue from a running job.
 * 2. Stateful Execution: Supports stateful execution, which allows member variables to retain their values between job invocations.
 * 3. High Concurrency: Processes large sets of data without hitting governor limits.
 * 4. Flexibility: Useful for operations that need more flexibility in execution, especially when there's a possibility of chaining or performing related async operations.
 * 5. Enhanced Integration Capabilities: Useful for making asynchronous callouts to external systems, allowing for more extended processing times.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm
 * 
 * Note: The class below contains placeholders for implementing a queueable job to update accounts and opportunities.
 */
public with sharing class NextStepQueueable {

    // Member variable to store the accounts
    private final Map<Id,Account> accounts;

    // Constructor to accept the accounts
    public NextStepQueueable(Map<Id,Account> accounts) {
       this.accounts  = accounts; // Store the accounts in a member variable
    }

    // Method to queue the job
    public static void enqueueJob() {
        // Get 10 accounts with Next Step populated
        List<Account> accountsToProcess = [
                SELECT Id,  Next_Step__c
                FROM Account
                WHERE  Next_Step__c != NULL
                LIMIT 10
        ];

        // If there are any accounts, queue the job using System.enqueueJob
        if(!accountsToProcess.isEmpty()) {
            Map<Id, Account> accountMap = new Map<Id, Account>(accountsToProcess);
            System.enqueueJob(new  NextStepQueueable(accountMap));
        }
    }

    /*
     * Update/Uncomment the template code to create a method
     * Method to execute the queueable job
     */
   public void execute(QueueableContext context) {
        // Get the accounts from the member variable
       for (Account acc: accounts.values()) {
           // Remove the Next Step using the helper method
           removeNextStep(acc);
       }
       // Update the accounts
       update accounts.values();

       // Get the opportunities related to the accounts
       List<Opportunity> opps = [
               SELECT Id, NextStep
               FROM Opportunity
               WHERE AccountId IN :accounts.keySet()
       ];
       // Remove the Next Step using the helper method
       for(Opportunity opp: opps) {
           removeNextStep(opp);
       }
       // Update the opportunities
       update opps;

       // Call the enqueueJob method to queue another job to process more records.
       enqueueJob();
   }

    // Overloaded method to accept an opportunity
    private static void removeNextStep(Opportunity opp) {
        opp.NextStep = null;
    }

    // Helper method to remove the Next Step
    private static void removeNextStep(Account acc) {
        acc.Next_Step__c = null;
    }
}