require 'rails_helper'

RSpec.describe Crm::Kanban::FollowUps::LongTermScheduler do
  let(:account) { create(:account) }
  let(:pipeline) do
    account.crm_kanban_pipelines.create!(
      name: 'Comercial',
      settings: {
        'follow_up_settings' => {
          'instruction' => 'Retorno longo com contexto.',
          'long_term_enabled' => true,
          'long_term_delay_value' => 3,
          'long_term_delay_unit' => 'month'
        }
      }
    )
  end
  let(:stage) { pipeline.stages.create!(account: account, name: 'Novos leads', position: 0) }
  let(:card) { account.crm_kanban_cards.create!(pipeline: pipeline, stage: stage, title: 'Lead') }

  it 'creates a long term return from pipeline settings' do
    travel_to Time.zone.parse('2026-05-15 10:00:00') do
      schedule = described_class.new(card: card).perform

      expect(schedule.source).to eq('long_term_reactivation')
      expect(schedule.reason).to eq('long_term_return')
      expect(schedule.scheduled_for).to eq(Time.zone.parse('2026-08-15 10:00:00'))
      expect(card.reload.metadata.dig('follow_up_intent', 'state')).to eq('long_term_scheduled')
    end
  end

  it 'does not replace a paused override' do
    card.update!(metadata: { 'follow_up_override' => { 'mode' => 'paused' } })

    expect(described_class.new(card: card).perform).to be_nil
  end
end
