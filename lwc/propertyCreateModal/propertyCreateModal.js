import LightningModal from "lightning/modal";

export default class PropertyCreateModal extends LightningModal {
  handleStatusChange(event) {
    if (event.detail.status === "FINISHED") {
      this.close("success");
    }
  }
}
