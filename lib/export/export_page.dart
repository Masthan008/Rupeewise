import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';

/// Export data page with file download and metadata tracking
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final ExportService _exportService = ExportService();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;
  ExportResult? _lastExport;
  String _selectedFormat = 'csv';
  List<ExportRecord> _exportHistory = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadExportHistory();
  }

  Future<void> _loadExportHistory() async {
    try {
      final history = await _exportService.getExportHistory();
      if (mounted) {
        setState(() {
          _exportHistory = history;
        });
      }
    } catch (_) {
      // Silently fail if table doesn't exist yet
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _exportAndDownload() async {
    setState(() {
      _isExporting = true;
      _lastExport = null;
    });

    try {
      final result = await _exportService.exportAndDownload(
        format: _selectedFormat,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _lastExport = result;
          _isExporting = false;
        });

        // Refresh history
        _loadExportHistory();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded ${result.filename} (${result.recordCount} records)'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.close : Icons.history),
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
            tooltip: 'Export History',
          ),
        ],
      ),
      body: _showHistory ? _buildHistoryView() : _buildExportView(),
    );
  }

  Widget _buildExportView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date range selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectDateRange,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.date_range),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Format selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Format',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'csv',
                        label: Text('CSV'),
                        icon: Icon(Icons.table_chart),
                      ),
                      ButtonSegment(
                        value: 'json',
                        label: Text('JSON'),
                        icon: Icon(Icons.code),
                      ),
                    ],
                    selected: {_selectedFormat},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedFormat = newSelection.first;
                        _lastExport = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Export button
          ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportAndDownload,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_isExporting ? 'Exporting...' : 'Download Export'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),

          // Last export info
          if (_lastExport != null) ...[
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Export Successful',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('File', _lastExport!.filename),
                    _buildInfoRow('Records', '${_lastExport!.recordCount}'),
                    _buildInfoRow('Status', 'Downloaded & Saved to History'),
                  ],
                ),
              ),
            ),
          ],

          // Export preview
          if (_lastExport != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Export Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: SelectableText(
                  _lastExport!.content,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_exportHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No export history',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your exports will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exportHistory.length,
      itemBuilder: (context, index) {
        final export = _exportHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: export.format == 'csv'
                  ? Colors.green.shade100
                  : Colors.blue.shade100,
              child: Icon(
                export.format == 'csv' ? Icons.table_chart : Icons.code,
                color: export.format == 'csv' ? Colors.green : Colors.blue,
              ),
            ),
            title: Text(
              '${export.format.toUpperCase()} Export',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              DateFormat('MMM d, yyyy h:mm a').format(export.createdAt),
            ),
            trailing: Text(
              '${export.recordCount} records',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
