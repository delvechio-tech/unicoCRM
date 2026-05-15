require 'rails_helper'

RSpec.describe Crm::KanbanFollowUpDispatchJob do
  let(:account) { create(:account) }
  let(:pipeline) { account.crm_kanban_pipelines.create!(name: 'Comercial') }
  let(:stage) { pipeline.stages.create!(account: account, name: 'Novos leads', position: 0) }
  let(:card) { account.crm_kanban_cards.create!(pipeline: pipeline, stage: stage, title: 'Lead') }

  it 'enqueues generation for due schedules without content and execution for ready schedules' do
    ready_schedule = card.follow_up_schedules.create!(
      account: account,
      pipeline: pipeline,
      source: 'cadence',
      scheduled_for: 1.minute.ago,
      generated_message: 'Oi'
    )
    pending_schedule = card.follow_up_schedules.create!(
      account: account,
      pipeline: pipeline,
      source: 'cadence',
      scheduled_for: 1.minute.ago
    )
    card.follow_up_schedules.create!(
      account: account,
      pipeline: pipeline,
      source: 'cadence',
      scheduled_for: 1.hour.from_now,
      generated_message: 'Depois'
    )

    expect do
      described_class.perform_now
    end.to have_enqueued_job(Crm::KanbanFollowUpExecutionJob).with(ready_schedule.id).once
      .and have_enqueued_job(Crm::KanbanFollowUpGenerationJob).with(pending_schedule.id).once
  end

  it 'does not execute a generated message that is still pending review' do
    pipeline.update!(
      settings: {
        'follow_up_settings' => {
          'delivery_mode' => 'review_before_send'
        }
      }
    )
    card.follow_up_schedules.create!(
      account: account,
      pipeline: pipeline,
      source: 'cadence',
      scheduled_for: 1.minute.ago,
      generated_message: 'Oi',
      metadata: { 'review_state' => 'pending_review' }
    )

    expect do
      described_class.perform_now
    end.not_to have_enqueued_job(Crm::KanbanFollowUpExecutionJob)
  end
end
