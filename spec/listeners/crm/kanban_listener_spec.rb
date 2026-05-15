require 'rails_helper'

RSpec.describe Crm::KanbanListener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: 'incoming') }

  describe '#message_created' do
    it 'enqueues auto sync for public incoming messages' do
      event = Events::Base.new('message.created', Time.zone.now, message: message)

      expect(Crm::KanbanAutoSyncJob).to receive(:perform_later).with(message.id)

      listener.message_created(event)
    end

    it 'enqueues auto sync for public outgoing messages so rules can mark conversations as answered' do
      outgoing_message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: 'outgoing')
      event = Events::Base.new('message.created', Time.zone.now, message: outgoing_message)

      expect(Crm::KanbanAutoSyncJob).to receive(:perform_later).with(outgoing_message.id)

      listener.message_created(event)
    end

    it 'ignores events without a message' do
      event = Events::Base.new('message.created', Time.zone.now, message: nil)

      expect(Crm::KanbanAutoSyncJob).not_to receive(:perform_later)

      listener.message_created(event)
    end
  end
end
