public with sharing class VisitMapController {
    
    @AuraEnabled(cacheable=true)
    public static List<Visit> getVisits() {
        return [
            SELECT Id, 
                Name,
                Status,
                PlannedVisitStartTime,
                ActualVisitStartTime,
                PlaceId,
                Place.Name,    
                cgcloud__Geolocation__Latitude__s,
                cgcloud__Geolocation__Longitude__s
            FROM Visit
            WHERE cgcloud__Geolocation__Latitude__s != null
            AND cgcloud__Geolocation__Longitude__s != null
            AND Status IN ('Planned', 'In Progress', 'Completed')
            LIMIT 10
        ];
    }
    
    @AuraEnabled
    public static Visit checkIn(Id visitId, Decimal latitude, Decimal longitude) {
        Visit v = [SELECT Id FROM Visit WHERE Id = :visitId];
        v.ActualVisitStartTime = DateTime.now();
        v.Status = 'In Progress';
        v.CheckInLatitude__c = latitude;
        v.CheckInLongitude__c = longitude;
        update v;
        return v;
    }
}