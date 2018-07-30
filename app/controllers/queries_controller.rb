class QueriesController < ApplicationController
  def create
    LodqaSearchJob.perform_later params[:query],
                                 'https://webhook.site/1469caf6-efeb-4fb1-93b0-103ae91d4741',
                                 'https://webhook.site/1469caf6-efeb-4fb1-93b0-103ae91d4741'
  end
end
