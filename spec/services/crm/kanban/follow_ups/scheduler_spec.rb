require 'rails_helper'

RSpec.describe Crm::Kanban::FollowUps::Scheduler do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:pipeline) do
    account.crm_kanban_pipelines.create!(
      name: 'Comercial',
      settings: {
        'follow_up_settings' => {
          'enabled' => true,
          'instruction' => 'Seja breve.',
          'trigger' => 'last_ai_message_without_customer_reply',
          'cadence' => [
            {
              'id' => 'step-1',
              'delay_value' => 2,
              'delay_unit' => 'hour'
            }
          ]
        }
      }
    )
  end
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
  let(:message) do
    create(
      :message,
      account: account,
      inbox: inbox,
      conversation: conversation,
      message_type: 'outgoing',
      content: 'Posso ajudar?'
    )
  end

  it 'creates a scheduled follow-up from the first cadence step' do
    travel_to Time.zone.parse('2026-05-15 10:00:00') do
      schedule = described_class.new(card: card, message: message).perform

      expect(schedule).to be_persisted
      expect(schedule.source).to eq('cadence')
      expect(schedule.status).to eq('scheduled')
      expect(schedule.scheduled_for).to eq(Time.zone.parse('2026-05-15 12:00:00'))
      expect(schedule.events.pluck(:event_type)).to eq(['scheduled'])
    end
  end

  it 'cancels the previous pending follow-up when a new outgoing message arrives' do
    first_schedule = described_class.new(card: card, message: message).perform
    next_message = create(
      :message,
      account: account,
      inbox: inbox,
      conversation: conversation,
      message_type: 'outgoing',
      content: 'Ainda posso ajudar?'
    )

    described_class.new(card: card, message: next_message).perform

    expect(first_schedule.reload.status).to eq('canceled')
    expect(first_schedule.reason).to eq('superseded_by_new_outgoing_message')
  end

  it 'does not schedule a follow-up when automation is paused for the card' do
    card.update!(metadata: { 'follow_up_override' => { 'mode' => 'paused' } })

    expect(described_class.new(card: card, message: message).perform).to be_nil
    expect(card.follow_up_schedules).to be_empty
  end

  it 'does not replace a manual follow-up override' do
    card.update!(metadata: { 'follow_up_override' => { 'mode' => 'manual' } })

    expect(described_class.new(card: card, message: message).perform).to be_nil
    expect(card.follow_up_schedules).to be_empty
  end

  it 'uses the channel override for the first schedule when configured' do
    pipeline.update!(
      settings: pipeline.settings.deep_merge(
        'follow_up_settings' => {
          'channel_overrides' => [
            {
              'id' => 'instagram-override',
              'channel' => 'instagram',
              'delay_value' => 23,
              'delay_unit' => 'hour'
            }
          ]
        }
      )
    )
    allow(inbox).to receive(:channel_type).and_return('Channel::Instagram')

    travel_to Time.zone.parse('2026-05-15 10:00:00') do
      schedule = described_class.new(card: card, message: message).perform

      expect(schedule.scheduled_for).to eq(Time.zone.parse('2026-05-16 09:00:00'))
    end
  end

  it 'moves the schedule into the next business window' do
    pipeline.update!(
      settings: pipeline.settings.deep_merge(
        'follow_up_settings' => {
          'business_hours_enabled' => true,
          'business_days' => %w[mon tue wed thu fri],
          'business_start' => '08:00',
          'business_end' => '18:00'
        }
      )
    )

    travel_to Time.zone.parse('2026-05-15 17:30:00') do
      schedule = described_class.new(card: card, message: message).perform

      expect(schedule.scheduled_for).to eq(Time.zone.parse('2026-05-18 08:00:00'))
    end
  end
end
