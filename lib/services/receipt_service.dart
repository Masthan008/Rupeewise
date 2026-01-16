import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for managing receipt/bill uploads to Supabase Storage
class ReceiptService {
  final _client = SupabaseService.instance.client;
  static const String _bucketName = 'receipts';

  /// Upload receipt image and return the public URL
  Future<String> uploadReceipt({
    required Uint8List imageBytes,
    required String expenseId,
    String? mimeType,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _getExtension(mimeType);
    final fileName = '$userId/$expenseId/$timestamp$extension';

    // Upload to Supabase Storage
    await _client.storage.from(_bucketName).uploadBinary(
      fileName,
      imageBytes,
      fileOptions: FileOptions(
        contentType: mimeType ?? 'image/jpeg',
        upsert: true,
      ),
    );

    // Get public URL
    final publicUrl = _client.storage.from(_bucketName).getPublicUrl(fileName);

    // Update expense with receipt URL
    await _updateExpenseReceiptUrl(expenseId, publicUrl);

    return publicUrl;
  }

  /// Get extension from MIME type
  String _getExtension(String? mimeType) {
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'application/pdf':
        return '.pdf';
      default:
        return '.jpg';
    }
  }

  /// Update expense with receipt URL
  Future<void> _updateExpenseReceiptUrl(String expenseId, String url) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('expenses')
        .update({'receipt_url': url})
        .eq('id', expenseId)
        .eq('user_id', userId);
  }

  /// Delete receipt from storage
  Future<void> deleteReceipt(String expenseId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get existing receipt URL
    final expense = await _client
        .from('expenses')
        .select('receipt_url')
        .eq('id', expenseId)
        .eq('user_id', userId)
        .single();

    final receiptUrl = expense['receipt_url'] as String?;
    if (receiptUrl == null || receiptUrl.isEmpty) return;

    // Extract path from URL
    final path = _extractPathFromUrl(receiptUrl);
    if (path != null) {
      try {
        await _client.storage.from(_bucketName).remove([path]);
      } catch (_) {
        // Silently fail if file doesn't exist
      }
    }

    // Clear receipt URL from expense
    await _client
        .from('expenses')
        .update({'receipt_url': null})
        .eq('id', expenseId)
        .eq('user_id', userId);
  }

  /// Extract storage path from public URL
  String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      // Find 'receipts' bucket in path and return everything after
      final bucketIndex = segments.indexOf(_bucketName);
      if (bucketIndex >= 0 && bucketIndex < segments.length - 1) {
        return segments.sublist(bucketIndex + 1).join('/');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get receipt URL for an expense
  Future<String?> getReceiptUrl(String expenseId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return null;

    try {
      final expense = await _client
          .from('expenses')
          .select('receipt_url')
          .eq('id', expenseId)
          .eq('user_id', userId)
          .single();

      return expense['receipt_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Check if expense has receipt
  Future<bool> hasReceipt(String expenseId) async {
    final url = await getReceiptUrl(expenseId);
    return url != null && url.isNotEmpty;
  }
}

