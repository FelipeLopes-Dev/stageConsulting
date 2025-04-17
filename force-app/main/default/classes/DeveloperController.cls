public with sharing class DeveloperController {
    
    @AuraEnabled(cacheable=true)
    public static List<Developer__c> getDevelopersByTechnology(Id opportunityId) {
        Opportunity opp = [SELECT ProjectTechnology__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        String tecnologia = opp.ProjectTechnology__c;

        List<Developer__c> matchingDevs = [
            SELECT Id, Name, Especialidade__c
            FROM Developer__c
            WHERE IsActive__c = true
        ];

        List<Developer__c> filtered = new List<Developer__c>();
        for (Developer__c dev : matchingDevs) {
            if (String.isNotBlank(dev.Especialidade__c) && dev.Especialidade__c.contains(tecnologia)) {
                filtered.add(dev);
            }
        }
        return filtered;
    }

    @AuraEnabled
    public static void createOpportunityDevelopers(Id opportunityId, List<Id> developerIds) {
        List<OpportunityDeveloper__c> records = new List<OpportunityDeveloper__c>();
        for (Id devId : developerIds) {
            records.add(new OpportunityDeveloper__c(
                Opportunity__c = opportunityId,
                Developer__c = devId
            ));
        }
        insert records;
    }
    
    @AuraEnabled
    public static String syncOpportunityDevelopers(Id opportunityId, List<Id> developerIds) {
        List<OpportunityDeveloper__c> existing = [
            SELECT Id, Developer__c, Developer__r.Name
            FROM OpportunityDeveloper__c
            WHERE Opportunity__c = :opportunityId
        ];
    
        Set<Id> existingIds = new Set<Id>();
        Map<Id, OpportunityDeveloper__c> devIdToRecord = new Map<Id, OpportunityDeveloper__c>();
        for (OpportunityDeveloper__c od : existing) {
            existingIds.add(od.Developer__c);
            devIdToRecord.put(od.Developer__c, od);
        }
    
        List<OpportunityDeveloper__c> toInsert = new List<OpportunityDeveloper__c>();
        List<OpportunityDeveloper__c> toDelete = new List<OpportunityDeveloper__c>();
        List<String> removedNames = new List<String>();
        List<String> alreadyAllocated = new List<String>();
    
        for (Id devId : developerIds) {
            if (!existingIds.contains(devId)) {
                toInsert.add(new OpportunityDeveloper__c(
                    Opportunity__c = opportunityId,
                    Developer__c = devId
                ));
            } else {
                alreadyAllocated.add(devIdToRecord.get(devId).Developer__r.Name);
            }
        }
    
        for (OpportunityDeveloper__c od : existing) {
            if (!developerIds.contains(od.Developer__c)) {
                toDelete.add(od);
                removedNames.add(od.Developer__r.Name);
            }
        }
    
        if (!toInsert.isEmpty()) insert toInsert;
        if (!toDelete.isEmpty()) delete toDelete;
    
        String message = '';
        if (!removedNames.isEmpty()) {
            message += 'Removidos: ' + String.join(removedNames, ', ') + '. ';
        }
        if (!alreadyAllocated.isEmpty()) {
            message += 'Já estavam alocados: ' + String.join(alreadyAllocated, ', ') + '.';
        }
        return message;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Id> getSelectedDeveloperIds(Id opportunityId) {
        List<OpportunityDeveloper__c> records = [
            SELECT Developer__c FROM OpportunityDeveloper__c
            WHERE Opportunity__c = :opportunityId
        ];
    
        List<Id> developerIds = new List<Id>();
        for (OpportunityDeveloper__c od : records) {
            developerIds.add(od.Developer__c);
        }
        return developerIds;
    }   
    
    @AuraEnabled
    public static void clearOpportunityDevelopers(Id opportunityId) {
        List<OpportunityDeveloper__c> toDelete = [
            SELECT Id FROM OpportunityDeveloper__c
            WHERE Opportunity__c = :opportunityId
        ];
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }    
}