require 'rails_helper'

RSpec.describe Crm::Kanban::FollowUps::IncomingIntentProcessor do
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

  it 'disqualifies the card and cancels schedules on explicit opt-out' do
    schedule = card.follow_up_schedules.create!(
      account: account,
      pipeline: pipeline,
      source: 'cadence',
      scheduled_for: 1.day.from_now
    )
    message = create(
      :message,
      account: account,
      inbox: inbox,
      conversation: conversation,
      message_type: 'incoming',
      content: 'Nao quero mais contato.'
    )

    described_class.new(card: card, message: message).perform

    expect(card.reload.status).to eq('lost')
    expect(card.lost_reason).to eq('explicit_opt_out')
    expect(card.metadata.dig('follow_up_intent', 'state')).to eq('opted_out')
    expect(schedule.reload.status).to eq('canceled')
  end

  it 'marks a soft negative as waiting for reschedule preference' do
    message = create(
      :message,
      account: account,
      inbox: inbox,
      conversation: conversation,
      message_type: 'incoming',
      content: 'Nao posso agora.'
    )

    described_class.new(card: card, message: message).perform

    expect(card.reload.metadata.dig('follow_up_intent', 'state')).to eq('awaiting_reschedule_preference')
    expect(card.status).to eq('open')
  end
end
