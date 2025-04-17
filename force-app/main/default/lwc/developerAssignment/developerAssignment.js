import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDevelopersByTechnology from '@salesforce/apex/DeveloperController.getDevelopersByTechnology';
import syncOpportunityDevelopers from '@salesforce/apex/DeveloperController.syncOpportunityDevelopers';
import getSelectedDeveloperIds from '@salesforce/apex/DeveloperController.getSelectedDeveloperIds';
import clearOpportunityDevelopers from '@salesforce/apex/DeveloperController.clearOpportunityDevelopers';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Technology_FIELD from '@salesforce/schema/Opportunity.ProjectTechnology__c';
import { refreshApex } from '@salesforce/apex';

export default class DeveloperAssignment extends LightningElement {
    @api recordId;

    @track developers = [];
    @track selectedDeveloperIds = [];
    @track error;

    wiredDevelopersData;
    previousTechnology;

    @wire(getRecord, { recordId: '$recordId', fields: [Technology_FIELD] })
    wiredOpportunity({ error, data }) {
        if (data) {
            const currentTech = getFieldValue(data, Technology_FIELD);

            if (this.previousTechnology !== undefined && this.previousTechnology !== currentTech) {
                this.previousTechnology = currentTech;

                clearOpportunityDevelopers({ opportunityId: this.recordId })
                    .then(() => {
                        this.selectedDeveloperIds = [];
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Tecnologia alterada',
                                message: 'Os desenvolvedores foram removidos. Selecione os novos de acordo com a nova tecnologia.',
                                variant: 'info'
                            })
                        );
                        return refreshApex(this.wiredDevelopersData);
                    })
                    .catch(error => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Erro ao limpar alocações',
                                message: error.body.message,
                                variant: 'error'
                            })
                        );
                    });
            } else if (this.previousTechnology === undefined && currentTech) {
                this.previousTechnology = currentTech;
            }

            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
        }
    }

    @wire(getDevelopersByTechnology, { opportunityId: '$recordId' })
    wiredDevelopers(result) {
        this.wiredDevelopersData = result;
        if (result.data) {
            this.developers = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error.body.message;
        }
    }

    connectedCallback() {
        getSelectedDeveloperIds({ opportunityId: this.recordId })
            .then(ids => {
                this.selectedDeveloperIds = ids;
            })
            .catch(error => {
                this.error = error.body.message;
            });
    }

    get developerOptions() {
        return this.developers.map(dev => ({
            label: dev.Name,
            value: dev.Id
        }));
    }

    handleChange(event) {
        this.selectedDeveloperIds = event.detail.value;
    }

    handleSave() {
        syncOpportunityDevelopers({
            opportunityId: this.recordId,
            developerIds: this.selectedDeveloperIds
        })
            .then((message) => {
                let variant = 'success';
                let title = 'Sucesso!';
                if (message && message.includes('Removidos')) {
                    variant = 'warning';
                    title = 'Desenvolvedores Removidos';
                } else if (message && message.includes('alocados')) {
                    variant = 'info';
                    title = 'Aviso';
                }

                this.dispatchEvent(
                    new ShowToastEvent({
                        title,
                        message: message || 'Alocação atualizada com sucesso.',
                        variant
                    })
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erro',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}