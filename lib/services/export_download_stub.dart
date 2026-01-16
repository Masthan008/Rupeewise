/// Stub download implementation for non-web platforms
void downloadFile({
  required String content,
  required String filename,
  required String mimeType,
}) {
  // On mobile, you would use path_provider + file_saver
  // For now, this is a no-op stub
  // TODO: Implement mobile file download if needed
}
