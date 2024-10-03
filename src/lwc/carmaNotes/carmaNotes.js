import { LightningElement,api,wire, track } from 'lwc';
import fetchRecords from '@salesforce/apex/CARMA_CSLAndSSANotesController.fetchRecords'; 
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class CarmaNotes extends NavigationMixin( LightningElement ) { 

    @api recordId; 
    @track isModalVisible = false;
    strTitle = "Notes";
    objectName = "CARMA_Note__c";
    titleWithCount = this.strTitle + ' (0)';
    listRecords = [];  

    connectedCallback(){
        this.populateNotesGrid();    
    }

    populateNotesGrid(){
        if(this.recordId){
            fetchRecords({carmaCaseId: this.recordId})
            .then(result => {
                if ( result ) {

                    this.titleWithCount = this.strTitle + ' (' + result.length + ')';  
                    this.listRecords = result;
                    refreshApex(this.listRecords);        
                } 
                
            });
        }
    }

    openCarmaNotes(event) {
        // Navigate to Account record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": event.target.dataset.value,
                "objectApiName": "CARMA_Note__c",
                "actionName": "view"
            },
        });
    }

    createNew(){
        this.isModalVisible = true;
    }

    handleModalSubmit() {
        this.handleModalClose();
    }

    handleModalClose() {
        this.isModalVisible = false;
    }

    handleGridUpdate(){
        this.populateNotesGrid();
    }

}