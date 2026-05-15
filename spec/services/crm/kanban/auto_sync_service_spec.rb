require 'rails_helper'

RSpec.describe Crm::Kanban::AutoSyncService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, name: 'Cliente Teste') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) do
    create(
      :message,
      account: account,
      inbox: inbox,
      conversation: conversation,
      message_type: 'incoming',
      content: 'Quero um orcamento'
    )
  end

  before do
    allow(Crm::KanbanWebhookJob).to receive(:perform_later)
  end

  describe '#perform' do
    it 'creates a card in the default pipeline when no open card exists' do
      card = described_class.new(message: message).perform

      expect(card).to be_persisted
      expect(card.pipeline).to eq(Crm::KanbanPipeline.ensure_default_for!(account))
      expect(card.contact).to eq(contact)
      expect(card.conversation).to eq(conversation)
      expect(card.last_message).to eq(message)
      expect(card.metadata['last_message_id']).to eq(message.id)
    end

    it 'updates an existing open card in another pipeline instead of duplicating it' do
      other_pipeline = account.crm_kanban_pipelines.create!(name: 'Retencao', default: false)
      other_stage = other_pipeline.stages.create!(account: account, name: 'Em andamento', position: 0)
      existing_card = account.crm_kanban_cards.create!(
        pipeline: other_pipeline,
        stage: other_stage,
        contact: contact,
        conversation: conversation,
        title: 'Card existente',
        status: 'open'
      )

      expect do
        result = described_class.new(message: message).perform
        expect(result).to eq(existing_card)
      end.not_to change(account.crm_kanban_cards, :count)

      expect(existing_card.reload.last_message).to eq(message)
      expect(existing_card.stage).to eq(other_stage)
      expect(existing_card.metadata['last_message_id']).to eq(message.id)
    end

    it 'creates the card in the pipeline stage selected by structured automation rules' do
      pipeline = account.crm_kanban_pipelines.create!(name: 'Conversas Atrasadas', default: false, position: 1)
      stage = pipeline.stages.create!(account: account, name: 'Novas Conversas', position: 0)
      pipeline.update!(
        settings: {
          'automation_rules' => [
            {
              'id' => 'rule-incoming',
              'name' => 'Mensagem recebida',
              'enabled' => true,
              'trigger' => 'message_created',
              'condition' => 'incoming_message',
              'stage_id' => stage.id
            }
          ]
        }
      )

      card = described_class.new(message: message).perform

      expect(card.pipeline).to eq(pipeline)
      expect(card.stage).to eq(stage)
      expect(card.metadata['kanban_rule_id']).to eq('rule-incoming')
    end

    it 'moves an existing card when an outgoing message matches an answered rule' do
      pipeline = account.crm_kanban_pipelines.create!(name: 'Conversas Atrasadas', default: false, position: 1)
      waiting_stage = pipeline.stages.create!(account: account, name: 'Lidas', position: 0)
      answered_stage = pipeline.stages.create!(account: account, name: 'Respondida', position: 1)
      pipeline.update!(
        settings: {
          'automation_rules' => [
            {
              'id' => 'rule-answered',
              'name' => 'Respondida',
              'enabled' => true,
              'trigger' => 'message_created',
              'condition' => 'agent_replied',
              'stage_id' => answered_stage.id
            }
          ]
        }
      )
      card = account.crm_kanban_cards.create!(
        pipeline: pipeline,
        stage: waiting_stage,
        contact: contact,
        conversation: conversation,
        title: 'Cliente Teste',
        status: 'open'
      )
      outgoing_message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        message_type: 'outgoing',
        content: 'Respondido'
      )

      result = described_class.new(message: outgoing_message).perform

      expect(result).to eq(card)
      expect(card.reload.stage).to eq(answered_stage)
      expect(card.last_message).to eq(outgoing_message)
    end
  end
end
