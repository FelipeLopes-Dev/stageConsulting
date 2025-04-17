public with sharing class BuscarCNPJService {

    public class Input {
        @InvocableVariable(required=true)
        public String cnpj;
    }

    public class Output {
        @InvocableVariable public String razaoSocial;
        @InvocableVariable public String nomeFantasia;
        @InvocableVariable public String municipio;
        @InvocableVariable public String uf;
        @InvocableVariable public String status;
    }

    @InvocableMethod(label='Buscar dados CNPJ na CNPJá Open')
    public static List<Output> buscarDadosCNPJ(List<Input> inputs) {
        List<Output> outputs = new List<Output>();

        for (Input input : inputs) {
            String cnpjLimpo = input.cnpj.replaceAll('[^0-9]', '');

            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://open.cnpja.com/office/' + cnpjLimpo);
            req.setMethod('GET');
            req.setHeader('User-Agent', 'SalesforceIntegration/1.0');
            req.setHeader('Accept', 'application/json');

            Http http = new Http();
            HttpResponse res;

            try {
                res = http.send(req);
                System.debug('Response: ' + res);
                if (res.getStatusCode() == 200) {
                    Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                    Output o = new Output();
                    o.razaoSocial   = (String) json.get('razao_social');
                    o.nomeFantasia  = (String) json.get('nome_fantasia');
                    o.municipio     = (String) json.get('descricao_municipio');
                    o.uf            = (String) json.get('uf');
                    o.status        = (String) json.get('situacao_cadastral');

                    outputs.add(o);
                } else {
                    System.debug('Erro ao consultar CNPJá: ' + res.getStatusCode() + ' - ' + res.getBody());
                }
            } catch (Exception e) {
                System.debug('Erro na chamada CNPJá: ' + e.getMessage());
            }
        }

        return outputs;
    }
}