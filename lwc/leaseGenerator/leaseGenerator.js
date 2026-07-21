import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import GenerateLeaseModal from "c/generateLeaseModal";

export default class LeaseGenerator extends LightningElement {
  @api recordId;

  async handleGenerateLease() {
    const result = await GenerateLeaseModal.open({
      size: "small",
      description: "Generate a new lease agreement for this tenant",
      tenantContactId: this.recordId
    });

    if (result === "success") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Lease Agreement Created",
          message: "The lease agreement was generated successfully.",
          variant: "success"
        })
      );
    }
  }
}
