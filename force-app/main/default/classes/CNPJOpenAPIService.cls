public class CNPJOpenAPIService {

    @InvocableMethod(label='Consulta CNPJ e cria Lead')
    public static List<FlowOutput> consultarCNPJ(List<FlowInput> inputs) {
        List<FlowOutput> results = new List<FlowOutput>();

        for (FlowInput input : inputs) {
            FlowOutput output = new FlowOutput();

            try {
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setMethod('GET');
                req.setEndpoint('https://open.cnpja.com/office/' + input.cnpj);
                req.setHeader('Content-Type', 'application/json');

                HttpResponse res = http.send(req);
                System.debug('Resposta completa: ' + res.getBody());

                if (res.getStatusCode() == 200) {
                    CNPJResponse cnpjData = (CNPJResponse) JSON.deserialize(res.getBody(), CNPJResponse.class);

                    if (cnpjData.company != null && cnpjData.status != null && cnpjData.status.text == 'Ativa') {
                        Lead novoLead = new Lead();
                        novoLead.CNPJ__c = cnpjData.taxId;
                        novoLead.Company = cnpjData.company.name;
                        novoLead.LastName = cnpjData.company.name;
                        novoLead.RazaoSocial__c = String.isBlank(cnpjData.alias) ? cnpjData.company.name : cnpjData.alias;
                        novoLead.NomeFantasia__c = String.isBlank(cnpjData.alias) ? cnpjData.company.name : cnpjData.alias;
                        novoLead.Fundacao__c = Date.ValueOf(cnpjData.founded);
                        novoLead.LeadSource = 'Integration';
                        novoLead.Rating = 'Cold';
                        if (cnpjData.address != null) {
                            novoLead.Country = cnpjData.address.country != null && cnpjData.address.country.name == 'Brasil' ? 'BR' : cnpjData.address.country.name;
                            novoLead.State = cnpjData.address.state;
                            novoLead.City = cnpjData.address.city;
                            novoLead.Street = cnpjData.address.street;
                            novoLead.PostalCode = cnpjData.address.zip;
                        }
                        if (cnpjData.mainActivity != null) {
                            novoLead.AtividadePrincipal__c = cnpjData.mainActivity.text;
                        }
                        
                    	Map<String, Object> rawData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());                        
                        List<Object> rawPhones = (List<Object>) rawData.get('phones');
                        String phoneNumber = null;
                        String phoneArea = null;
                        
                        if (rawPhones != null && !rawPhones.isEmpty()) {
                            Map<String, Object> firstPhone = (Map<String, Object>) rawPhones[0];
                            phoneNumber = (String) firstPhone.get('number');
                            phoneArea = (String) firstPhone.get('area');
                        }

                        if (phoneArea != null && phoneNumber != null && phoneNumber.length() >= 8) {
                            String formattedNumber = '(' + phoneArea + ') ' + phoneNumber.substring(0, 4) + '-' + phoneNumber.substring(4);
                            novoLead.Phone = formattedNumber;
                        } else {
                                System.debug('Telefone não foi formatado por dados incompletos');
                        }
                    
                        if (!cnpjData.emails.isEmpty()) {
                            CNPJResponse.Email email = cnpjData.emails[0];
                            novoLead.Email = email.address;
                        }                        

                        insert novoLead;
                        output.resultado = 'Lead created';
                        output.leadId = novoLead.Id;
                        output.name = cnpjData.company.name;
                    } else {
                        output.resultado = 'Inactive Company';
                    }
                } else {
                    output.resultado = 'API Error: ' + res.getStatus();
                }
            } catch (Exception e) {
                output.resultado = 'Erro inesperado: ' + e.getMessage();
            }

            results.add(output);
            System.debug('results: ' + results);
        }

        return results;        
    }

    public class FlowInput {
        @InvocableVariable(required=true)
        public String cnpj;
    }

    public class FlowOutput {
        @InvocableVariable
        public String resultado;
        @InvocableVariable
        public Id leadId;     
		@InvocableVariable
        public String name;        
    }
}