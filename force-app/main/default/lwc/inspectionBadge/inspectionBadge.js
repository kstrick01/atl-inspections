import { LightningElement, api } from 'lwc';

export default class InspectionBadge extends LightningElement {
    @api grade;
    @api score;
    @api inspectionDate; // ISO date string, e.g. "2026-10-14"

    get hasInspection() {
        return Boolean(this.grade);
    }

    get badgeClass() {
        return `badge badge-${(this.grade || 'none').toLowerCase()}`;
    }

    // Flag old scores so users aren't misled by an out-of-date grade
    get isStale() {
        if (!this.inspectionDate) {
            return false;
        }
        const inspected = new Date(`${this.inspectionDate}T00:00:00Z`);
        const cutoff = new Date();
        cutoff.setUTCFullYear(cutoff.getUTCFullYear() - 1);
        return inspected < cutoff;
    }
}
