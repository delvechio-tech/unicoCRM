class Crm::Kanban::ActionRecorder
  def initialize(card:, action_type:, actor_type: 'manual', user: nil, data: {})
    @card = card
    @action_type = action_type
    @actor_type = actor_type
    @user = user
    @data = data
  end

  def perform
    card.actions.create!(
      account: card.account,
      action_type: action_type,
      actor_type: actor_type,
      user: user,
      data: data
    )
  end

  private

  attr_reader :card, :action_type, :actor_type, :user, :data
end
