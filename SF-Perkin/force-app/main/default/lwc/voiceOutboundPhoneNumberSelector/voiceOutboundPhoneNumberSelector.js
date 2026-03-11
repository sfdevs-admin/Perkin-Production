import { LightningElement, api } from 'lwc';
import getPhone from '@salesforce/apex/VoiceOutboundPhoneNumber.getPhone';
import getPhoneOptions from '@salesforce/apex/VoiceOutboundPhoneNumber.getPhoneOptions';
import updatePhone from '@salesforce/apex/VoiceOutboundPhoneNumber.updatePhone';

export default class VoiceOutboundPhoneNumberSelector extends LightningElement {
    @api value;
    options = [];
    saving = false;
    connectedCallback() {
        getPhone()
            .then(data => {
                console.log('VoiceOutboundPhoneNumberSelector getPhone', data);
                this.value = data;
            })
            .catch(error => {
                console.error('VoiceOutboundPhoneNumberSelector getPhone', error);
            })
          
            getPhoneOptions()
            .then(data => {
                this.options = Object.keys(data).map(key => ({ label: data[key], value: key }));
            })
            .catch(error => {
                console.error('VoiceOutboundPhoneNumberSelector getPhoneOptions', error);
            });

        }
    handleChange(event) {
        this.saving = true;
        this.value = event.detail.value;
        updatePhone({ phone: this.value })
            .then(data => {
                console.log('VoiceOutboundPhoneNumberSelector handleChange', data);
                this.saving = false;
            })
            .catch(error => {
                console.error('VoiceOutboundPhoneNumberSelector handleChange', error);
                this.saving = false;
            })
    }
}