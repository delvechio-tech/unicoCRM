require 'rails_helper'

RSpec.describe Crm::Kanban::FollowUps::ManualScheduler do
  let(:account) { create(:account) }
  let(:pipeline) { account.crm_kanban_pipelines.create!(name: 'Comercial') }
  let(:stage) { pipeline.stages.create!(account: account, name: 'Novos leads', position: 0) }
  let(:card) { account.crm_kanban_cards.create!(pipeline: pipeline, stage: stage, title: 'Lead') }
  let!(:existing_schedule) do
    Crm::KanbanFollowUpSchedule.create!(
      account: account,
      pipeline: pipeline,
      card: card,
      source: 'cadence',
      scheduled_for: 1.day.from_now
    )
  end

  it 'replaces pending schedules with a manual override' do
    schedule = described_class.new(
      card: card,
      scheduled_for: 2.days.from_now,
      instruction: 'Retomar proposta.'
    ).perform

    expect(existing_schedule.reload.status).to eq('canceled')
    expect(schedule.source).to eq('manual_override')
    expect(schedule.message_instruction).to eq('Retomar proposta.')
    expect(card.reload.metadata.dig('follow_up_override', 'mode')).to eq('manual')
  end
end
