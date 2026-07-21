import { createElement } from "lwc";
import PropertyList from "c/propertyList";
import getProperties from "@salesforce/apex/PropertyListController.getProperties";

jest.mock(
  "@salesforce/apex/PropertyListController.getProperties",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const SAMPLE_RECORDS = [
  {
    Id: "001000000000001",
    Name: "PROP-0001",
    Property_Name__c: "Sunset Villa",
    Status__c: "Available",
    Furnishing_Status__c: "Furnished",
    Rent__c: 1500,
    Type__c: "Residential",
    City__c: "Austin",
    State__c: "TX"
  }
];

async function flushPromises() {
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
}

describe("c-property-list", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("shows a spinner while the initial page is loading", () => {
    getProperties.mockResolvedValue({
      records: [],
      totalRecords: 0,
      pageNumber: 1,
      pageSize: 25
    });

    const element = createElement("c-property-list", { is: PropertyList });
    document.body.appendChild(element);

    expect(
      element.shadowRoot.querySelector("lightning-spinner")
    ).not.toBeNull();
  });

  it("renders returned records in the datatable once loaded", async () => {
    getProperties.mockResolvedValue({
      records: SAMPLE_RECORDS,
      totalRecords: 1,
      pageNumber: 1,
      pageSize: 25
    });

    const element = createElement("c-property-list", { is: PropertyList });
    document.body.appendChild(element);
    await flushPromises();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();
    expect(datatable.data).toEqual(SAMPLE_RECORDS);
    expect(element.shadowRoot.querySelector("lightning-spinner")).toBeNull();
  });

  it("shows an empty-state message when no records are returned", async () => {
    getProperties.mockResolvedValue({
      records: [],
      totalRecords: 0,
      pageNumber: 1,
      pageSize: 25
    });

    const element = createElement("c-property-list", { is: PropertyList });
    document.body.appendChild(element);
    await flushPromises();

    expect(element.shadowRoot.textContent).toContain(
      "No properties found matching your filters."
    );
    expect(element.shadowRoot.querySelector("lightning-datatable")).toBeNull();
  });

  it("disables Previous on the first page and requests page 2 when Next is clicked", async () => {
    getProperties.mockResolvedValue({
      records: SAMPLE_RECORDS,
      totalRecords: 30,
      pageNumber: 1,
      pageSize: 25
    });

    const element = createElement("c-property-list", { is: PropertyList });
    document.body.appendChild(element);
    await flushPromises();

    const [previousButton, nextButton] = element.shadowRoot.querySelectorAll(
      "lightning-button-icon"
    );
    expect(previousButton.disabled).toBe(true);
    expect(nextButton.disabled).toBe(false);

    nextButton.click();
    await flushPromises();

    expect(getProperties).toHaveBeenCalledTimes(2);
    expect(getProperties.mock.calls[1][0]).toMatchObject({ pageNumber: 2 });
  });

  it("resets to page 1 and passes the selected filters when Apply Filters is clicked", async () => {
    getProperties.mockResolvedValue({
      records: SAMPLE_RECORDS,
      totalRecords: 30,
      pageNumber: 1,
      pageSize: 25
    });

    const element = createElement("c-property-list", { is: PropertyList });
    document.body.appendChild(element);
    await flushPromises();

    const nextButton = element.shadowRoot.querySelectorAll(
      "lightning-button-icon"
    )[1];
    nextButton.click();
    await flushPromises();

    const [minRentInput] =
      element.shadowRoot.querySelectorAll("lightning-input");
    minRentInput.value = "1000";
    minRentInput.dispatchEvent(new CustomEvent("change"));

    const [statusCombobox] =
      element.shadowRoot.querySelectorAll("lightning-combobox");
    statusCombobox.dispatchEvent(
      new CustomEvent("change", { detail: { value: "Available" } })
    );

    const [applyButton] =
      element.shadowRoot.querySelectorAll("lightning-button");
    applyButton.click();
    await flushPromises();

    const lastCallArgs =
      getProperties.mock.calls[getProperties.mock.calls.length - 1][0];
    expect(lastCallArgs.pageNumber).toBe(1);
    expect(lastCallArgs.minRent).toBe(1000);
    expect(lastCallArgs.status).toBe("Available");
  });

  it("shows an error message and clears the loading state when the Apex call rejects", async () => {
    getProperties.mockRejectedValue({
      body: { message: "Insufficient access" }
    });

    const element = createElement("c-property-list", { is: PropertyList });
    document.body.appendChild(element);
    await flushPromises();

    expect(element.shadowRoot.querySelector("lightning-spinner")).toBeNull();
    expect(element.shadowRoot.textContent).toContain("Insufficient access");
  });
});
