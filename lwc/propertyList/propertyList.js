import { LightningElement } from "lwc";
import getProperties from "@salesforce/apex/PropertyListController.getProperties";
import PropertyCreateModal from "c/propertyCreateModal";

const PAGE_SIZE = 25;

const COLUMNS = [
  {
    label: "Property",
    fieldName: "recordUrl",
    type: "url",
    typeAttributes: { label: { fieldName: "Name" }, target: "_self" }
  },
  { label: "Property Name", fieldName: "Property_Name__c", type: "text" },
  { label: "City", fieldName: "City__c", type: "text" },
  { label: "State", fieldName: "State__c", type: "text" },
  { label: "Type", fieldName: "Type__c", type: "text" },
  {
    label: "Furnishing Status",
    fieldName: "Furnishing_Status__c",
    type: "text"
  },
  { label: "Status", fieldName: "Status__c", type: "text" },
  { label: "Rent", fieldName: "Rent__c", type: "currency" }
];

const STATUS_OPTIONS = [
  { label: "All Statuses", value: "" },
  { label: "Available", value: "Available" },
  { label: "Occupied", value: "Occupied" }
];

const FURNISHING_OPTIONS = [
  { label: "All Furnishing Types", value: "" },
  { label: "Furnished", value: "Furnished" },
  { label: "Semi-Furnished", value: "Semi-Furnished" },
  { label: "Unfurnished", value: "Unfurnished" }
];

export default class PropertyList extends LightningElement {
  columns = COLUMNS;
  statusOptions = STATUS_OPTIONS;
  furnishingOptions = FURNISHING_OPTIONS;

  pageNumber = 1;
  pageSize = PAGE_SIZE;

  minRent = "";
  maxRent = "";
  status = "";
  furnishingStatus = "";

  records = [];
  totalRecords = 0;
  isLoading = false;
  errorMessage = "";

  connectedCallback() {
    this.loadProperties();
  }

  async handleNewProperty() {
    console.log("handleNewProperty clicked");
    try {
      const result = await PropertyCreateModal.open({
        size: "small",
        description: "Create a new property"
      });
      console.log("PropertyCreateModal closed with result:", result);
      if (result === "success") {
        this.pageNumber = 1;
        this.loadProperties();
      }
    } catch (error) {
      console.error("Error opening PropertyCreateModal:", error);
    }
  }

  loadProperties() {
    this.isLoading = true;
    this.errorMessage = "";

    getProperties({
      pageNumber: this.pageNumber,
      pageSize: this.pageSize,
      minRent: this.toNumberOrNull(this.minRent),
      maxRent: this.toNumberOrNull(this.maxRent),
      status: this.status || null,
      furnishingStatus: this.furnishingStatus || null
    })
      .then((result) => {
        this.records = result.records.map((record) => ({
          ...record,
          recordUrl: `/${record.Id}`
        }));
        this.totalRecords = result.totalRecords;
      })
      .catch((error) => {
        this.records = [];
        this.totalRecords = 0;
        this.errorMessage = this.extractErrorMessage(error);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  handleMinRentChange(event) {
    this.minRent = event.target.value;
  }

  handleMaxRentChange(event) {
    this.maxRent = event.target.value;
  }

  handleStatusChange(event) {
    this.status = event.detail.value;
  }

  handleFurnishingStatusChange(event) {
    this.furnishingStatus = event.detail.value;
  }

  handleApplyFilters() {
    this.pageNumber = 1;
    this.loadProperties();
  }

  handleResetFilters() {
    this.minRent = "";
    this.maxRent = "";
    this.status = "";
    this.furnishingStatus = "";
    this.pageNumber = 1;
    this.loadProperties();
  }

  handlePrevious() {
    if (this.isFirstPage) {
      return;
    }
    this.pageNumber -= 1;
    this.loadProperties();
  }

  handleNext() {
    if (this.isLastPage) {
      return;
    }
    this.pageNumber += 1;
    this.loadProperties();
  }

  toNumberOrNull(value) {
    return value === "" || value === null || value === undefined
      ? null
      : Number(value);
  }

  extractErrorMessage(error) {
    if (error && error.body && error.body.message) {
      return error.body.message;
    }
    if (error && error.message) {
      return error.message;
    }
    return "An unknown error occurred while loading properties.";
  }

  get totalPages() {
    return this.totalRecords === 0
      ? 1
      : Math.ceil(this.totalRecords / this.pageSize);
  }

  get isFirstPage() {
    return this.pageNumber <= 1;
  }

  get isLastPage() {
    return this.pageNumber >= this.totalPages;
  }

  get hasRecords() {
    return !this.isLoading && !this.errorMessage && this.records.length > 0;
  }

  get isEmpty() {
    return !this.isLoading && !this.errorMessage && this.records.length === 0;
  }

  get paginationSummary() {
    const unit = this.totalRecords === 1 ? "property" : "properties";
    return `Page ${this.pageNumber} of ${this.totalPages} (${this.totalRecords} ${unit})`;
  }
}
