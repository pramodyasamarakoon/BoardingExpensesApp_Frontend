import 'dart:convert';
import 'dart:io';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';

class GoogleSheetsService {
  final String _spreadsheetId = '12t3iMjL3CvKUGnAd0k5SmGY9vHGRKOCm_AuO2FCVzt8';
  final String _jsonFilePath = 'assets/boarding-expenses-project-faf0effc839f.json';
  sheets.SheetsApi? _sheetsApi;

  Future<void> initialize() async {
    final credentials = ServiceAccountCredentials.fromJson(
      json.decode(await File(_jsonFilePath).readAsString()),
    );

    const scopes = [sheets.SheetsApi.spreadsheetsScope];

    final client = await clientViaServiceAccount(credentials, scopes);
    _sheetsApi = sheets.SheetsApi(client);
  }

  Future<void> addExpense(Map<String, String> expenseData) async {
    if (_sheetsApi == null) {
      throw Exception('Google Sheets API is not initialized.');
    }

    final range = 'Sheet1!A:D'; // Adjust this to match your spreadsheet layout.
    final values = [
      [
        expenseData['date'],
        expenseData['amount'],
        expenseData['remark'],
        expenseData['members']
      ]
    ];

    final valueRange = sheets.ValueRange.fromJson({
      'values': values,
    });

    await _sheetsApi!.spreadsheets.values.append(
      valueRange,
      _spreadsheetId,
      range,
      valueInputOption: 'RAW',
    );
  }
}
