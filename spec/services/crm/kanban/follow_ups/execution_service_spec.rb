require 'rails_helper'

RSpec.describe Crm::Kanban::FollowUps::ExecutionService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:pipeline) { account.crm_kanban_pipelines.create!(name: 'Comercial') }
  let(:stage) { pipeline.stages.create!(account: account, name: 'Novos leads', position: 0) }
  let(:card) do
    account.crm_kanban_cards.create!(
      pipeline: pipeline,
      stage: stage,
      contact: contact,
      conversation: conversation,
      title: 'Lead'
    )
  end
  let(:schedule) do
    card.follow_up_schedules.create!(
      account: account,
      pipeline: pipeline,
      conversation: conversation,
      source: 'cadence',
      scheduled_for: 1.minute.ago,
      generated_message: 'Podemos continuar nossa conversa?'
    )
  end

  before do
    allow(SendReplyJob).to receive(:perform_later)
  end

  it 'creates and dispatches an outgoing message for a ready schedule' do
    message = described_class.new(schedule: schedule).perform

    expect(message).to be_outgoing
    expect(message.content).to eq('Podemos continuar nossa conversa?')
    expect(schedule.reload.status).to eq('sent')
    expect(schedule.events.pluck(:event_type)).to eq(%w[processing sent cadence_exhausted])
    expect(SendReplyJob).to have_received(:perform_later).with(message.id).once
  end

  it 'advances the cadence after sending a cadence follow-up' do
    pipeline.update!(
      settings: {
        'follow_up_settings' => {
          'max_attempts' => 2,
          'cadence' => [
            { 'id' => 'step-1', 'delay_value' => 1, 'delay_unit' => 'hour' },
            { 'id' => 'step-2', 'delay_value' => 1, 'delay_unit' => 'day' }
          ]
        }
      }
    )
    schedule.update!(attempt_number: 1, cadence_step: 1)

    travel_to Time.zone.parse('2026-05-15 10:00:00') do
      described_class.new(schedule: schedule).perform
    end

    expect(card.follow_up_schedules.scheduled.last.attempt_number).to eq(2)
  end

  it 'does not send when the customer replied after scheduling' do
    schedule
    create(
      :message,
      account: account,
      inbox: inbox,
      conversation: conversation,
      message_type: 'incoming',
      content: 'Voltei.'
    )

    expect(described_class.new(schedule: schedule).perform).to be_nil
    expect(schedule.reload.status).to eq('scheduled')
  end

  it 'does not send when the card is opted out' do
    card.update!(metadata: { 'follow_up_intent' => { 'state' => 'opted_out' } })

    expect(described_class.new(schedule: schedule).perform).to be_nil
    expect(schedule.reload.status).to eq('scheduled')
  end
end
