@IsTest
private class CNPJOpenAPIServiceTest {

    private class MockCNPJResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{' +
                '"taxId": "12345678000190",' +
                '"alias": "Empresa Teste",' +
                '"founded": "2001-06-01",' +
                '"status": {"id": 1, "text": "Ativa"},' +
                '"company": {"id": 1, "name": "Empresa Teste Ltda", "equity": 100000.00,' +
                    '"nature": {"id": 1, "text": "LTDA"},' +
                    '"size": {"id": 1, "acronym": "ME", "text": "Microempresa"},' +
                    '"simples": {"optant": true, "since": "2010-01-01"},' +
                    '"simei": {"optant": false, "since": "2012-01-01"},' +
                    '"members": [] },' +
                '"address": {' +
                    '"state": "SP",' +
                    '"city": "São Paulo",' +
                    '"street": "Rua Teste",' +
                    '"zip": "01234-000",' +
                    '"country": {"id": 1, "name": "Brasil"} },' +
                '"mainActivity": {"id": 1, "text": "Desenvolvimento de software"},' +
                '"phones": [{"type": "mobile", "area": "11", "number": "987654321"}],' +
                '"emails": [{"ownership": "comercial", "address": "contato@empresa.com", "domain": "empresa.com"}]' +
            '}');
            return res;
        }
    }

    @IsTest
    static void testConsultaCNPJ_LeadCreated() {

        Test.setMock(HttpCalloutMock.class, new MockCNPJResponse());
        CNPJOpenAPIService.FlowInput input = new CNPJOpenAPIService.FlowInput();
        input.cnpj = '12345678000190';
        List<CNPJOpenAPIService.FlowInput> inputs = new List<CNPJOpenAPIService.FlowInput>{ input };

        Test.startTest();
        List<CNPJOpenAPIService.FlowOutput> resultados = CNPJOpenAPIService.consultarCNPJ(inputs);
        Test.stopTest();

        List<Lead> leads = [SELECT Id, Company, CNPJ__c, Phone, Email, RazaoSocial__c FROM Lead WHERE CNPJ__c = '12345678000190'];
        System.assertEquals(1, leads.size(), 'Lead deve ter sido criado');
        System.assertEquals('(11) 9876-54321', leads[0].Phone, 'Telefone deve estar formatado');
        System.assertEquals('Empresa Teste Ltda', leads[0].Company);
        System.assertEquals('Empresa Teste', leads[0].RazaoSocial__c);
        System.assertEquals('contato@empresa.com', leads[0].Email);
    }
}