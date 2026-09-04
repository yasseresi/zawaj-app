import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../config/app_config.dart';
import '../data/services/api_client.dart';
import 'path_service.dart';
import '../utils/utils.dart';

/// Downloads guest-list exports through the authenticated API and stores them
/// in the app documents directory so the platform share sheet can open them.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  final ApiClient _api = ApiClient.instance;

  FutureEither<File> download(String weddingId, ExportFormat format) async {
    final response =
        await _api.raw<List<int>>(() => AppConfig.dio.get<List<int>>(
              '/weddings/$weddingId/export.${format.extension}',
              options: Options(responseType: ResponseType.bytes),
            ));

    return response.match(
      (failure) => Left(failure),
      (value) async {
        final directoryResult =
            await PathService.instance.getDocumentsDirectory();
        return directoryResult.match(
          (failure) => Left(failure),
          (directory) async {
            final file =
                File('${directory.path}/guest-list.${format.extension}');
            await file.writeAsBytes(value.data ?? const <int>[]);
            return Right(file);
          },
        );
      },
    );
  }
}

enum ExportFormat {
  csv,
  xlsx,
  pdf;

  String get extension => name;
  String get mimeType => switch (this) {
        ExportFormat.csv => 'text/csv',
        ExportFormat.xlsx =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ExportFormat.pdf => 'application/pdf',
      };
}
