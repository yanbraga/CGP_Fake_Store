import { LightningElement, wire } from 'lwc';
import getVisits from '@salesforce/apex/VisitMapController.getVisits';

export default class VisitMap extends LightningElement {
    mapMarkers = [];

    @wire(getVisits)
    wired({ data, error }) {
        if (data) {
            this.mapMarkers = data
                .filter(v => {
                    return v.cgcloud__Geolocation__Latitude__s != null && 
                           v.cgcloud__Geolocation__Longitude__s != null &&
                           v.cgcloud__Geolocation__Latitude__s !== 0 &&
                           v.cgcloud__Geolocation__Longitude__s !== 0;
                })
                .map(v => ({
                    location: {
                        Latitude: v.cgcloud__Geolocation__Latitude__s,
                        Longitude: v.cgcloud__Geolocation__Longitude__s
                    },
                    title: v.Place?.Name || v.Name,          
                    description: `Visita: ${v.Name} | Status: ${v.Status}`,
                    icon: v.ActualVisitStartTime ? 'standard:record' : 'standard:location'
                }));
        }
        
        if (error) {
            console.error('Erro:', error);
        }
    }
}