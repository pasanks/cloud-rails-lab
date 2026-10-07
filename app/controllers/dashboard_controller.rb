class DashboardController < ApplicationController
  def show
    @checks = ResourceChecks.all
  end
end
