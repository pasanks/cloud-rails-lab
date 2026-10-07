# Upload/list/download/delete files with Active Storage. On Cloud with a bucket
# attached this uses the `cloud` (S3) service; otherwise local disk.
class UploadsController < ApplicationController
  def index
    @blobs = ActiveStorage::Blob.order(created_at: :desc).limit(50)
    @service_name = ActiveStorage::Blob.service.name
  end

  def create
    file = params[:file]
    return redirect_to(uploads_path, alert: "Choose a file first.") if file.blank?

    blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename, content_type: file.content_type)
    redirect_to uploads_path, notice: "Uploaded #{blob.filename} to the #{blob.service_name} service."
  end

  def destroy
    ActiveStorage::Blob.find(params[:id]).purge
    redirect_to uploads_path, notice: "File deleted."
  end
end
