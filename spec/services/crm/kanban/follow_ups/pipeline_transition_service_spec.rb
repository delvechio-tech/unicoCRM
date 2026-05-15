require 'rails_helper'

RSpec.describe Crm::Kanban::FollowUps::PipelineTransitionService do
  describe '#perform' do
    let(:account) { create(:account) }
    let(:first_pipeline) { account.crm_kanban_pipelines.create!(name: 'Primeiro funil') }
    let(:second_pipeline) { account.crm_kanban_pipelines.create!(name: 'Segundo funil') }
    let(:stage) { second_pipeline.stages.create!(account: account, name: 'Etapa', position: 0) }
    let(:card) do
      account.crm_kanban_cards.create!(
        pipeline: second_pipeline,
        stage: stage,
        title: 'Lead'
      )
    end
    let!(:schedule) do
      Crm::KanbanFollowUpSchedule.create!(
        account: account,
        pipeline: second_pipeline,
        card: card,
        source: 'cadence',
        scheduled_for: 1.day.from_now
      )
    end

    it 'cancels pending schedules when the card changes pipeline' do
      described_class.new(card: card, previous_pipeline_id: first_pipeline.id).perform

      expect(schedule.reload.status).to eq('canceled')
      expect(schedule.reason).to eq('pipeline_changed')
    end
  end
end
