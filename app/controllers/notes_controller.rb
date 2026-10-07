# Create/list/delete notes in the primary database (DATABASE_URL).
class NotesController < ApplicationController
  def index
    @notes = Note.order(created_at: :desc)
  end

  def create
    note = Note.new(params.expect(note: [ :title, :body ]))
    if note.save
      redirect_to notes_path, notice: "Note saved to the primary database."
    else
      redirect_to notes_path, alert: note.errors.full_messages.to_sentence
    end
  end

  def destroy
    Note.find(params[:id]).destroy
    redirect_to notes_path, notice: "Note deleted."
  end
end
