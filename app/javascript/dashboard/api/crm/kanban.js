/* global axios */
import ApiClient from '../ApiClient';

class CrmKanbanAPI extends ApiClient {
  constructor() {
    super('crm/kanban', { accountScoped: true });
  }

  updatePipeline(data) {
    return axios.patch(this.url, data);
  }

  createCard(data) {
    return axios.post(`${this.url}/cards`, data);
  }

  updateCard(id, data) {
    return axios.patch(`${this.url}/cards/${id}`, data);
  }

  deleteCard(id) {
    return axios.delete(`${this.url}/cards/${id}`);
  }

  updateStage(id, data) {
    return axios.patch(`${this.url}/stages/${id}`, data);
  }

  createActivity(cardId, data) {
    return axios.post(`${this.url}/cards/${cardId}/activities`, data);
  }

  updateActivity(cardId, activityId, data) {
    return axios.patch(`${this.url}/cards/${cardId}/activities/${activityId}`, data);
  }

  completeActivity(cardId, activityId) {
    return axios.post(`${this.url}/cards/${cardId}/activities/${activityId}/complete`);
  }

  createWebhook(data) {
    return axios.post(`${this.url}/webhooks`, data);
  }

  updateWebhook(id, data) {
    return axios.patch(`${this.url}/webhooks/${id}`, data);
  }

  deleteWebhook(id) {
    return axios.delete(`${this.url}/webhooks/${id}`);
  }
}

export default new CrmKanbanAPI();
