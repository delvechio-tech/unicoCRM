require 'rails_helper'

RSpec.describe Crm::Kanban::FollowUps::CancellationService do
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
  let!(:schedule) do
    card.follow_up_schedules.create!(
      account: account,
      pipeline: pipeline,
      contact: contact,
      conversation: conversation,
      source: 'cadence',
      scheduled_for: 2.hours.from_now
    )
  end
  let(:message) do
    create(
      :message,
      account: account,
      inbox: inbox,
      conversation: conversation,
      message_type: 'incoming',
      content: 'Voltei'
    )
  end

  it 'cancels pending follow-ups when the customer replies' do
    described_class.new(card: card, message: message).perform

    expect(schedule.reload.status).to eq('canceled')
    expect(schedule.reason).to eq('customer_replied')
    expect(schedule.events.pluck(:event_type)).to eq(['canceled'])
  end
end
