class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?   = user.present?
  def show?    = user.present?
  def create?  = user.admin?
  def new?     = create?
  def update?  = user.admin?
  def edit?    = update?
  def destroy? = user.admin?

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      @scope.all
    end

    private

    attr_reader :user, :scope
  end
end
