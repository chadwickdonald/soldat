class UserPolicy < ApplicationPolicy
  def index?   = user.admin?
  def show?    = user.admin?
  def create?  = user.admin?
  def new?     = user.admin?
  def update?  = user.admin?
  def edit?    = user.admin?
  def destroy? = user.admin?
end
