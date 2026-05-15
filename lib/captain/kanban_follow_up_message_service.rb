class Captain::KanbanFollowUpMessageService < Captain::BaseTaskService
  pattr_initialize [:account!, :conversation_display_id!, :instruction!, :schedule_context!]

  def perform
    make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('kanban_follow_up_message') },
        { role: 'user', content: generation_context }
      ]
    )
  end

  private

  def generation_context
    [
      "Instrucao do funil:\n#{instruction}",
      "Contexto do retorno:\n#{schedule_context.to_json}",
      "Conversa:\n#{conversation.to_llm_text(include_contact_details: false)}"
    ].join("\n\n")
  end

  def event_name
    'kanban_follow_up_message'
  end
end
