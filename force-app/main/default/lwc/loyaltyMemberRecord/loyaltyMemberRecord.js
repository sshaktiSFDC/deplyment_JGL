import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getLoyaltyMemeber from '@salesforce/apex/JgLoyaltyController.getLoyaltyMemeber';
import { CurrentPageReference } from 'lightning/navigation';

import {
    IsConsoleNavigation,
    getFocusedTabInfo,
    setTabLabel
} from 'lightning/platformWorkspaceApi';

export default class LoyaltyMemberRecord extends NavigationMixin(LightningElement) {
    memberNumber;

    @wire(IsConsoleNavigation) isConsoleNavigation;

    @wire(CurrentPageReference)
    getPageReference(currentPageReference) {
        if (currentPageReference) {
            this.memberNumber = currentPageReference.state.c__memberNumber;
        }
    }

    connectedCallback() {
        console.error('connectedCallback');
        getFocusedTabInfo()
        .then(({ tabId }) => {
            setTabLabel(tabId, 'Member Record');
        })
        .catch(error => {
            console.log(error);
        });
        alert('connectedCallback ' + this.memberNumber);
    }

    renderedCallback() {
        getLoyaltyMemeber({memberNumber: this.memberNumber})
        .then(wrapper => {
            if (wrapper.result) {
                this.loyaltyMember = wrapper.loyaltyMember;
                console.log(JSON.stringify(this.loyaltyMember));
            } else {
                alert(wrapper.lastError);
            }
        })
        .catch(error => {
            alert(error);
        })
    }

}