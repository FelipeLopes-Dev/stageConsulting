trigger UpdateOportunidadeComAnexo on ContentDocumentLink (after insert) {
    Set<Id> oppIds = new Set<Id>();
    Set<Id> contentDocIds = new Set<Id>();

    for (ContentDocumentLink cdl : Trigger.New) {
        if (cdl.LinkedEntityId != null && String.valueOf(cdl.LinkedEntityId).startsWith('006')) {
            oppIds.add(cdl.LinkedEntityId);
            contentDocIds.add(cdl.ContentDocumentId);
        }
    }

    if (!oppIds.isEmpty() && !contentDocIds.isEmpty()) {
        Map<Id, ContentDocument> contentDocsMap = new Map<Id, ContentDocument>(
            [SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocIds]
        );

        List<Opportunity> oppsToUpdate = [SELECT Id, CustomerFileAttachment__c, CustomerDocSign__c FROM Opportunity WHERE Id IN :oppIds];

        for (ContentDocumentLink cdl : Trigger.New) {
            if (cdl.LinkedEntityId != null && String.valueOf(cdl.LinkedEntityId).startsWith('006')) {
                ContentDocument doc = contentDocsMap.get(cdl.ContentDocumentId);
                if (doc != null && doc.Title != null) {
                    if (doc.Title.toLowerCase().contains('de acordo')) {
                        for (Opportunity opp : oppsToUpdate) {
                            if (opp.Id == cdl.LinkedEntityId) {
                                opp.CustomerFileAttachment__c = true;
                            }
                        }
                    }

                    if (doc.Title.toLowerCase().contains('proposta assinada')) {
                        for (Opportunity opp : oppsToUpdate) {
                            if (opp.Id == cdl.LinkedEntityId) {
                                opp.CustomerDocSign__c = true;
                            }
                        }
                    }
                }
            }
        }

        update oppsToUpdate;
    }
}