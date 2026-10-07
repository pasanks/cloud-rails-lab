# A hit counter stored in the Rails cache. With REDIS_URL it's shared by every
# process and instance; with the :memory_store fallback each process counts alone.
class CacheController < ApplicationController
  def show
    # increment returns nil when the cache server can't be reached.
    @hits = Rails.cache.increment("hit-counter")
    @store = Rails.cache.class.name
  end

  def destroy
    Rails.cache.delete("hit-counter")
    redirect_to cache_path, notice: "Hit counter reset."
  end
end
