import { api } from "lwc";
import LightningModal from "lightning/modal";
import createLease from "@salesforce/apex/LeaseAgreementController.createLease";

export default class GenerateLeaseModal extends LightningModal {
  @api tenantContactId;

  propertyFilter = {
    criteria: [
      { fieldPath: "Has_Active_Lease__c", operator: "eq", value: false }
    ]
  };

  propertyId = "";
  terms = "";
  agreedMonthlyRent = "";
  startDate = "";
  endDate = "";
  isSaving = false;
  errorMessage = "";

  handlePropertyChange(event) {
    this.propertyId = event.detail.recordId;
  }

  handleTermsChange(event) {
    this.terms = event.target.value;
  }

  handleRentChange(event) {
    this.agreedMonthlyRent = event.target.value;
  }

  handleStartDateChange(event) {
    this.startDate = event.target.value;
  }

  handleEndDateChange(event) {
    this.endDate = event.target.value;
  }

  handleCancel() {
    this.close();
  }

  get isSaveDisabled() {
    return (
      this.isSaving || !this.propertyId || !this.startDate || !this.endDate
    );
  }

  handleGenerate() {
    this.errorMessage = "";
    if (!this.propertyId || !this.startDate || !this.endDate) {
      this.errorMessage = "Property, Start Date, and End Date are required.";
      return;
    }

    this.isSaving = true;
    createLease({
      tenantContactId: this.tenantContactId,
      propertyId: this.propertyId,
      terms: this.terms || null,
      agreedMonthlyRent:
        this.agreedMonthlyRent === "" ? null : Number(this.agreedMonthlyRent),
      startDate: this.startDate,
      endDate: this.endDate
    })
      .then(() => {
        this.close("success");
      })
      .catch((error) => {
        this.errorMessage = this.extractErrorMessage(error);
      })
      .finally(() => {
        this.isSaving = false;
      });
  }

  extractErrorMessage(error) {
    if (error && error.body && error.body.message) {
      return error.body.message;
    }
    if (error && error.message) {
      return error.message;
    }
    return "An unknown error occurred while generating the lease.";
  }
}
