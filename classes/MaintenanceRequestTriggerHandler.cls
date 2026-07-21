public with sharing class MaintenanceRequestTriggerHandler {
  private static final List<String> ACTIVE_STATUSES = new List<String>{
    'Open',
    'In Progress'
  };

  public static void assignVendors(List<Maintenance_Request__c> newRequests) {
    List<Maintenance_Request__c> unassignedRequests = new List<Maintenance_Request__c>();
    for (Maintenance_Request__c request : newRequests) {
      if (request.Vendor_Contact__c == null) {
        unassignedRequests.add(request);
      }
    }
    if (unassignedRequests.isEmpty()) {
      return;
    }

    List<Contact> vendors = [
      SELECT Id
      FROM Contact
      WHERE RecordType.DeveloperName = 'Vendor'
    ];
    if (vendors.isEmpty()) {
      return;
    }

    Map<Id, Integer> workloadByVendorId = new Map<Id, Integer>();
    for (Contact vendor : vendors) {
      workloadByVendorId.put(vendor.Id, 0);
    }

    List<AggregateResult> workloadResults = [
      SELECT Vendor_Contact__c vendorId, COUNT(Id) requestCount
      FROM Maintenance_Request__c
      WHERE Vendor_Contact__c != NULL AND Status__c IN :ACTIVE_STATUSES
      GROUP BY Vendor_Contact__c
    ];
    for (AggregateResult result : workloadResults) {
      Id vendorId = (Id) result.get('vendorId');
      if (workloadByVendorId.containsKey(vendorId)) {
        workloadByVendorId.put(vendorId, (Integer) result.get('requestCount'));
      }
    }

    for (Maintenance_Request__c request : unassignedRequests) {
      Id leastLoadedVendorId = findLeastLoadedVendorId(workloadByVendorId);
      request.Vendor_Contact__c = leastLoadedVendorId;
      workloadByVendorId.put(
        leastLoadedVendorId,
        workloadByVendorId.get(leastLoadedVendorId) + 1
      );
    }
  }

  private static Id findLeastLoadedVendorId(Map<Id, Integer> workloadByVendorId) {
    Id leastLoadedVendorId;
    Integer lowestWorkload;
    for (Id vendorId : workloadByVendorId.keySet()) {
      Integer workload = workloadByVendorId.get(vendorId);
      if (lowestWorkload == null || workload < lowestWorkload) {
        lowestWorkload = workload;
        leastLoadedVendorId = vendorId;
      }
    }
    return leastLoadedVendorId;
  }
}
