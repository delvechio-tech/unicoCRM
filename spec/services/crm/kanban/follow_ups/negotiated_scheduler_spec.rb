require 'rails_helper'

RSpec.describe Crm::Kanban::FollowUps::NegotiatedScheduler do
  let(:account) { create(:account) }
  let(:pipeline) do
    account.crm_kanban_pipelines.create!(
      name: 'Comercial',
      settings: {
        'follow_up_settings' => {
          'business_hours_enabled' => true,
          'business_days' => %w[mon tue wed thu fri],
          'business_start' => '08:00',
          'business_end' => '18:00'
        }
      }
    )
  end
  let(:stage) { pipeline.stages.create!(account: account, name: 'Novos leads', position: 0) }
  let(:card) { account.crm_kanban_cards.create!(pipeline: pipeline, stage: stage, title: 'Lead') }

  it 'schedules a negotiated return and marks the intent state' do
    schedule = described_class.new(
      card: card,
      scheduled_for: Time.zone.parse('2026-05-16 07:30:00'),
      source: 'ai_negotiated',
      instruction: 'Retome de forma breve.'
    ).perform

    expect(schedule.source).to eq('ai_negotiated')
    expect(schedule.scheduled_for).to eq(Time.zone.parse('2026-05-18 08:00:00'))
    expect(card.reload.metadata.dig('follow_up_intent', 'state')).to eq('scheduled_return')
  end
end
