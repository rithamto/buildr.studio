import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:volta/screens/home_screen/file_explorer_state.dart';
import 'package:volta/utils/git_ignore_checker.dart';

class VariableSectionState extends ChangeNotifier {
  final Map<String, List<String>> _selectedPaths = {};
  final Map<String, String?> _concatenatedContents = {};
  final Map<String, String> _inputValues = {};

  Map<String, List<String>> get selectedPaths => _selectedPaths;
  Map<String, String?> get concatenatedContents => _concatenatedContents;
  Map<String, String> get inputValues => _inputValues;

  void onPathsSelected(String variableName, List<String> paths) {
    _selectedPaths[variableName] = paths;
    _concatenatedContents[variableName] = null;
    notifyListeners();
  }

  void setInputValue(String variableName, String value) {
    _inputValues[variableName] = value;
    notifyListeners();
  }

  String? getConcatenatedContent(BuildContext context, String variableName) {
    if (!_selectedPaths.containsKey(variableName) ||
        _selectedPaths[variableName]?.isEmpty == true) {
      return null;
    }

    try {
      final gitIgnoreContent =
          context.read<FileExplorerState>().gitIgnoreContent;
      if (gitIgnoreContent == null) {
        return null;
      }

      final concatenatedContent = StringBuffer();
      for (final p in _selectedPaths[variableName]!) {
        final fileInfo = FileSystemEntity.typeSync(p);
        if (fileInfo == FileSystemEntityType.file) {
          final file = File(p);
          final relativePath =
              '${path.separator}${path.relative(file.path, from: context.read<FileExplorerState>().selectedFolderPath!)}';
          if (!GitIgnoreChecker.isPathIgnored(gitIgnoreContent, relativePath)) {
            concatenatedContent.write('---${path.basename(p)}---\n```\n');
            concatenatedContent.write(file.readAsStringSync());
            concatenatedContent.write('\n```\n');
          }
        } else if (fileInfo == FileSystemEntityType.directory) {
          final directory = Directory(p);
          final files =
              directory.listSync(recursive: true).whereType<File>().toList();
          for (final file in files) {
            final relativePath =
                '${path.separator}${path.relative(file.path, from: context.read<FileExplorerState>().selectedFolderPath!)}';
            if (!GitIgnoreChecker.isPathIgnored(
                gitIgnoreContent, relativePath)) {
              concatenatedContent
                  .write('---${path.basename(file.path)}---\n```\n');
              concatenatedContent.write(file.readAsStringSync());
              concatenatedContent.write('\n```\n');
            }
          }
        }
      }
      final content = concatenatedContent.toString().trim();
      _concatenatedContents[variableName] = content;
      return content;
    } catch (e) {
      // Log or display the error to the UI
      print('Error concatenating file contents for variable $variableName: $e');
      return null;
    }
  }

  void submit(BuildContext context) {
    print('Input values:');
    for (final entry in _inputValues.entries) {
      print('${entry.key}: ${entry.value}');
    }

    for (final variableName in _selectedPaths.keys) {
      _concatenatedContents[variableName] =
          getConcatenatedContent(context, variableName);
    }

    print('Concatenated contents:');
    for (final entry in _concatenatedContents.entries) {
      final variableName = entry.key;
      final content = entry.value;
      if (content != null) {
        print('$variableName:\n$content');
      } else {
        print('$variableName: No content available');
      }
    }
  }
}
