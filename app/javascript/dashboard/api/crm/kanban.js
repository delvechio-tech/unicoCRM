/* global axios */
import ApiClient from '../ApiClient';

class CrmKanbanAPI extends ApiClient {
  constructor() {
    super('crm/kanban', { accountScoped: true });
  }

  getBoard(params = {}) {
    return axios.get(this.url, { params });
  }

  createPipeline(data) {
    return axios.post(`${this.url}/pipelines`, data);
  }

  updatePipeline(id, data) {
    if (data) return axios.patch(`${this.url}/pipelines/${id}`, data);

    return axios.patch(this.url, id);
  }

  deletePipeline(id) {
    return axios.delete(`${this.url}/pipelines/${id}`);
  }

  createCard(data) {
    return axios.post(`${this.url}/cards`, data);
  }

  updateCard(id, data) {
    return axios.patch(`${this.url}/cards/${id}`, data);
  }

  deleteCard(id, params = {}) {
    return axios.delete(`${this.url}/cards/${id}`, { params });
  }

  summarizeCard(id, params = {}) {
    return axios.post(`${this.url}/cards/${id}/summarize`, null, { params });
  }

  createFollowUp(cardId, data) {
    return axios.post(`${this.url}/cards/${cardId}/follow_ups`, data);
  }

  updateFollowUp(cardId, followUpId, data) {
    return axios.patch(`${this.url}/cards/${cardId}/follow_ups/${followUpId}`, data);
  }

  cancelFollowUp(cardId, followUpId, params = {}) {
    return axios.delete(`${this.url}/cards/${cardId}/follow_ups/${followUpId}`, { params });
  }

  updateStage(id, data) {
    return axios.patch(`${this.url}/stages/${id}`, data);
  }

  createStage(data) {
    return axios.post(`${this.url}/stages`, data);
  }

  deleteStage(id, params = {}) {
    return axios.delete(`${this.url}/stages/${id}`, { params });
  }

  createActivity(cardId, data) {
    return axios.post(`${this.url}/cards/${cardId}/activities`, data);
  }

  updateActivity(cardId, activityId, data) {
    return axios.patch(`${this.url}/cards/${cardId}/activities/${activityId}`, data);
  }

  completeActivity(cardId, activityId, params = {}) {
    return axios.post(
      `${this.url}/cards/${cardId}/activities/${activityId}/complete`,
      null,
      { params }
    );
  }

  createWebhook(data) {
    return axios.post(`${this.url}/webhooks`, data);
  }

  updateWebhook(id, data) {
    return axios.patch(`${this.url}/webhooks/${id}`, data);
  }

  deleteWebhook(id, params = {}) {
    return axios.delete(`${this.url}/webhooks/${id}`, { params });
  }
}

export default new CrmKanbanAPI();
