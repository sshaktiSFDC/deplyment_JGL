import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import searchLoyaltyMemebers from "@salesforce/apex/JgLoyaltyController.searchLoyaltyMemebers";

import {
    IsConsoleNavigation,
    getFocusedTabInfo,
    setTabLabel
} from 'lightning/platformWorkspaceApi';

export default class LoyalitySearchMembers extends NavigationMixin(LightningElement) {
    @track loyaltyMembers;
    searchKey = '';

    connectedCallback() {
        console.error('connectedCallback');
        getFocusedTabInfo()
        .then(({ tabId }) => {
            setTabLabel(tabId, 'Loyalty Search');
        })
        .catch(error => {
            console.log(error);
        });
    }

    handleInputChange(event) {
        this.searchKey = event.target.value;
    }

    handleSearch() {

        searchLoyaltyMemebers({searchTerm: this.searchKey})
        .then(wrapper => {
            if (wrapper.result) {
                this.loyaltyMembers = wrapper.loyaltyMembers;
                console.log(JSON.stringify(this.loyaltyMembers ));
            } else {
                alert(wrapper.lastError);
            }
        })
        .catch(error => {
            alert(error);
        })        
    }

    openMemberRecord(event) {
        const memberNumber = event.target.dataset.id;
        alert(memberNumber);
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Loyalty_Member' // Ensure this matches your Lightning Page API name
            },
            state: {
                c__memberNumber: memberNumber // Prefix with 'c__' for custom parameters
            }
        });
    }
}