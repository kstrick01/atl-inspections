import { LightningElement, wire } from 'lwc';
import searchRestaurants from '@salesforce/apex/InspectionController.searchRestaurants';
import getInspections from '@salesforce/apex/InspectionController.getInspections';

const DEBOUNCE_MS = 300;

export default class RestaurantInspectionList extends LightningElement {
    searchTerm = '';
    postalCode = '';
    expandedId;
    history = [];
    historyError;
    delayTimeout;

    @wire(searchRestaurants, { searchTerm: '$searchTerm', postalCode: '$postalCode' })
    restaurants;

    get rows() {
        return (this.restaurants?.data ?? []).map((restaurant) => ({
            ...restaurant,
            isExpanded: restaurant.Id === this.expandedId,
            historyLabel: restaurant.Id === this.expandedId ? 'Hide history' : 'View history'
        }));
    }

    get isEmpty() {
        return Array.isArray(this.restaurants?.data) && this.restaurants.data.length === 0;
    }

    get errorMessage() {
        const error = this.restaurants?.error;
        if (!error) {
            return undefined;
        }
        return error.body?.message ?? 'Something went wrong loading restaurants.';
    }

    get hasHistory() {
        return this.history.length > 0;
    }

    // Debounce so we don't query on every keystroke
    handleSearchChange(event) {
        const value = event.target.value;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = window.setTimeout(() => {
            this.searchTerm = value;
        }, DEBOUNCE_MS);
    }

    handlePostalChange(event) {
        const value = event.target.value;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = window.setTimeout(() => {
            this.postalCode = value;
        }, DEBOUNCE_MS);
    }

    async handleToggleHistory(event) {
        const restaurantId = event.currentTarget.dataset.id;

        if (this.expandedId === restaurantId) {
            this.expandedId = undefined;
            return;
        }

        this.expandedId = restaurantId;
        this.history = [];
        this.historyError = undefined;
        try {
            this.history = await getInspections({ restaurantId });
        } catch (error) {
            this.historyError = error.body?.message ?? 'Could not load inspection history.';
        }
    }

    disconnectedCallback() {
        window.clearTimeout(this.delayTimeout);
    }
}
