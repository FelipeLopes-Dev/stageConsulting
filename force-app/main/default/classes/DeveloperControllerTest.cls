@isTest
private class DeveloperControllerTest {

    @testSetup
    static void setupData() {
        // Cria uma oportunidade com tecnologia definida
        Opportunity opp = new Opportunity(
            Name = 'Oportunidade Teste',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            ProjectTechnology__c = 'Salesforce',
            CustoEstimadoProjeto__c = 2000,
            Amount = 10000            
        );
        insert opp;

        // Desenvolvedores ativos com e sem a tecnologia no campo Especialidade
        List<Developer__c> devs = new List<Developer__c>{
            new Developer__c(Name='Dev 1', Especialidade__c='Salesforce; JavaScript', IsActive__c=true),
            new Developer__c(Name='Dev 2', Especialidade__c='JavaScript; Python', IsActive__c=true),
            new Developer__c(Name='Dev 3', Especialidade__c='Salesforce', IsActive__c=true),
            new Developer__c(Name='Dev Inativo', Especialidade__c='Salesforce', IsActive__c=false)
        };
        insert devs;

        // Relaciona 1 desenvolvedor com a oportunidade
        OpportunityDeveloper__c od = new OpportunityDeveloper__c(
            Opportunity__c = opp.Id,
            Developer__c = devs[2].Id // Dev 3
        );
        insert od;
    }

    @isTest
    static void testGetDevelopersByTechnology() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Developer__c> result = DeveloperController.getDevelopersByTechnology(opp.Id);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Deve retornar 2 desenvolvedores com Salesforce na especialidade e ativos');
        for (Developer__c dev : result) {
            System.assert(dev.Especialidade__c.contains('Salesforce'));
        }
    }

    @isTest
    static void testCreateOpportunityDevelopers() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Developer__c> devs = [SELECT Id FROM Developer__c WHERE Name = 'Dev 1' OR Name = 'Dev 2'];

        Test.startTest();
        DeveloperController.createOpportunityDevelopers(opp.Id, new List<Id>{devs[0].Id, devs[1].Id});
        Test.stopTest();

        List<OpportunityDeveloper__c> inserted = [
            SELECT Id FROM OpportunityDeveloper__c
            WHERE Opportunity__c = :opp.Id AND Developer__c IN :devs
        ];
        System.assertEquals(2, inserted.size(), 'Deve ter criado 2 registros OpportunityDeveloper__c');
    }

    @isTest
    static void testSyncOpportunityDevelopers() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Developer__c> devs = [SELECT Id, Name FROM Developer__c WHERE Name = 'Dev 1' OR Name = 'Dev 3'];

        Test.startTest();
        String message = DeveloperController.syncOpportunityDevelopers(opp.Id, new List<Id>{devs[0].Id});
        Test.stopTest();

        System.debug('Mensagem retornada: ' + message);
        System.assert(message.contains('Removidos'), 'Deve indicar que um desenvolvedor foi removido');
        System.assert(!message.contains('Já estavam alocados'), 'Não deve conter alocados novamente');

        List<OpportunityDeveloper__c> remaining = [
            SELECT Developer__c FROM OpportunityDeveloper__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, remaining.size());
        System.assertEquals(devs[0].Id, remaining[0].Developer__c);
    }

    @isTest
    static void testGetSelectedDeveloperIds() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Id> selected = DeveloperController.getSelectedDeveloperIds(opp.Id);
        Test.stopTest();

        System.assertEquals(1, selected.size(), 'Deve retornar 1 ID de desenvolvedor relacionado');
    }

    @isTest
    static void testClearOpportunityDevelopers() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        DeveloperController.clearOpportunityDevelopers(opp.Id);
        Test.stopTest();

        List<OpportunityDeveloper__c> afterDelete = [
            SELECT Id FROM OpportunityDeveloper__c WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(0, afterDelete.size(), 'Todos os registros devem ser deletados');
    }
}