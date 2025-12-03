import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/report/report_filter.dart';
import 'auth_interceptor.dart';

class ReportDownloadService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

  ReportDownloadService(): super() {
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  Future<void> _setAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Download report file (PDF or Excel)
  Future<bool> downloadReport({
    required String reportType,
    required ReportFilter filter,
  }) async {
    try {
      await _setAuthHeaders();

      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Build query parameters from filter
      final queryParams = <String, dynamic>{};
      
      if (filter.startDate != null) {
        queryParams['StartDate'] = filter.startDate!.toIso8601String();
      }
      if (filter.endDate != null) {
        queryParams['EndDate'] = filter.endDate!.toIso8601String();
      }
      
      if (filter.term != null) queryParams['Term'] = filter.term;
      if (filter.year != null) queryParams['Year'] = filter.year;
      if (filter.gradeId != null) queryParams['GradeId'] = filter.gradeId;
      if (filter.paymentMethod != null) queryParams['PaymentMethod'] = filter.paymentMethod;
      if (filter.feeType != null) queryParams['FeeType'] = filter.feeType;
      
      queryParams['Format'] = filter.format;
    
      // Build the endpoint URL - handle student-statement special case
      String endpoint;
      if (reportType == 'student-statement' && filter.studentId != null) {
        // For student statement, studentId goes in the URL path, not query params
        endpoint = '/admin/Report/student-statement/${filter.studentId}';
      } else {
        // For all other reports, use standard endpoint
        endpoint = '/admin/Report/$reportType';
        // Add studentId as query param for other reports if provided
        if (filter.studentId != null) {
          queryParams['StudentId'] = filter.studentId;
        }
      }

      // Determine file extension and MIME type
      final isExcel = filter.format.toUpperCase() == 'EXCEL';
      final extension = isExcel ? 'xlsx' : 'pdf';
      final mimeType = isExcel 
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : 'application/pdf';

      // Generate filename
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final sanitizedReportType = reportType.replaceAll('/', '_').replaceAll(' ', '_');
      final fileName = '${sanitizedReportType}_$timestamp.$extension';

      // Get download directory
      Directory? directory;
      if (Platform.isAndroid) {
        try {
          final downloadPath = '/storage/emulated/0/Download';
          directory = Directory(downloadPath);
          
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } catch (e) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not find download directory');
      }

      final filePath = '${directory.path}/$fileName';

      // Make request to download file
      final checkResponse = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
          headers: {
            'Accept': mimeType,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Check if response is successful
      if (checkResponse.statusCode != 200) {
        String errorMsg = 'Server returned status ${checkResponse.statusCode}';
        
        if (checkResponse.data != null) {
          try {
            final responseText = String.fromCharCodes(checkResponse.data);
            errorMsg += '\n$responseText';
          } catch (e) {
            // Could not parse response
          }
        }
        
        throw Exception(errorMsg);
      }

      // Check content type
      final contentType = checkResponse.headers.value('content-type')?.toLowerCase();
      
      if (contentType != null) {
        final isValidContent = isExcel 
            ? (contentType.contains('spreadsheet') || contentType.contains('excel') || contentType.contains('octet-stream'))
            : (contentType.contains('pdf') || contentType.contains('octet-stream'));
        
        if (!isValidContent && !contentType.contains('application/json')) {
          throw Exception('Invalid response type: $contentType. Expected ${isExcel ? "Excel" : "PDF"} file.');
        }
      }

      // Check if we got data
      final responseData = checkResponse.data as List<int>;
      if (responseData.isEmpty) {
        throw Exception('Server returned empty response');
      }

      // Verify it's not an error response (HTML/JSON)
      if (responseData.length < 1000) {
        final previewText = String.fromCharCodes(responseData.take(100).toList());
        if (previewText.toLowerCase().contains('<html') || 
            previewText.toLowerCase().contains('<!doctype') ||
            previewText.trim().startsWith('{')) {
          throw Exception('Server returned error page instead of file');
        }
      }

      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(responseData);

      // Verify file was saved
      if (!await file.exists()) {
        throw Exception('File was not created at $filePath');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File was saved but is empty');
      }

      if (fileSize != responseData.length) {
        throw Exception('File size mismatch: saved $fileSize bytes, expected ${responseData.length} bytes');
      }

      // Open the file automatically
      try {
        await OpenFile.open(filePath);
      } catch (e) {
        // Don't fail the download if we can't open the file
      }

      return true;
      
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Report endpoint not found: Check if the endpoint exists in the backend.');
      } else if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Authentication error. Please log in again.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error while generating report. Please check backend logs.');
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timeout. The report might be too large or server is slow.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Connection error. Please check your internet connection and server status.');
      }
      
      return false;
      
    } catch (e) {
      rethrow;
    }
  }

}