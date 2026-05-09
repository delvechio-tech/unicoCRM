class Crm::KanbanPipeline < ApplicationRecord
  self.table_name = 'crm_kanban_pipelines'

  belongs_to :account

  has_many :stages, dependent: :destroy, class_name: '::Crm::KanbanStage', foreign_key: :pipeline_id, inverse_of: :pipeline
  has_many :cards, dependent: :destroy_async, class_name: '::Crm::KanbanCard', foreign_key: :pipeline_id, inverse_of: :pipeline

  validates :name, presence: true, uniqueness: { scope: :account_id }

  DEFAULT_STAGES = [
    { name: 'Novos leads', color: 'blue', stale_after_days: 2, win_probability: 10 },
    { name: 'Qualificacao', color: 'teal', stale_after_days: 3, win_probability: 25 },
    { name: 'Proposta enviada', color: 'amber', stale_after_days: 4, win_probability: 55 },
    { name: 'Negociacao', color: 'ruby', stale_after_days: 3, win_probability: 75 },
    { name: 'Ganhou', color: 'green', stale_after_days: 0, win_probability: 100 },
    { name: 'Perdido', color: 'slate', stale_after_days: 0, win_probability: 0 }
  ].freeze

  def self.ensure_default_for!(account)
    pipeline = account.crm_kanban_pipelines.find_or_create_by!(default: true) do |record|
      record.name = 'Pipeline comercial'
      record.description = 'Pipeline padrao para acompanhar clientes, oportunidades e follow-ups.'
      record.ai_rules = [
        'Mova cards apenas quando houver sinal claro na conversa.',
        'Atualize resumo e orcamento quando o cliente informar necessidade, valor ou prazo.',
        'Use Ganhou somente quando houver confirmacao objetiva de fechamento.',
        'Use Perdido somente quando o cliente recusar, sumir apos criterio definido ou ficar fora de perfil.'
      ].join("\n")
    end

    pipeline.ensure_default_stages!
    pipeline
  end

  def ensure_default_stages!
    DEFAULT_STAGES.each_with_index do |stage_attributes, index|
      stages.find_or_create_by!(name: stage_attributes[:name]) do |stage|
        stage.account = account
        stage.position = index
        stage.color = stage_attributes[:color]
        stage.stale_after_days = stage_attributes[:stale_after_days]
        stage.win_probability = stage_attributes[:win_probability]
      end
    end
  end
end
