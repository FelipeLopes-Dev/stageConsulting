public class SendProposalWithGeneratedPDF {

    @InvocableMethod(label='Send Proposal Email with Generated PDF')
    public static void sendEmail(List<Request> requests) {
        System.debug('Entrou na classe');
        for (Request req : requests) {
            try {
                Opportunity opp = [
                    SELECT Name, ProjectTechnology__c, DataInicio__c, CloseDate, Amount,
                           Account.Name, Lead__r.Name
                    FROM Opportunity
                    WHERE Id = :req.opportunityId
                    LIMIT 1
                ];

                String customerName = String.isBlank(opp.AccountId) ? opp.Lead__r.Name : opp.Account.Name;

                PageReference pdfPage = Page.ProposalDocument;
                pdfPage.getParameters().put('id', opp.Id);
                pdfPage.getParameters().put('customerName', customerName);
                Blob pdfBlob = pdfPage.getContent();

                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Proposta_StageConsulting.pdf');
                attachment.setBody(pdfBlob);
                attachment.setContentType('application/pdf');

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] { req.toAddress });
                email.setSubject(req.subject);
                email.setHtmlBody(req.body);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

            } catch (Exception e) {
                System.debug('Erro ao enviar e-mail: ' + e.getMessage());
            }
        }
    }

    public class Request {
        @InvocableVariable(label='Endereço de E-mail')
        public String toAddress;

        @InvocableVariable(label='Assunto do Email')
        public String subject;

        @InvocableVariable(label='Corpo do Email (HTML)')
        public String body;

        @InvocableVariable(label='ID da Oportunidade')
        public Id opportunityId;
    }
}