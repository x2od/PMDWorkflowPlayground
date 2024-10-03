import { LightningElement, api, track, wire} from 'lwc';
import NewContactModal from 'c/vacxCreateNewContactForm';

// import casesCell from "./casesCell";
import sendIds from "@salesforce/messageChannel/WHVAHotlineCaseContact__c";
import setLookups from "@salesforce/messageChannel/WHVAHotlineContactMC__c";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import {
    publish,
    subscribe,
    MessageContext,
  } from "lightning/messageService";
import callerTemplate from './callerTemplate.html';
import veteranTemplate from './veteranTemplate.html';
import nonVeteranTemplate from './nonVeteranTemplate.html';
import thirdPartyTemplate from './thirdPartyTemplate.html';

// import popScreenFlow from 'c/vacxVAPInitiateFlow';

import verifyTemplate from './verifyTemplate.html';
// import personSearch from "@salesforce/apex/WHVAHotlinePersonSearchController.personSearch";
//Future: combined search
import doCombinedSearch from "@salesforce/apex/WHVAHotlinePersonSearchController.personSearchNew";
// import writeExistingVAP from "@salesforce/apex/WHVAHotlinePersonSearchController.writeExistingVAP";



import retrieveMPIE  from "@salesforce/apex/WHVAHotlinePersonSearchController.retrieveMPIE";
import {
  // birthdateMask,
  ssnMask
} from "c/whvaUtility";


import getUserPermissionSets from "@salesforce/apex/WHVAHotlinePersonSearchController.getUserPermissionSets";
import getContactRecordTypesForCreation from "@salesforce/apex/WHVAHotlinePersonSearchController.getContactRecordTypesForCreation";
import getRTName from "@salesforce/apex/WHVAHotlinePersonSearchController.getRecordTypeNameById";


// custom labels
import selfVetSelect from "@salesforce/label/c.WHVA_SelfVetSelect";
import selfVetSearch from "@salesforce/label/c.WHVA_SelfVetSearch";
import nonVetTabSearchInfoLabel from "@salesforce/label/c.VACX_nonVetTabSearchInfo";
import impactedSearchLabel from "@salesforce/label/c.VACX_ImpactedPersonSearch";
import anonSearch from "@salesforce/label/c.WHVA_ContactAnon";
import selfNonVetSearch from "@salesforce/label/c.WHVA_ContactSelfNonVet";
import vetVerify from "@salesforce/label/c.WHVA_SelfVetVerify";
import vetVerify2 from "@salesforce/label/c.WHVA_SelfVetVerify2";
import impactedProxyLabel from "@salesforce/label/c.VACX_ImpactedProxySearch";
import proxyVetVerify from "@salesforce/label/c.WHVA_ProxyVetVerifyVet2";
import MOH_Recipient from "@salesforce/label/c.VACX_MOH_Recipient"
// proxy non vet labels 1 and 2 
import proxyLabel from "@salesforce/label/c.WHVA_ContactProxy";
import proxyLabel2 from "@salesforce/label/c.WHVA_ContactProxy2";
import exactMatchLabelImport from "@salesforce/label/c.VACX_ExactMatch";

import proxyVetSearch from "@salesforce/label/c.WHVA_ContactProxyVet";
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import carmaCallout from "@salesforce/apex/WHVAHotlinePersonSearchController.carmaCallout";
import checkJobs from "@salesforce/apex/WHVAHotlinePersonSearchController.checkJobs";
import insertMPIContact from "@salesforce/apex/WHVAHotlinePersonSearchController.insertMPIContact";
import saveMPIContact from "@salesforce/apex/WHVAHotlinePersonSearchController.saveMPIEContact";
import currentCase from "@salesforce/apex/WHVAHotlinePersonSearchController.updateCurrentCase";
// import MyModal from 'c/vacxNewContactForm';
import BIRTH_STATE_FIELD from '@salesforce/schema/Contact.Birth_State__c';
import MOH_FIELD from '@salesforce/schema/Contact.Medal_of_Honor_MOH_Recipient__c';
import CONTACT_OBJECT from "@salesforce/schema/Contact";


const fields = [MOH_FIELD];
const NON_DIGIT_REGEX = /[^0-9]/g;

export default class VacxContactSearchTemplates extends LightningElement {
    //message context
    @wire(MessageContext)
    messageContext;


    @wire(getPicklistValues, { recordTypeId: '$contactObjWire.data.defaultRecordTypeId', fieldApiName: BIRTH_STATE_FIELD })
    birthStateOptionsWire({ data, error }) {
      if (data) {
        if (data.values) {
          this.birthStateOptions = data.values;
        }
      }
    };
  
  
    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    contactObjWire;

    
    @wire(getRecord, { recordId: '$searchResultId', fields })
    contact;
    //variables for templates
    @api verifyTemp;
    @api templateChoice;
    @api prox;
    @api proxForVet;
    @api thirdParty;
    @api selectedTemplate;

    showCallerTemplate = true;
    showVeteranTemplate = false;
    showNonVeteranTemplate = false;
    showSpinner = false;
    showSearchCriteria = true;
    renderVerify = false;


    //custom labels
    searchInfo = selfVetSearch;
    searchInfoLineTwo = '';
    searchInfoNonVet = nonVetTabSearchInfoLabel;
    //exact match
    exactMatchLabel = exactMatchLabelImport;
    //impacted perosn 
    impactedPersonSearch = impactedSearchLabel;
    //Medal of Honor
    MOHContact = MOH_Recipient;
    //variables for radio buttons
    whoIsCallingDefault;
    whoIsCallingSelection;
    callingForSelection;
    showCallingForGroup = false;
    whoAreTheyCallingForDefault;
    callingFor;
    isAnon = false;
    hasProxy;
    anonymousCheckbox;

    //variables for combobox
    showRelationshipCombobox = false;

    //variables for fields
    FNhasValue;
    LNhasValue;
    DOBhasValue;
    SSNhasValue;
    specialInstructions;
    setPhone;
    setSSN;
    relationshipType;
    emailTrimmed;
    @track dobInput;
    @track disableSearch = true;
    disableNewContact = true;
    emailHasValue;
    phoneHasValue;
    RThasValue = false;
    homePhoneHasValue;
    siMap;
    maidenName;
    birthCity;
    birthState;


    //variables for additional fields, Agents do NOT see, OCR OPS do
    showAdditional = false;
    showVeteranFields = true;
    newConRTName;
    
    //datatable
    exactMatch = true;
    columns = [];
    searchResults = [];
    @track showResultsTable;
    @track noResults;
    @track top;
    @track left;
    @track selectedcase;
    @track showPopover = false;
    errorMessage;
    showMPIError;

    //verify 
    isVeteran;
    @api verifySearchResultId;
    searchResultId;

    recordTypeName;
    templateToReturnTo;
    disableVerified = false;
    saved = false;
    disableSpecial;
    disabled = true;
    jobid;
    timeoutid;
    theContact;
    showVAP;
    @api mpiTab;
    @api caseId;
    //the caller type to update case respectively
    callerType = '';
    //whether or not we should send the contact as a vet (depends on the template to determine lookups, not dependent on RT!!!!)
    sendAsVeteran;
    personType;
    isShowFlow = false;
    mapOfVAPValues = [];
   
  
    get isAgent() { //PTEMSWHHL-2680 don't show section to agents
      return (this.isOCRMember || this.isOPSMember) ? false : true;
    }

    get whoIsCallingOptions() {
    //we are going to be searching both vets and non vets, and just using person type from the result thats selected
    //so the table is going to be showing both vets and non vets, do we want a column to identify?
    return [
        // { label: "Self - Veteran/Non-Veteran", value: "Caller" },
        // { label: "Veteran/Non-Veteran", value: "Caller2" },
        { label: "Veteran (Self)", value:"Vet"},

        { label: "Non-Veteran (Self)", value:"NonVet"},
        { label: "Proxy (Calling on Behalf of)", value: "Proxy" },
        { label: "Anonymous", value: "Anonymous" },
    ];
    }
    
    get whoAreTheyCallingForOptions() {
    return [
        { label: "Veteran", value: "ProxyVet" },
        { label: "Non-Veteran", value: "ProxyNonVet" },
        { label: "Veteran & Impacted Person", value: "ImpactedPerson" },
    ];
    }

    get mohField() {
      return getFieldValue(this.contact.data, MOH_FIELD);
    }


    
    // render templates on tab selection
    render() {
     if (this.templateChoice == 'Caller'){
            return callerTemplate;
        } else if (this.templateChoice == 'Veteran'){
            return veteranTemplate;
        }  else if (this.templateChoice == 'NonVeteran'){
            return nonVeteranTemplate;
        }  else if (this.templateChoice == 'ImpactedPerson'){
            return thirdPartyTemplate;

        } else if (this.templateChoice == 'Verify'){
          this.searchResultId = this.searchResultId ? this.searchResultId : this.verifySearchResultId;
          return verifyTemplate;
          // this.renderVerify = true;

        }

    }

    //set defaults and receive record type ids - get ocr and ops too
    connectedCallback(){
      
        getUserPermissionSets().then((result) => {
          this.showSpinner = false;
            result.forEach(perm => {
              if (perm == 'VIEWS_WH_Hotline_OCR_Member') {
                this.isOCRMember = true;
                this.showAdditional = true;
              }
              else if (perm == 'WH_VA_Hotline_Operations_Team') {
                this.isOPSMember = true;
                this.showAdditional = true;
              }
            });
          })
            .catch((error) => {
              this.showSpinner = false;
              
            });
          //this is the message which sets id: WHVAHotlineCaseContact__c
        //set the defaults for the inital caller template
        //TODO: create an isDefault method to set defaults and also to set an 'isdefault' attribute to use elsewhere

        this.hasProxy = this.hasProxy ? this.hasProxy : this.prox;
      if (this.selectedTemplate == 'Caller'){
        this.callerType = 'SelfVet';
        // this.relationshipType = ''
        this.showSpinner = true;
        this.whoIsCallingDefault = 'Vet';
        this.whoIsCallingSelection = 'Vet';
        this.showCallingForGroup = false;


          var payload = {
            // hasProxy: this.hasProxy,
            whoIsCalling : this.whoIsCallingDefault,
            callingFor : this.callingForSelection,
            relationshipType: this.relationshipType,
            isAnon: this.isAnon,
            isOCRMember: this.isOCRMember,
          };
          publish(this.messageContext, setLookups, payload);
        }
       
    }

  
    //FIELD FORM LOGIC
    // send an event to the aura to handle which tabs are displayed, and deteremine to show the conditional radio button groups
    handleWhoIsCallingChange(event){
        this.searchInfoLineTwo = '';

        var whoIsCalling = event.detail.value;
        this.whoIsCallingSelection = event.detail.value;
        //switch custom labels based on selection
        switch(whoIsCalling){
          //grab record id to use in verify template and re-render using that template
          case 'Anonymous':
            this.callerType = 'Anon';
            this.searchInfo = anonSearch;
            //if results are showing, we only want to switch here
            this.showResultsTable = false;
            // this.isAnon = true;
            // this.showSearchCriteria = false;
            break;
          case 'Vet':
            this.callerType = 'SelfVet';

            // this.showSearchCriteria = true;

            this.searchInfo = selfVetSearch;
            // this.showVeteranFields = true;
            break;

          case 'NonVet':
            this.callerType = 'SelfNonVet';

            // this.showSearchCriteria = true;

            this.searchInfo = selfNonVetSearch;
            // this.showVeteranFields = false;
            break;

          case 'Proxy':
            this.callerType = 'ProxyVet';

            this.searchInfo = proxyVetSearch;

            break;

          default:

        }
        //when swtiched, false if this.isAnon is false and resuls are true

         this.isAnon = this.whoIsCallingSelection == 'Anonymous' ? true : false;
         //if anon, dont ever show results table
         if (this.isAnon) {
          this.anonymousCheckbox = true;
          this.showResultsTable = false;
          this.showSearchCriteria = false;
         
         } else {
          this.anonymousCheckbox = false;
          this.showSearchCriteria = true;
         }

           //if there are stored results but the table is false (anon prviously selected and set it to false), then show it again (as long as not anonymous seleciton again)
           if (this.searchResults && !this.showResultsTable && !this.isAnon) {
            this.showResultsTable = true;
           }

        
        //show Veteran or Non Vet (false) fields
        this.showVeteranFields = this.whoIsCallingSelection == 'Vet' ? true : false;
        //vet, custom label
       
    
        //sending event to aura
        this.dispatchEvent(
          new CustomEvent("whoiscallingchange", { detail: {whoIsCalling} })
        );
       
        if (whoIsCalling == "Proxy") {
            this.hasProxy = true;
            this.showCallingForGroup = true;
            this.whoAreTheyCallingForDefault = "ProxyVet";
            this.showRelationshipCombobox = true;
        } else {
            this.hasProxy = false;

            this.showCallingForGroup = false;
            this.showRelationshipCombobox = false;
        }

        var payload = {
          hasProxy: this.hasProxy,
          whoIsCalling : this.whoIsCallingSelection,
          callingFor : this.whoAreTheyCallingForDefault,
          relationshipType: this.relationshipType,
          isAnon: this.isAnon,
          isOCRMember: this.isOCRMember,
          // callerType: 'Self-Veteran',
        };
        publish(this.messageContext, setLookups, payload);
        //TODO: send this to the housing Aura to store if is proxy or not
        // publish(this.messageContext, setLookups, payload);


    }

    // send an event to the aura to handle which tabs are displayed, and deteremine to show the conditional radio button groups
    handleWhoAreTheyCallingForChange(event){
         var callingFor = event.detail.value;
         this.callingForSelection = event.detail.value;
        //sending event to aura
        this.dispatchEvent(
            new CustomEvent("whoaretheycallingforchange", { detail: {callingFor} })
        );
      

        // conditional combobox logic
        if (callingFor == "ProxyVet") {
          this.callerType = 'ProxyVet';

          this.showVeteranFields = false;
            this.showRelationshipCombobox = true;
            this.searchInfo = proxyVetSearch;
            this.searchInfoLineTwo = '';
        } else if (callingFor == "ProxyNonVet"){
          this.callerType = 'ProxyNonVet';

          //caller would be veteran? TODO map person type as well
          //capture Veteran on Caller tab and Impacted Person on Non Vet tab
          this.showVeteranFields = true;
          this.searchInfo = proxyLabel;
          this.searchInfoLineTwo = proxyLabel2;
            this.showRelationshipCombobox = false;
        } else if (callingFor == "ImpactedPerson"){
          this.callerType = 'ImpactedPerson';
          this.searchInfo = impactedProxyLabel;
          this.searchInfoLineTwo = '';
            this.showRelationshipCombobox = true;
        }

        var payload = {
          hasProxy: this.hasProxy,
          whoIsCalling : this.whoIsCallingSelection,
          callingFor : this.callingForSelection,
          relationshipType: this.relationshipType,
          isAnon: this.isAnon,
          isOCRMember: this.isOCRMember,
          // callerType: 'Self-Veteran',
        };
      publish(this.messageContext, setLookups, payload);

    }

    firstNameChange(event) {
      this.firstName = event.detail.value;
      this.FNhasValue = (event.detail.value) ? true : false;
      this.fieldCheck(); 
    }
  
    lastNameChange(event) {
      this.lastName = event.detail.value;
      this.LNhasValue = (event.detail.value) ? true : false;
      this.fieldCheck();
    }


     
    dobChange(event) {
      // var dob;
      // if (!this.showVeteranFields){
      //   dob = this.template.querySelector('lightning-input[data-id=birthdateAdditional]');
      // }
      // if (this.showVeteranFields){
        let dob = this.template.querySelector('lightning-input[data-id=birthdate]');
      // }


        if (event.target.value) {

        this.dobInput = event.target.value;
        this.DOBhasValue = true;
          if (event.key == 'Backspace') { //field retains valid value after backspace, need to reevaluate
            dob.blur();
            dob.focus();
            this.DOBhasValue = false;
          }
        this.fieldCheck();

      } else {
       if (event.key != 'Tab') {
             dob.blur();
             dob.focus();
             
             if (dob.reportValidity() && event.key != 'Backspace'){
         this.DOBhasValue = true;
       } else {
         this.DOBhasValue = false;
       }
       } else {
        if (dob.reportValidity() && event.key != 'Backspace' && this.dobInput) {
          this.DOBhasValue = true;
        } else {
          this.DOBhasValue = false;
        }
       }


        
        // dob.blur();
        // dob.focus();
      }
    
    }

      /* workaround for date input field not providing value until blurred with valid value
        get element, blur, report validity, focus back if tab (9) or backspace (8), missing scenario is tab
        from inside dob field
      */
  
    
    SSNclicked(event) {
      if (event.target.value.length === 9) {
        this.rightClickPasted = true;
      }
      this.SSNcheck(event);
    }

    SSNcheck(event) {
      this.SSNinput = event.target.value;
      this.setSSN = ssnMask(event.target.value);
      if (this.templateChoice == 'Verify'){
        this.template.querySelector('lightning-input-field[data-id=ssnV]').reportValidity();
   //   }else if (this.showVeteranFields){
        this.template.querySelector('lightning-input[data-id=ssn]').reportValidity();
    //  } else if (!this.showVeteranFields){
    //      this.template.querySelector('lightning-input[data-id=ssnAdditional]').reportValidity();
      }
     

      // 9 digit ssn
      //if (this.SSNinput.length < 9) {
      if (this.SSNinput.length < 11) {
        //this.SSNerror = true;
        this.SSNhasValue = false;
      }
      if (this.SSNinput.length === 0) {
        //this.SSNerror = false;
        this.SSNhasValue = false;
      }
      //if (this.SSNinput.length === 9) {
      if (this.SSNinput.length === 11 || this.rightClickPasted) {
        //this.SSNerror = false;
        this.SSNhasValue = true;
      }
       

      this.fieldCheck();
      
    }

    emailChange(event) {
      const uid = event.currentTarget.dataset.inputuid;
      var value = event.currentTarget.value;
      
      value = value.trim();
      this.emailTrimmed = value;
      this.template.querySelector(
        'lightning-input[data-inputuid="' + uid + '"]'
      ).value = value;
      this.template.querySelector(
        'lightning-input-field[data-uid="' + uid + '"]'
      ).value = value;
      if (value != null && value != "") {
        this.emailHasValue = true;
      } else {
        this.emailHasValue = false;
      }
      

      this.fieldCheck();
    }


    phoneChange(event) {
      if (event.detail.value) {
        this.phoneHasValue = true;
        this.setPhone = event.detail.value;
      } else {
        this.setPhone = '';
        this.phoneHasValue = false;
      }
      this.fieldCheck();
    }

    homePhoneChange(event) {
      if (event.detail.value) {
        this.homePhoneHasValue = true;
      } else {
        this.homePhoneHasValue = false;
      }
      this.fieldCheck();
    }

    handleRelType(event) {
      this.relationshipType = event.detail.value;
      // if (value != null && value != "") 
      if (event.detail.value != null && event.detail.value != "") {
        this.RThasValue = true;
      } else {
        this.RThasValue = false;
      }
      this.fieldCheck();
      //this.relationshipType = event.detail.value;
      //send update everytime its changed
      var payload = {
        hasProxy: this.hasProxy,
        whoIsCalling : this.whoIsCallingSelection,
        //this shouldnt be default, it was?
        callingFor : this.callingForSelection,
        relationshipType: this.relationshipType,
        isAnon: this.isAnon,
        isOCRMember: this.isOCRMember,
        // callerType: 'Self-Veteran',
      };
      publish(this.messageContext, setLookups, payload);
    }

    handleMaidenName(event) {
      this.maidenName = event.target.value;
    }
    handleBirthCity(event) {
      this.birthCity = event.target.value;
    }
    handleBirthState(event) {
      this.birthState = event.target.value;
    }

    fieldCheck() {
     
    if (this.whoIsCallingSelection == 'NonVet' || this.whoIsCallingSelection == 'Vet'){

      this.fieldWithoutRelCheck();
      }

      //verify that both name fields are populated, and either DOB or SSN are populated
      
      // if (this.whoIsCallingSelection == 'Vet'){
      //   if (
      //     (this.FNhasValue && this.LNhasValue && (this.emailHasValue || this.phoneHasValue || this.DOBhasValue || this.SSNhasValue)) 
      //      ) {
      //     this.disableSearch = false;
      //   } else {
      //     this.disableSearch = true;
      //   }
      // } else if (this.whoIsCallingSelection == 'NonVet'){
      //   if (
      //     this.FNhasValue &&
      //     this.LNhasValue &&
      //     (this.emailHasValue || this.phoneHasValue)
      //     ) {
      //       this.disableSearch = false;
      //     } else {
      //       this.disableSearch = true;
      //     }
      // } else 
      //TODO: Relationship consideration 
      if (this.prox || this.hasProxy){
          //for these, we need a relationship type
          if ( ( (this.proxForVet || this.callingForSelection == 'ImpactedPerson') && this.selectedTemplate == 'Caller' ) || (!this.proxForVet && this.selectedTemplate == 'NonVeteran')
            || this.selectedTemplate == 'ImpactedPerson'){

           this.fieldWithRelCheck();
          }
          //no relationship needed here
          else if (!this.proxForVet && this.selectedTemplate == 'Caller'|| this.proxForVet && this.selectedTemplate == 'Veteran' ){
           this.fieldWithoutRelCheck();
          //defautl would be proxy vet, just determine caller and vet tabs
          } else {
            if (this.selectedTemplate == 'Caller'){
              this.fieldWithRelCheck();
            } else {
              this.fieldWithoutRelCheck();
         
            }
          }
      }
      //default Vet
      else {
        this.fieldWithoutRelCheck();

      }
  
    }

   
    fieldWithoutRelCheck(){
      //last name and any two fields
      const inputFields = this.template.querySelectorAll("lightning-input-field");
      var count = 0;
      var hasTemplate;
      var hasRel;
      if (inputFields) {
        inputFields.forEach((field) => {
          if (field.value){
            count++;
          }
        });
      }

      if (this.SSNhasValue) {

        count++;
      }
      if (this.DOBhasValue){
        count++;
      }
 

//subtract one because template field automatically carries a value
      if (count >= 3 && this.LNhasValue){
        //enable search;
        this.disableSearch = false;

      } else {
        this.disableSearch = true;

      }
 

      // if (
      //   (this.FNhasValue && this.LNhasValue && (this.emailHasValue || this.phoneHasValue)) 
      //   || (this.FNhasValue && this.LNhasValue && (this.DOBhasValue || this.SSNhasValue))
      //   ) {
      //     this.disableSearch = false;
      //   } else {
      //     //disable button if not all are populated
      //     this.disableSearch = true;
      // }
    }

    fieldWithRelCheck(){
      
      
      //last name and any two fields
      const inputFields = this.template.querySelectorAll("lightning-input-field");
      var count = 0;
      var hasTemplate;
      var hasRel;
      if (inputFields) {
        inputFields.forEach((field) => {
          if (field.value){
           
            count++;

            if (field.fieldName === "Relationship_Type__c"){
              hasRel = true;
            }
          }
        });
      }

      if (this.SSNhasValue) {

        count++;
      }
      if (this.DOBhasValue){
        count++;
      }
      if (hasRel){
        count--;
      }

   
      if (count >= 3 && this.LNhasValue && this.RThasValue && this.relationshipType.length > 0){
        //enable search;
        this.disableSearch = false;

      } else {
        this.disableSearch = true;

      }
      
      // if (
      //   ((this.FNhasValue && this.LNhasValue && (this.emailHasValue || this.phoneHasValue)) 
      //   || (this.FNhasValue && this.LNhasValue && (this.DOBhasValue || this.SSNhasValue)) )&& this.RThasValue && this.relationshipType.length > 0
      //   ) {
      //     this.disableSearch = false;
      //   } else {
      //     //disable button if not all are populated
      //     this.disableSearch = true;
      // }
    }

      //TODO: which fields to trigger enabling search

      //NEW CONTACT
      handleNewContactButton() {
        //TODO: prevent clicking twice
        const inputFields = this.template.querySelectorAll("lightning-input-field");
        const contact = {};
        //TODO: change method to accept without person type, overload?
        const recordTypeName = this.newConRTName;
       // this.recordTypeName = this.newConRTName;
        if (inputFields) {
          inputFields.forEach((field) => {
            contact[field.fieldName] = field.value;
              if (field.fieldName === "Phone") {
              if (this.phoneHasValue) {
                field.value = field.value.toString().replace(NON_DIGIT_REGEX, "");
              }
              // 
              //
            }
            if (field.fieldName === "HomePhone") {
              if (this.homePhoneHasValue) {
                field.value = field.value.toString().replace(NON_DIGIT_REGEX, "");
              }
            }
          });
        
            if (this.SSNhasValue) {
            contact.SSN__c = (this.setSSN).replace(/[^0-9.]/g, "");
          //  contact.SSN__c = this.setSSN;
            }
            if (this.dobInput) {
              contact.Birthdate = (this.dobInput);
            }
            if (this.emailHasValue){
              contact.Email = (this.emailTrimmed);
            }
        }

      //duplicate contact
    NewContactModal.open({
      // maps to developer-created `@api options`
      label: "Modal Header",
      contact: contact,
    }).then((result) => {
    });
    //sends to WHVAHotlinePErsonSearchAura
    //TODO: create the New Contact Aura form from here? 
    // this.dispatchEvent(
    //   new CustomEvent("newcontact", {
    //     detail: { contact, recordTypeName }
    //   })
    // );
    this.templateToReturnTo = this.templateChoice;



      }

      //CLEAR
      handleClear() {
        const lightningInputFields = this.template.querySelectorAll("lightning-input-field");
        const inputFields = this.template.querySelectorAll("lightning-input");

       
        if (lightningInputFields) {
          lightningInputFields.forEach((field) => {
            field.value = "";
          });
        }

        if (inputFields) {
            inputFields.forEach((field) => {
              field.value = "";
            });
          }
          //clear stored values - ssn, dob, email phone
          this.setSSN = '';
          this.emailTrimmed = '';
          this.setPhone = '';
          this.dobInput = '';
          this.FNhasValue = false;
          this.SSNhasValue = false;

       this.phoneHasValue = false;
          this.LNhasValue = false;
          //reset to false
          this.RThasValue = false;
          this.SSNhasValue = false;
          this.DOBhasValue = false;
          this.showResultsTable = false;
          this.disableSearch = true;
          this.exactMatch = true;

      }
    
   
      //SEARCH AND DATA TABLE HANDLERS
      handleSearch(){
        //make sure we reset the result each time so if theres no result, the old results dont persist
        this.searchResults = [];
        this.disableNewContact = false;

        this.showSpinner = true;
        const inputFields = this.template.querySelectorAll("lightning-input-field");
        const contact = {};
        
        //  
       //get selection stored
       var sendPersonType;

   
        if (inputFields) {
          inputFields.forEach((field) => {
            // determine tab by the template field
            
            if (field.fieldName === "Template"){
       //TODO template choice and template value can probably be the same thing, why did i need this field? to return to the correct template
              this.tempValue = field.value;

            }
            if (field.fieldName === "Phone") {

              if (this.phoneHasValue) {

                field.value = field.value.toString().replace(NON_DIGIT_REGEX, "");
              }
              // 
              //
            }
            if (field.fieldName === "HomePhone") {
              if (this.homePhoneHasValue) {

                field.value = field.value.toString().replace(NON_DIGIT_REGEX, "");
              }
            }
            if (this.SSNhasValue) {
            contact.SSN__c = (this.setSSN).replace(/[^0-9.]/g, "");
          //  contact.SSN__c = this.setSSN;
            }
            if (this.dobInput) {
              contact.Birthdate = (this.dobInput);
            }
            if (this.emailHasValue){
              contact.Email = (this.emailTrimmed);
            }
            contact[field.fieldName] = field.value;
    
            // this.person[field.fieldName] = field.value;
          });
        }

      //set determination of person type here to use in Person Search, and New Contact Form, Updating Case
      this.setPersonType();

       
       //new contact form record name set
       this.newConRTName = this.personType == 'Veteran' ? 'Unverified_Veteran' : 'VIEWS_Tier_1_Call_Center';
       sendPersonType = this.personType;
       var results;
       
      //   personSearch({ con: contact, personType: sendPersonType, sfFirst: false }).then((result) => {
      //     this.showSpinner = false;
      //   //   

        

      //     if (result.length > 0) {
      //     // let caseArray = [];
      //  //   this.searchResultId = result;
      //     this.handleResults(result);
      //       //
         
      //     //if theres no results, then we want show table false and to display message
      //     } else {
      //       //TODO: no results vs. error
      //       this.showResultsTable = false;
      //       this.noResults = true;
      //       this.errorMessage = 'No matches were returned from MPI or Salesforce. Please refine your search and try again.';

      //     }
         
      //   }) .catch((error) => {
      //     this.showResultsTable = false;

      //     this.showSpinner = false;
      //     this.noResults = true;
      //     this.errorMessage = 'There was an error establishing a connection with MPI. Please refresh your page and try again.';


          
      //   });
    //  NO RECORD TYPE SEARCH - FUTURE
          doCombinedSearch({ con: contact, sfFirst: false }).then((result) => {
          this.showSpinner = false;
            results = result;

          if (result.length > 0) {

          // let caseArray = [];
       //   this.searchResultId = result;
          this.handleResults(result);
            //
         
          //if theres no results, then we want show table false and to display message
          } else {
            //TODO: no results vs. error
            this.showResultsTable = false;
            this.showMPIError = false;
            this.noResults = true;
            this.errorMessage = 'No matches were returned from MPI or Salesforce. Please refine your search and try again.';
          }
         
        }).catch((error) => {

          if (results) {

          // let caseArray = [];
       //   this.searchResultId = result;
          this.handleResults(results);
            //
         
          //if theres no results, then we want show table false and to display message
          } else if (error.status == '500'){
            //TODO: no results vs. error
          
          this.showMPIError = false;
          this.showResultsTable = false;
          this.showSpinner = false;
          this.noResults = true;
          this.errorMessage = 'There was an error establishing a connection with MPI. Please refresh your page and try again.';
          } else if (error.status == '404'){
           
              //TODO: no results vs. error
              this.showResultsTable = false;
              this.showSpinner = false;
              this.showMPIError = false;
              this.noResults = true;
              this.errorMessage = 'No matches were returned from MPI or Salesforce. Please refine your search and try again.';
            
          }

          
        });


      }


      receivedEDIPIdata(event){
        this.searchResults = [];
        retrieveMPIE({ edipi: event.detail.edipi })
          .then((result) => {
            this.showSpinner = false;
         
            if (result[0] != undefined) {
              this.setPersonType();
              

              this.handleResults(result);

            } else {
              //TODO: no results vs. error
              
              this.showResultsTable = false;
              this.noResults = true;
              this.errorMessage = 'No matches were returned from EDIPI. Please refine your search and try again.';
              // 

              // this.showTable = false;
              // this.showError = true;
            }
            //if theres no results, then we want show table false and to display message
            //on result -> send data to another lwc which will render the table for us
          })
          .catch((error) => {
          //  this.handleMPIError();
            this.showResultsTable = false;
            this.noResults = true;

            this.errorMessage = 'No matches were returned from EDIPI. Please refine your search and try again.';

            this.showSpinner = false;
          });
      }

      // handleMPIError(){
      //   if (x.MPIError){
      //     this.showMPIError = true;
      //     this.showResultsTable = true;
      //     this.showSpinner = false;
      //     this.errorMessage = 'There was an error establishing a connection with MPI. The results displayed are from Salesforce only.';


      //   } else {}
      // }
      //logic to set person type to determine impactd person or caler field population
      setPersonType(event){

        if (this.whoIsCallingSelection == 'Vet'){
         this.personType = 'Veteran';
 
 
        } else if (this.whoIsCallingSelection == 'NonVet'){
         this.personType = 'NonVeteran';
 
         //default
         //TODO: reconfig for separate searches - future release
        } else if (this.whoIsCallingSelection == 'Proxy' || this.prox || this.hasProxy) {
         //proxy calling for a vet means the caller is a non vet, or if its a proxy for non vet, the non vet is the tab
           if (this.proxForVet && this.selectedTemplate == 'Caller' || !this.proxForVet  && this.selectedTemplate == "NonVeteran" ){
             if (this.relationshipType == 'Veteran'){
               this.personType = 'Veteran';
               
             } else {
               this.personType = 'NonVeteran';
 
             }
             //proxy calling for non vet, caller is a Vet, proxy for Vet, Vet tab is Vet
           } else if (!this.proxForVet && this.selectedTemplate == 'Caller' || this.proxForVet && this.selectedTemplate == "Veteran" ){

             this.personType = 'Veteran';
 
           // } else if (this.callingForSelection == 'VetOrNonVet'){
           //   //third party
 
           //DEFAULT is Veteran, so default would be caller tab is nonveteran
           } else if (this.selectedTemplate == 'Caller'){
             this.personType = 'NonVeteran';
 
           } else if (this.selectedTemplate == 'Veteran'){
             this.personType = 'Veteran';
           }
       //default
        } else {
         this.personType = 'Veteran';
 
        }
       }



      //handle both kinds of results, person search or edipi, and render data table
      handleResults(result){
        let caseArray = [];
        this.searchResults = result;
        //assign the search results some values to display in the table
        //set this as false to begin with
        this.hasVAP = false;
        //reset to default each time there is a search
        this.exactMatch = true;
        this.searchResults.forEach(x => {
          //if the entered fields arent exact, little error message TODO
          if (x.MPIError){
            this.showMPIError = true;
            this.showResultsTable = true;
            this.showSpinner = false;
            this.errorMessage = 'There was an error establishing a connection with MPI. The results displayed are from Salesforce only.';
  
  
          }
        const inputFields = this.template.querySelectorAll("lightning-input-field");
        if (inputFields) {
          inputFields.forEach((field) => {
      
              //check if a field has a value from the user input, if it matches the returned contact's value 
              //if any of them arent exact, the exactmatch will be false and prompt the warning banner
              //eexactmatch is defaulted to true, and only is false when one of these values doesnt match
              if (this.phoneHasValue && field.fieldName === "Phone"){

                if (field.value !== x.Phone) {
                  this.exactMatch = false;
                }
              } 
              if (this.FNhasValue && field.fieldName === "FirstName" && field.value && x.FirstName){

                if (field.value.toUpperCase() !== x.FirstName.toUpperCase()) {

                  this.exactMatch = false;
                }
              }
              if (this.LNhasValue && field.fieldName === "LastName" && field.value){

                if (field.value.toUpperCase() !== x.LastName.toUpperCase()) {

                  this.exactMatch = false;
                }
              }
              //add to checks to find value
              if (field.fieldName === "MailingPostalCode" && field.value){
                if (field.value !== x.MailingPostalCode) {
                  this.exactMatch = false;
                }
              } 
              //check if contact ahs fields before converting
              if (field.fieldName === "MiddleName" && field.value && x.MiddleName){
                if (field.value.toUpperCase() !== x.MiddleName.toUpperCase()) {

                  this.exactMatch = false;
                }
              } 
              //not sure about email?
              if (this.emailHasValue && field.fieldName === "Email" && field.value && x.Email){

                if (field.value.toUpperCase() !== x.Email.toUpperCase()) {

                  this.exactMatch = false;
                }
              }
              //these arent input fields
              if (this.DOBhasValue){
                if (this.dobInput !== x.Birthdate) {

                  this.exactMatch = false;
                }
              }
              if (this.SSNhasValue){
                //compare proper format
                if ((this.setSSN).replace(/[^0-9.]/g, "") !== x.SSN) {

                  this.exactMatch = false;
                }
              }


            //repeat for fname, lname, ssn, dob, middle name, phone, email, zip (additional?)
            // if (field.fieldName === "HomePhone") {
            //   if (this.homePhoneHasValue) {
            //     field.value = field.value.toString().replace(NON_DIGIT_REGEX, "");
            //   }
            // }
  
          });
        }
        
          if (x.RecordTypeName){
            x['RecordTypeName'] = x.RecordTypeName;
          //if theres no record type and its MPI, check person type
          } else if (x.externalSource){
            //person type?
            if (x.MPIPersonType){
                var personType = x.MPIPersonType;
                var vetPersonCode = "VET";
              //if person type inclues VET, its a vet
              if (personType.includes(vetPersonCode)){
                x['RecordTypeName'] = 'Veterans';
              //if person type doesnt, its Non
              } else {
                x['RecordTypeName'] = 'Non-VA Employee/Non-Veteran';
              }
            //no person type for MPI, default is Vet per MPI
            } else {
              x['RecordTypeName'] = 'Veterans';

            }
          
          //if theres no record type or person type, this is the default, this shouldnt happen (default should be unverified vet probably)
          } else {
            x['RecordTypeName'] = 'Unknown';

          }
          // if (x.MPI_PersonType__c.includes("VET")){
          //   x.RecordTypeName = "Veterans";

          // } else {
          //   x.RecordTypeName = "Non-VA Employee/Non-Veteran";
          // }
          if (x.VAPEmail || x.VAPPhone || x.VAPZipCode){
            this.hasVAP = true;
          } 
          // if (x.SpecialInstructions){
          //   siMap.set(x.Id, x.SpecialInstructions);
          // }
          // else block will remove VAP if one person doesnt have it
          // else {
          //   this.hasVAP = false;
          // }

          //for regular case column
          // x.VACX_Cases.forEach(y => {
          //   caseArray.push(y.Name);
  
          // });
          // x['casesToDisplay'] = caseArray;
          // 

        });
        //
        this.showResultsTable = true;
        this.noResults = false;
   //if they have vap, assign columns one way, if not, the other way
   if (this.hasVAP){
    this.columns = [
      { label: "Identifier", fieldName: "RecordTypeName" },

      { label: "First Name", fieldName: "FirstName", type: 'button',
      typeAttributes: { label: {fieldName: "FirstName"},  contactid: {fieldName: "FirstName"}, variant: 'base', name: 'selectContact' } },
      { label: "Last Name", fieldName: "LastName", type: 'button',
      typeAttributes: { label: {fieldName: "LastName"}, contactid: {fieldName: "LastName"}, variant: 'base', name: 'selectContact' } },
      { label: "Middle Name", fieldName: "MiddleName" },
      {label: "External Source",
      fieldName: "externalSource",
      type: "externalSourceCell",
      typeAttributes: {
        source: { fieldName: "externalSource" },
        gal: { fieldName: "gal" }
      }
      },
      { label: "DOB", fieldName: "Birthdate" },
      { label: "SSN", fieldName: "SSN" },
      { label: "EDIPI", fieldName: "EDIPI" },
      { label: "Email", fieldName: "Email" },
      // regular Case column
      // { label: "Cases", fieldName: "casesToDisplay", type: 'button', wrapText: true,
      // typeAttributes: { label: {fieldName: "casesToDisplay"}, variant: 'base', name: 'selectCase' } },
      // custom case column using custom component
      {label: "Cases",
      fieldName: "VACX_Cases",
      type: "caseCell",
      typeAttributes: {
        vacx_cases: { fieldName: "VACX_Cases" }}
      },
      
      { label: "VAP EMAIL", fieldName: "VAPEmail" },
      { label: "VAP PHONE", fieldName: "VAPPhone" },
      { label: "VAP ZIP CODE", fieldName: "VAPZipCode" },
    ];
  } else if (!this.hasVAP){
    this.columns = [
      { label: "Identifier", fieldName: "RecordTypeName" },

      { label: "First Name", fieldName: "Id", type: 'button',
      typeAttributes: { label: {fieldName: "FirstName"}, contactid: {fieldName: "Id"}, variant: 'base', name: 'selectContact' } },
      { label: "Last Name", fieldName: "Id", type: 'button',
      typeAttributes: { label: {fieldName: "LastName"}, contactid: {fieldName: "LastName"}, variant: 'base', name: 'selectContact' } },
      { label: "Middle Name", fieldName: "MiddleName" },
      {label: "External Source",
      fieldName: "externalSource",
      type: "externalSourceCell",
      typeAttributes: {
        source: { fieldName: "externalSource" },
        gal: { fieldName: "gal" }
      }
      },
      { label: "DOB", fieldName: "Birthdate" },
      { label: "SSN", fieldName: "SSN" },
      { label: "EDIPI", fieldName: "EDIPI" },
      { label: "Email", fieldName: "Email" },
      // regular Case column
      // { label: "Cases", fieldName: "casesToDisplay", type: 'button', wrapText: true,
      // typeAttributes: { label: {fieldName: "casesToDisplay"}, variant: 'base', wrapText: true, name: 'selectCase' } },
      // custom case column using custom component
      {label: "Cases",
      fieldName: "VACX_Cases",
      type: "caseCell",
      typeAttributes: {
        vacx_cases: { fieldName: "VACX_Cases" }}
      },
    ];
  }
       //TODO:  if () {
          //   this.columns = [...cols];
          // } else {
          //     // return every column but the one you want to hide
          //     this.columns = [...cols].filter(col => col.fieldName != 'name');
          // }
  
        
    
      }

     
  
      handleMouseOver(event) {

          this.showPopover = true;
          this.selectedcase = event.detail.case;
          this.top = event.detail.top;
          this.left = event.detail.left;
      }
  
      handleMouseOut() {
          this.showPopover = false;
      }

    
      handleRowAction(event){
        const actionName = event.detail.action.name;
        //call this again in case its changed (by switching radio buttons with results present)
      this.setPersonType();

        switch(actionName){
          //grab record id to use in verify template and re-render using that template
          case 'selectContact':
            //here is where we could create contact in SF
            
            // const index = this.searchResults.findIndex(user => user.id === row.id);
            this.searchResultId = event.detail.row.Id ? event.detail.row.Id : null;
            this.recordTypeName = event.detail.row.RecordTypeName;
            // 
            this.theContact = event.detail.row.theContact;
            // 
            //store this to know which template to return to, should be the template you are currently on 
            this.templateToReturnTo = this.selectedTemplate;

            //then change to Verify

        
     
           if (this.searchResultId != null){
              this.templateChoice = 'Verify';
              // this.carmaCallout();
              this.showVAP = true;
              if (this.theContact.SpecialInstructions){
                //special instructions toast - i can put this here
                const event = new ShowToastEvent({
                  title: "Attention",
                  message: this.theContact.FirstName + " " + this.theContact.LastName + " has Special Instructions",
                  variant: "warning",
                  mode: "dismissable",
                  duration: "10000ms",
                });
                this.dispatchEvent(event);
              }
              
              // if (event.getParam("specialInstructions")) {
              //   var toastMessage = "";
              //   if (event.getParam("FirstName")) {
              //     toastMessage += event.getParam("FirstName") + " ";
              //   }
              //   if (event.getParam("LastName")) {
              //     toastMessage += event.getParam("LastName") + " ";
              //   }
              //   toastMessage += "has Special Instructions";
              //   helper.showSpecialInstructions(toastMessage);

            } else {
              this.createContactInSalesforce(event.detail.row.theContact);
            }
            //set verify defaults
            if (
              this.recordTypeName === "Unverified Veteran" ||
              this.recordTypeName === "Unverified Non VA Employees/Non Veterans"
            ) {
              this.disableVerified = false;
              this.disabled = false;
              // this.editButton = false;
            } else if (
              this.recordTypeName === "Non-VA Employee/Non-Veteran" ||
              this.recordTypeName === "Veterans"
            ) {
              this.disabled = false;
              this.disableVerified = true;
              // this.editButton = false;
            }
            if (this.isOPSMember) {
              this.disableSpecial = true;
            } else {
              this.disableSpecial = false;
            }

            break;


          default:

        }
       
      }

      //this is only for MPI contacts
      createContactInSalesforce(mpiCon){
        
        this.showSpinner = true;
        var recordType = mpiCon.MPI_PersonType__c;
        var mpiPersonType;
        var mpiContactId;
        if (recordType){
          var vetPersonCode = "VET";
          // var getCodeIndex = recordType.indexOf(vetPersonCode);
          //if its nnot -1, it contains the code
          // if (getCodeIndex != -1) {
          if (recordType.includes(vetPersonCode)){
            mpiPersonType = "Veteran";
          } else {
            mpiPersonType = "Non-Veteran";
          }
        } else {
          mpiPersonType = 'Veteran';
        }

        saveMPIContact({ con: mpiCon, personType: mpiPersonType })
        .then((result) => {
          this.showSpinner = false;
          //naivgate back to case record? or maybe just a success alert?
          if (result) {
            
            const event = new ShowToastEvent({
              title: "Success",
              message: "Contact has been saved and added to the database.",
              variant: "success",
              mode: "dismissable",
              duration: "10000ms",
            });
            this.dispatchEvent(event);
            this.searchResultId = result;
            this.templateChoice = 'Verify';
            this.showVAP = true;

          }
        })
        .catch((error) => {
          //SHOW ERROR TOAST
          this.showSpinner = false;
          const event = new ShowToastEvent({
            title: "Error",
            message: 'There was an error adding this contact to the database due to a duplicate SSN. Please notify your administrator and proceed by selecting another option or creating a new contact without the SSN.',
            variant: "error",
            mode: "sticky"
          });
          this.dispatchEvent(event);
          
        });

        //special instructions toast - i can put this here  
            // const event = new ShowToastEvent({
            //   title: "Attention",
            //   message: "Contact has been saved and added to the database.",
            //   variant: "warning",
            //   mode: "dismissable",
            //   duration: "10000ms",
            // });
            // this.dispatchEvent(event);

        // if (event.getParam("specialInstructions")) {
        //   var toastMessage = "";
        //   if (event.getParam("FirstName")) {
        //     toastMessage += event.getParam("FirstName") + " ";
        //   }
        //   if (event.getParam("LastName")) {
        //     toastMessage += event.getParam("LastName") + " ";
        //   }
        //   toastMessage += "has Special Instructions";
        //   helper.showSpecialInstructions(toastMessage);
        
 
        return mpiContactId;
      }

      insertMPIContactInSalesforce(mpiCon){
        //  
          //create contact w apex method
          // return id?
         // return 'hi';
          var mpiContactId = '';
          
          insertMPIContact({ con: mpiCon })
          .then((result) => {
            this.showSpinner = false;
            //naivgate back to case record? or maybe just a success alert?
            if (result) {
              const event = new ShowToastEvent({
                title: "Success",
                message: "Contact has been saved and added to the database.",
                variant: "success",
                mode: "dismissable",
                duration: "10000ms",
              });
              this.dispatchEvent(event);
              mpiContactId = result.Id;
              // const fields = event.detail.fields;
              // this.template
              //   .querySelector("lightning-record-edit-form")
              //   .submit(fields);
              this.showSpinner = true;
            }
          })
          .catch((error) => {
            
          });
          return mpiContactId;
  
        }

      handleMouseOver(event) {
        this.showPopover = true;
        this.selectedCase = event.detail.case;
        this.top = event.detail.top;
        this.left = event.detail.left;
    }

    handleMouseOut() {
        this.showPopover = false;
    }

      //VERIFY TEMPLATE HANDLERS

      carmaCallout() {
        //queue VAP job
        let VAPID = this.searchResultId;
        
        carmaCallout({ recordid: VAPID })
          .then((result) => {
            this.jobid = result;
            if (this.jobid) {
              this.deferCheckJobs();
            } else {
              this.showVAPSpinner = false;
              this.showVAP = true;
            }
          })
          .catch((error) => {
            
          });
      }
    
      deferCheckJobs() {
        // this checks for jobs on a 3 second timer. Adjust timer accordingly and provide a UX that lets the
        // end-user know about how long they should be expecting to wait.
        this.timeoutid = setTimeout(() => this.checkJobsLWC(), 3000);
      }
    
      checkJobsLWC() {
        //queue VAP job
        checkJobs({ jobid: this.jobid })
          .then((result) => {
            if (result) {
              result.forEach((each) => {
                if (
                  each.Status === "Completed" ||
                  each.Status === "Aborted" ||
                  each.Status === "Failed"
                ) {
                  //stop checking
                  clearTimeout(this.timeoutid);
                  //show the sections, they will load and load their respective sections, which will turn the spinner off
                  this.showVAPSpinner = false;
    
                  this.showVAP = true;
                } else if (
                  each.Status != "Completed" ||
                  each.Status != "Aborted" ||
                  each.Status != "Failed"
                ) {
                  this.deferCheckJobs();
                }
              });
            }
          })
          .catch((error) => {
            
            //if it hasnt loaded yet, try again until it does
            //insufficient access error
            if (error.status === 500) {
              const event = new ShowToastEvent({
                title: "Error",
                message:
                  "Oops! We could not load VA Profile information right now. Please try again.",
                variant: "error",
                mode: "dismissable",
                duration: "10000ms",
              });
              this.dispatchEvent(event);
            }
          });
      }
      //go back to template that was previously active
      handleCancel(event){
        //retain selections before they default
        var whoIsCalling = this.whoIsCallingSelection;
        var callingFor = this.callingForSelection;
        var proxy = this.hasProxy;
        var proxyfor = this.proxForVet;
        //set template back to what it was before
        if (this.templateToReturnTo == 'Caller'){
          this.templateChoice = 'Caller';
        } else if (this.templateToReturnTo == 'Veteran'){
          this.templateChoice = 'Veteran';
        } else if (this.templateToReturnTo == 'NonVeteran'){
          this.templateChoice = 'NonVeteran';
          //default - this happens after Create New Contact
        } else if (this.templateToReturnTo == 'ImpactedPerson'){
          this.templateChoice = 'ImpactedPerson';
          //default - this happens after Create New Contact
        } else {
            this.templateChoice = 'Caller';
            whoIsCalling = 'Vet';
        }
     
        //reset values to override default with the last selections
        this.whoIsCallingSelection = proxy ? 'Proxy' : whoIsCalling;
        this.whoIsCallingDefault = proxy ? 'Proxy' : whoIsCalling;
        this.callingForSelection = callingFor;
        this.whoAreTheyCallingForDefault = callingFor ? callingFor : this.whoAreTheyCallingForDefault;
        this.hasProxy = proxy;
        this.proxForVet = proxyfor;
       

        this.setSSN = '';
        this.emailTrimmed = '';
        this.setPhone = '';
        this.dobInput = '';
        this.FNhasValue = false;
        this.SSNhasValue = false;

     this.phoneHasValue = false;
        this.LNhasValue = false;
        //reset to false
        this.RThasValue = false;
        this.SSNhasValue = false;
        this.DOBhasValue = false;
        this.showResultsTable = false;
        this.disableSearch = true;
        this.exactMatch = true;

      

        //disable search button until criteria met again
        this.disableSearch = true;
        this.disableNewContact = true;
         //sending event to aura to reset Tabs
        this.dispatchEvent(
          new CustomEvent("whoiscallingchange", { detail: {whoIsCalling} })
        );
           //sending event to aura
           this.dispatchEvent(
            new CustomEvent("whoaretheycallingforchange", { detail: {callingFor} })
        );

       
      }
      

      saveAndAddContact(event) {
        
        this.isVeteran = this.personType == "Veteran" ? true : false;

        this.showSpinner = true;

    //TODO have this stored
         if (this.recordTypeName == "VA Employees") {
        //   //go straight to success bc we cant update
        //    this.showSpinner = true;
          this.passContactToCase();
         } else {
          const fields = event.detail.fields;
          this.template.querySelector("lightning-record-edit-form").submit(fields);
            this.passContactToCase();

     
        }

      }

      savedState(){
        if (this.callingForSelection === "ProxyNonVet") {
          this.searchInfo = proxyVetVerify;
        } else if (
          this.whoIsCallingSelection === "Vet" ||
          this.callingForSelection === "ProxyVet"
        ) {
          this.searchInfo = vetVerify2;
        }

        this.disabled = true;
        this.disableVerified = true;
        this.disableSpecial = true;

        this.saved = true;
      }

      onVerifyLoad(){
        if (this.template.querySelector('lightning-input-field[data-id=specialInstructions]').value){
          const event = new ShowToastEvent({
            title: "Attention",
            message: this.theContact.FirstName + " " + this.theContact.LastName + " has Special Instructions",
            variant: "warning",
            mode: "sticky",
          });
          this.dispatchEvent(event);
        }
      }
     
      //on save: go to saved
      //on edit, go back to edit

      editState() {
        //if its on load, saved was already false. if its coming from save and add, it was true
        //only happen on initial load
        this.saved = false;

        if (
          this.recordTypeName === "Unverified Veteran" ||
          this.recordTypeName === "Unverified Non VA Employees/Non Veterans"
        ) {
          this.disableVerified = false;
          this.disabled = false;
          // this.editButton = false;
        } else if (
          this.recordTypeName === "Non-VA Employee/Non-Veteran" ||
          this.recordTypeName === "Veterans"
        ) {
          this.disabled = false;
          this.disableVerified = true;
          // this.editButton = false;
          //when coming from create new
        } else if (this.personType == 'Veteran'){
          this.disableVerified = false;
          this.disabled = false;

        }
        if (this.isOPSMember) {
          this.disableSpecial = true;
        } else {
          this.disableSpecial = false;
        }
        // 
        
       
       
      }
    
    
      passContactToCase() {
          this.savedState();
         if (this.recordTypeName == undefined){
             getRTName({ recordType: this.template.querySelector('lightning-input-field[data-id=RecordTypeId]').value })
          .then((result) => {
            if (result) {
              this.recordTypeName = result;
              this.showSpinner = false;
              var payload = {
                contactId: this.searchResultId,
                fieldMapping: this.templateToReturnTo,
                recordTypeName: this.recordTypeName,
              };
              publish(this.messageContext, sendIds, payload);
            
              
            }
          })
          .catch((error) => {
            //error
          });
          
         } else {
          this.showSpinner = false;
          var payload = {
            contactId: this.searchResultId,
            fieldMapping: this.templateToReturnTo,
            recordTypeName: this.recordTypeName,
          };
          publish(this.messageContext, sendIds, payload);
        
         }
       
       

          //updated case
       
        //show edit field button, once clicked, enabled everything again and show add button
      }

      handleRemove() {
        //on caller tab need to specify this so it reloads properly
        var payload = {
         // veteranId: "",
          contactId: "",
          // isVeteran: this.isVeteran,
          fieldMapping: this.templateToReturnTo,

        };
        publish(this.messageContext, sendIds, payload);
     //   this.templateChoice = 'Caller';
     //we do not need to reset anything
   // this.connectedCallback();
        this.editState();

      }

      handleEdit(event) {
        // this.editStateEvent(true);
        // this.preserveData = true;
        //this removes the contact so that the user has to re-add it
        var payload = {
          // veteranId: "",
          contactId: "",
          // isVeteran: this.isVeteran,
          fieldMapping: this.templateToReturnTo,


        };
        publish(this.messageContext, sendIds, payload);
    
        this.editState();
      }

      // MPI TAB HANDLERs
      //TODO: MPI TAB FIELD MAPPINGS
      updateCase(event) {
    
    
        event.preventDefault();
        const fields = event.detail.fields;
        this.template.querySelector("lightning-record-edit-form").submit(fields);
        this.showSpinner = true;
        //tod: caller type
        //here we want veteran to be determined by the template, not necessarily the RT, bc it needs to pass to the correct lookup
       this.sendAsVeteran = this.personType == "Veteran" ? true : false;
        //var callingFor = this.callingForSelection;
        //caller type becomes undefined during a proxy seleciton when the tab is selected
        //proxy non vet only has non vet tab, proxy vet only vet
        var callingFor;
        if (this.selectedTemplate == 'Caller'){
          callingFor = this.callingForSelection;

        }
        if (this.callerType.length === 0){
          //this.callerType = callingFor;
          if (this.proxForVet){
            this.callerType = 'ProxyVet';

          } else if (this.thirdParty){
            this.callerType = 'ImpactedPerson';

          } else {
            this.callerType = 'ProxyNonVet';
          }
        }
        //apex to query for case, then update depending on these parameters
        currentCase({
          contactid: this.searchResultId,
          caseid: this.caseId,
          type: this.callerType,
          fieldMapping: this.templateToReturnTo ? this.templateToReturnTo : this.selectedTemplate,
          relType: this.relationshipType,
        })
          .then((result) => {
            this.showSpinner = false;
    
            //naivgate back to case record? or maybe just a success alert?
            const event = new ShowToastEvent({
              title: "Success",
              message: "Contact has been saved and added to the Case.",
              variant: "success",
              mode: "dismissable",
              duration: "10000ms",
            });
            this.dispatchEvent(event);

            // this.editStateEvent(false);
            // this.savedState();
            // this.dataPreserve = true;
          })
          .catch((error) => {
            this.showSpinner = false;
           // var errorMessage = error.body?.pageErrors[0].message.toString().replace('"', "");
            //insufficient access error
            // if (error.status === 500) {
              const event = new ShowToastEvent({
                title: error.body ? "An error occurred while trying to update the record. Please try again." : "Error",
                message: (error.body.pageErrors && error.body.pageErrors.length > 0) ?  error.body?.pageErrors[0].message.toString().replace('"', "") : 'Oops! Something went wrong. Please contact your administrator.',
                variant: "error",
                mode: "dismissable",
                duration: "10000ms",
              });
              this.dispatchEvent(event);
            // }
    
          });
      }

      //VAP WRITE
      addUpdateVAP(){
        this.isShowFlow = true;
          //vap open modal
          popScreenFlow.open({
            // maps to developer-created `@api options`
            label: "Add/Update VAP",
            contactId: this.searchResultId,
          }).then((result) => {
          });
      }

      get flowVariables(){
        return [
          {
            // Match with the input variable name declared in the flow.
            name: "ContactId",
            type: "String",
            // Initial value to send to the flow input.
            value: this.searchResultId,
          }
        ];
      }

      handleStatusChange(event) {
        var listOfKeys = [];
        var listOfValues = [];

        if (event.detail.status === "FINISHED") {
          // set behavior after a finished flow interview.
          const outputVariables = event.detail.outputVariables;
          for (let i = 0; i < outputVariables.length; i++) {
            var outputVar = outputVariables[i];
            //a map of name and value
            //name => name__c
            //convert to the correct api name to push

            //edit will be prefaced with 'Edit'
            //new will be prefaced with 'New'
            //i have to handle these different? update vs. insert..
            //if same call, can handle names here and pass to one method, otherwise, handle here and pass to diff methods depening on flow aciton
            if (outputVar.name == "SFId") {
              outputVar.name = outputVar.name;
            } else {
              outputVar.name = outputVar.name + '__c';
            }
            
            listOfKeys.push(outputVar.name);
            listOfValues.push(outputVar.value);
            // outputVar.value;
           // this.mapOfVAPValues.push({value:outputVar.value, key:outputVar.name});
             
          }
          
          //take mpa of values, pass to apex with module name attached, then handle puhsing to API
          writeExistingVAP({moduleName: 'VACX', keyList: listOfKeys, valueList: listOfValues})
            .then((result) => {
            })
            .catch((error) => {
      
            });
        }
      }
}