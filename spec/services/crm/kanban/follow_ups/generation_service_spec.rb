require 'rails_helper'

RSpec.describe Crm::Kanban::FollowUps::GenerationService do
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
      message_instruction: 'Seja breve.'
    )
  end

  it 'stores the generated message and records the event' do
    service = instance_double(Captain::KanbanFollowUpMessageService, perform: { message: 'Podemos continuar?' })
    allow(Captain::KanbanFollowUpMessageService).to receive(:new).and_return(service)

    expect(described_class.new(schedule: schedule).perform).to eq('Podemos continuar?')
    expect(schedule.reload.generated_message).to eq('Podemos continuar?')
    expect(schedule.events.pluck(:event_type)).to eq(['generated'])
  end

  it 'marks generated content as pending review when the pipeline requires approval' do
    pipeline.update!(
      settings: {
        'follow_up_settings' => {
          'delivery_mode' => 'review_before_send'
        }
      }
    )
    service = instance_double(Captain::KanbanFollowUpMessageService, perform: { message: 'Podemos continuar?' })
    allow(Captain::KanbanFollowUpMessageService).to receive(:new).and_return(service)

    described_class.new(schedule: schedule).perform

    expect(schedule.reload.metadata['review_state']).to eq('pending_review')
  end

  it 'does not generate for opted out cards' do
    card.update!(metadata: { 'follow_up_intent' => { 'state' => 'opted_out' } })

    expect(described_class.new(schedule: schedule).perform).to be_nil
  end
end
