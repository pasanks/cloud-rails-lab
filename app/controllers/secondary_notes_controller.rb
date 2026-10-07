# Create/list/delete notes in the optional secondary database (SECONDARY_DATABASE_URL).
class SecondaryNotesController < ApplicationController
  before_action :require_secondary_database

  def index
    @notes = SecondaryNote.order(created_at: :desc)
  end

  def create
    note = SecondaryNote.new(params.expect(secondary_note: [ :title, :body ]))
    if note.save
      redirect_to secondary_notes_path, notice: "Note saved to the secondary database."
    else
      redirect_to secondary_notes_path, alert: note.errors.full_messages.to_sentence
    end
  end

  def destroy
    SecondaryNote.find(params[:id]).destroy
    redirect_to secondary_notes_path, notice: "Note deleted."
  end

  private

  # Without SECONDARY_DATABASE_URL, SecondaryNote would fall back to the primary
  # database, so we stop here instead.
  def require_secondary_database
    render :not_configured unless SecondaryRecord.configured?
  end
end
