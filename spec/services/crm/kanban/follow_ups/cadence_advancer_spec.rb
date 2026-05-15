require 'rails_helper'

RSpec.describe Crm::Kanban::FollowUps::CadenceAdvancer do
  let(:account) { create(:account) }
  let(:pipeline) do
    account.crm_kanban_pipelines.create!(
      name: 'Comercial',
      settings: {
        'follow_up_settings' => {
          'max_attempts' => 2,
          'cadence' => [
            { 'id' => 'step-1', 'delay_value' => 2, 'delay_unit' => 'hour' },
            { 'id' => 'step-2', 'delay_value' => 1, 'delay_unit' => 'day' }
          ]
        }
      }
    )
  end
  let(:stage) { pipeline.stages.create!(account: account, name: 'Novos leads', position: 0) }
  let(:card) { account.crm_kanban_cards.create!(pipeline: pipeline, stage: stage, title: 'Lead') }

  it 'creates the next cadence step after a sent follow-up' do
    schedule = card.follow_up_schedules.create!(
      account: account,
      pipeline: pipeline,
      source: 'cadence',
      status: 'sent',
      scheduled_for: 1.minute.ago,
      attempt_number: 1,
      cadence_step: 1
    )

    travel_to Time.zone.parse('2026-05-15 10:00:00') do
      next_schedule = described_class.new(schedule: schedule).perform

      expect(next_schedule.attempt_number).to eq(2)
      expect(next_schedule.cadence_step).to eq(2)
      expect(next_schedule.scheduled_for).to eq(Time.zone.parse('2026-05-16 10:00:00'))
    end
  end

  it 'records exhaustion when no next step or long-term return is configured' do
    schedule = card.follow_up_schedules.create!(
      account: account,
      pipeline: pipeline,
      source: 'cadence',
      status: 'sent',
      scheduled_for: 1.minute.ago,
      attempt_number: 2,
      cadence_step: 2
    )

    described_class.new(schedule: schedule).perform

    expect(schedule.events.pluck(:event_type)).to include('cadence_exhausted')
  end

  it 'falls back to long-term return when the cadence is exhausted and configured' do
    pipeline.update!(
      settings: pipeline.settings.deep_merge(
        'follow_up_settings' => {
          'long_term_enabled' => true,
          'long_term_delay_value' => 3,
          'long_term_delay_unit' => 'month'
        }
      )
    )
    schedule = card.follow_up_schedules.create!(
      account: account,
      pipeline: pipeline,
      source: 'cadence',
      status: 'sent',
      scheduled_for: 1.minute.ago,
      attempt_number: 2,
      cadence_step: 2
    )

    travel_to Time.zone.parse('2026-05-15 10:00:00') do
      next_schedule = described_class.new(schedule: schedule).perform

      expect(next_schedule.source).to eq('long_term_reactivation')
      expect(next_schedule.scheduled_for).to eq(Time.zone.parse('2026-08-15 10:00:00'))
    end
  end
end
