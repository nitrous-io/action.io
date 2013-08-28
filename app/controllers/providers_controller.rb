class ProvidersController < ApplicationController
  before_filter :authorize_as_addon_provider!

  def index
    if current_user.addon_provider_has_agreed_terms?
      render :index
    else
      redirect_to show_terms_providers_path
    end
  end

  def show_terms
    if current_user.addon_provider_has_agreed_terms?
      redirect_to providers_path
    else
      render :show_terms
    end
  end

  def agree_terms
    if params[:agree]
      current_user.update_attribute(:addon_provider_has_agreed_terms, true)
      redirect_to providers_path
    else
      redirect_to show_terms_providers_path
    end
  end
end
