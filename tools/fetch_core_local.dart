#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

final defaultRepo = 'sipeed/picoclaw';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('repo', abbr: 'r', defaultsTo: defaultRepo)
    ..addOption('tag', abbr: 't', defaultsTo: 'latest')
    ..addOption('out-dir', defaultsTo: 'app/bin')
    ..addOption('dest', defaultsTo: '')
    ..addFlag('install-to-build', defaultsTo: false)
    ..addOption('pack-cmd', defaultsTo: '')
    ..addOption('platform', defaultsTo: '')
    ..addOption('arch', defaultsTo: '')
    ..addFlag('skip-build', defaultsTo: false)
    ..addOption('build-mode', defaultsTo: 'release')
    ..addOption('asset-name', defaultsTo: '')
    ..addOption('github-token', defaultsTo: '')
    ..addFlag('dry-run', negatable: false, defaultsTo: false)
    ..addFlag('help', abbr: 'h', negatable: false, defaultsTo: false);

  // Preprocess args to handle cases where `--github-token` is present but the
  // provided value is missing (e.g., the shell expanded an empty env var and
  // the next option was consumed as the token value). Replace `--github-token`
  // with `--github-token=` when it's the last arg or the next token looks like
  // an option so ArgParser doesn't consume the next real option as the token.
  final preArgs = List<String>.from(args);
  for (var i = 0; i < preArgs.length; i++) {
    if (preArgs[i] == '--github-token') {
      if (i == preArgs.length - 1 || preArgs[i + 1].startsWith('-')) {
        preArgs[i] = '--github-token=';
      }
    }
  }
  final results = parser.parse(preArgs);
  if (results['help'] as bool) {
    stdout.writeln(
      'Usage: dart run tools/fetch_core_local.dart [options]\n${parser.usage}',
    );
    exit(0);
  }

  final repo = results['repo'] as String;
  final tag = results['tag'] as String;
  final outDir = results['out-dir'] as String;
  final assetNameOverride = (results['asset-name'] as String).trim();
  var token = (results['github-token'] as String).trim();
  // If token looks like an option (e.g. '--platform') it means the user didn't
  // provide a value; treat as empty and allow env var fallback below.
  if (token.startsWith('-')) token = '';
  final dryRun = results['dry-run'] as bool;
  final destOverride = (results['dest'] as String).trim();
  final installToBuild = results['install-to-build'] as bool;
  final packCmd = (results['pack-cmd'] as String).trim();
  final targetPlatformArg = (results['platform'] as String).trim();
  final archOverride = (results['arch'] as String).trim();
  final skipBuild = results['skip-build'] as bool;
  final buildMode = (results['build-mode'] as String).trim();

  // If no token option provided, fallback to environment variable
  if (token.isEmpty) {
    final envTok = Platform.environment['GITHUB_TOKEN'] ?? '';
    if (envTok.isNotEmpty) {
      token = envTok;
      stdout.writeln('Using GITHUB_TOKEN from environment');
    }
  }

  await Directory(outDir).create(recursive: true);

  final hostPlatform = detectPlatform();
  final hostArch = await detectArch();
  final selectedPlatform = targetPlatformArg.isNotEmpty
      ? (targetPlatformArg.toLowerCase() == 'macos'
            ? 'Darwin'
            : (targetPlatformArg.toLowerCase() == 'windows'
                  ? 'Windows'
                  : (targetPlatformArg.toLowerCase() == 'linux'
                        ? 'Linux'
                        : targetPlatformArg)))
      : hostPlatform;
  final arch = archOverride.isNotEmpty ? archOverride : hostArch;
  stdout.writeln(
    'Repo: $repo  Tag: $tag  Host: $hostPlatform/$hostArch  Target: $selectedPlatform/$arch',
  );

  // If user requested a specific target platform, require explicit arch too.
  if (targetPlatformArg.isNotEmpty && archOverride.isEmpty) {
    stderr.writeln(
      'When specifying --platform you must also pass --arch (e.g. --platform windows --arch x86_64)',
    );
    exit(2);
  }

  // If requested, run platform build first (unless skipped). This is done
  // before contacting the release API so dry-run can simulate it.
  if (targetPlatformArg.isNotEmpty && !skipBuild) {
    List<String> buildArgs;
    final t = targetPlatformArg.toLowerCase();
    List<List<String>> allBuilds = [];
    if (t == 'android') {
      if (buildMode == 'release') {
        buildArgs = [
          'build',
          'appbundle',
          '--release',
          '--target-platform',
          'android-arm,android-arm64',
        ];
        // Also build an APK (release) so CI has both AAB and APK outputs if desired.
        allBuilds.add(buildArgs);
        allBuilds.add(['build', 'apk', '--release']);
      } else {
        buildArgs = ['build', 'apk', '--debug'];
        allBuilds.add(buildArgs);
      }
    } else if (t == 'windows' || t == 'macos' || t == 'linux') {
      final modeFlag = buildMode == 'release' ? '--release' : '--debug';
      buildArgs = ['build', t, modeFlag];
      allBuilds.add(buildArgs);
    } else {
      buildArgs = ['build', t, '--$buildMode'];
      allBuilds.add(buildArgs);
    }
    stdout.writeln('Planned build steps:');
    for (final b in allBuilds) {
      stdout.writeln(' - flutter ${b.join(' ')}');
    }
    if (!dryRun) {
      for (final b in allBuilds) {
        stdout.writeln('Running: flutter ${b.join(' ')}');
        final pr = await Process.start('flutter', b, runInShell: true);
        await stdout.addStream(pr.stdout);
        await stderr.addStream(pr.stderr);
        final ec = await pr.exitCode;
        if (ec != 0) {
          stderr.writeln('flutter build failed with exit code $ec');
          exit(ec);
        }
        stdout.writeln('Build step completed');
      }
      stdout.writeln('All build steps completed successfully');
    }
  }

  // Android uses JNI libraries packaged in the APK (`android/app/src/main/jniLibs`).
  // If the target is Android, we skip downloading desktop/native core binaries.
  if (targetPlatformArg.isNotEmpty &&
      targetPlatformArg.toLowerCase() == 'android') {
    stdout.writeln(
      'Target is Android; skipping core binary download because JNI libs are used for Android builds.',
    );
    // Still write a version.txt in out-dir if desired (optional). Exit success.
    if (!dryRun) {
      await File(
        '${outDir.endsWith(Platform.pathSeparator) ? outDir : outDir + Platform.pathSeparator}version.txt',
      ).writeAsString('android-jni-supplied', flush: true);
    }
    exit(0);
  }

  String? assetName;
  String? assetUrl;

  if (assetNameOverride.isNotEmpty) {
    assetName = assetNameOverride;
    stdout.writeln('Using override asset name: $assetName');
  } else {
    final api = Uri.parse(
      'https://api.github.com/repos/$repo/releases${tag == 'latest' ? '/latest' : '/tags/$tag'}',
    );
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
    };
    if (token.isNotEmpty) headers['Authorization'] = 'token $token';
    final resp = await http.get(api, headers: headers);
    if (resp.statusCode != 200) {
      stderr.writeln('Failed to fetch release JSON: ${resp.statusCode}');
      exit(2);
    }
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final assets = (data['assets'] as List).cast<Map<String, dynamic>>();

    final prefExts = selectedPlatform.toLowerCase() == 'windows'
        ? ['.zip']
        : ['.tar.gz', '.tgz'];

    final scored = <Map<String, dynamic>>[];
    final platformToken = () {
      final s = selectedPlatform.toLowerCase();
      if (s == 'macos' || s == 'darwin') return 'darwin';
      if (s == 'windows') return 'windows';
      if (s == 'linux') return 'linux';
      if (s == 'android') return 'android';
      return s;
    }();

    final archLower = arch.toLowerCase();
    for (final a in assets) {
      final name = a['name'] as String? ?? '';
      final nameLower = name.toLowerCase();
      var score = 0;
      for (final e in prefExts) {
        if (nameLower.endsWith(e)) score += 1;
      }
      if (nameLower.contains('_${platformToken}_') ||
          (nameLower.startsWith('picoclaw_') &&
              nameLower.contains(platformToken))) {
        score += 8;
      }
      if (nameLower.contains(archLower)) score += 4;
      if (score > 0) {
        scored.add({
          'score': score,
          'name': name,
          'url': a['browser_download_url'],
          'nameLower': nameLower,
        });
      }
    }
    if (scored.isEmpty) {
      for (final a in assets) {
        final name = a['name'] as String? ?? '';
        final nameLower = name.toLowerCase();
        for (final e in prefExts) {
          if (nameLower.endsWith(e)) {
            scored.add({
              'score': 1,
              'name': name,
              'url': a['browser_download_url'],
              'nameLower': nameLower,
            });
          }
        }
      }
    }
    if (scored.isEmpty) {
      stderr.writeln('No matching asset found in release.');
      exit(3);
    }
    scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    if (targetPlatformArg.isNotEmpty) {
      final firstMatch = scored.firstWhere(
        (s) => (s['nameLower'] as String).contains(platformToken),
        orElse: () => {},
      );
      if (firstMatch.isNotEmpty) {
        assetName = firstMatch['name'] as String;
        assetUrl = firstMatch['url'] as String;
      } else {
        stderr.writeln(
          'No release asset matching platform "$selectedPlatform" found.',
        );
        exit(3);
      }
    } else {
      assetName = scored.first['name'] as String;
      assetUrl = scored.first['url'] as String;
    }
  }

  assetUrl ??= await resolveAssetUrl(repo, tag, assetName, token);
  if (assetUrl == null) {
    stderr.writeln('Could not resolve asset URL');
    exit(4);
  }

  stdout.writeln('Selected asset: $assetName');
  if (dryRun) {
    stdout.writeln('Dry run - planned actions:');
    if (targetPlatformArg.isNotEmpty && !skipBuild) {
      stdout.writeln(
        ' - Build: flutter build ${targetPlatformArg.toLowerCase()} --$buildMode',
      );
    }
    stdout.writeln(' - Download: $assetUrl');
    final plannedInstallDest = destOverride.isNotEmpty
        ? destOverride
        : (installToBuild
              ? (selectedPlatform == 'Windows'
                    ? 'build/windows/runner/Release'
                    : (selectedPlatform == 'Darwin'
                          ? 'build/macos/Build/Products/Release'
                          : 'build/linux/x64/release/bundle'))
              : outDir);
    stdout.writeln(' - Install to out-dir: $outDir');
    stdout.writeln(
      ' - Install to build output (if enabled): $plannedInstallDest',
    );
    if (packCmd.isNotEmpty) stdout.writeln(' - Pack command: $packCmd');
    stdout.writeln('Dry run - exiting');
    exit(0);
  }

  final tmpDir = await Directory.systemTemp.createTemp('fetch_core_local');
  final archiveFile = File('${tmpDir.path}/asset');

  stdout.writeln('Downloading $assetUrl');
  await downloadToFile(Uri.parse(assetUrl), archiveFile, token);

  stdout.writeln('Extracting archive');
  final extractDir = Directory('${tmpDir.path}/extract');
  await extractDir.create();

  if (assetName.toLowerCase().endsWith('.zip')) {
    final bytes = await archiveFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filePath = '${extractDir.path}/${file.name}';
      if (file.isFile) {
        final out = File(filePath);
        await out.create(recursive: true);
        await out.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
  } else {
    final bytes = await archiveFile.readAsBytes();
    final gunz = GZipDecoder().decodeBytes(bytes);
    final tar = TarDecoder().decodeBytes(gunz);
    for (final f in tar.files) {
      final filePath = '${extractDir.path}/${f.name}';
      if (f.isFile) {
        final out = File(filePath);
        await out.create(recursive: true);
        await out.writeAsBytes(f.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
  }

  // Find executables: prefer the launcher (picoclaw-launcher) but also
  // extract the core `picoclaw` binary if present. We will copy both into
  // the outDir so packaging includes the launcher and the core binary.
  File? foundLauncher;
  File? foundCore;
  File? fallbackExecutable;
  await for (final entity in extractDir.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File) {
      final name = entity.uri.pathSegments.last;
      if (name == 'picoclaw-launcher' || name == 'picoclaw-launcher.exe') {
        foundLauncher = entity;
      }
      if (name == 'picoclaw' || name == 'picoclaw.exe') {
        foundCore = entity;
      }
      if (fallbackExecutable == null) {
        if (Platform.isWindows) {
          if (name.toLowerCase().endsWith('.exe')) fallbackExecutable = entity;
        } else {
          try {
            final stat = await entity.stat();
            if ((stat.mode & 0x49) != 0) {
              // simple executable bit check
              fallbackExecutable = entity;
            }
          } catch (_) {}
        }
      }
    }
  }
  if (foundLauncher == null &&
      foundCore == null &&
      fallbackExecutable == null) {
    stderr.writeln('Could not locate an executable in the archive');
    exit(5);
  }

  // Copy files: prefer to copy launcher and core if present, otherwise copy the first executable found.
  final copiedNames = <String>[];
  Future<void> copyIfPresent(File? src) async {
    if (src == null) return;
    final destName = src.uri.pathSegments.last;
    final destFile = File(
      '${outDir.endsWith(Platform.pathSeparator) ? outDir : outDir + Platform.pathSeparator}$destName',
    );
    await destFile.create(recursive: true);
    await src.copy(destFile.path);
    if (!Platform.isWindows) {
      try {
        final pr = await Process.run('chmod', ['+x', destFile.path]);
        if (pr.exitCode != 0) stdout.writeln('chmod returned ${pr.stderr}');
      } catch (_) {}
    }
    copiedNames.add(destName);
  }

  if (foundLauncher != null) {
    await copyIfPresent(foundLauncher);
  }
  if (foundCore != null) {
    await copyIfPresent(foundCore);
  }
  if (copiedNames.isEmpty && fallbackExecutable != null) {
    await copyIfPresent(fallbackExecutable);
  }

  // Write a version.txt that records the asset and the installed binary names
  final versionContents = StringBuffer();
  versionContents.writeln(assetName);
  for (final n in copiedNames) {
    versionContents.writeln(n);
  }
  await File(
    '${outDir.endsWith(Platform.pathSeparator) ? outDir : outDir + Platform.pathSeparator}version.txt',
  ).writeAsString(versionContents.toString().trim(), flush: true);

  stdout.writeln(
    'Installed ${copiedNames.join(', ')} to $outDir and wrote version.txt ($assetName)',
  );

  // Optionally install into a build output directory
  String? installDest;
  if (destOverride.isNotEmpty) {
    installDest = destOverride;
  } else if (installToBuild) {
    if (Platform.isWindows) {
      // CI packages Windows at build/windows/x64/runner/Release, so install there
      installDest =
          'build${Platform.pathSeparator}windows${Platform.pathSeparator}x64${Platform.pathSeparator}runner${Platform.pathSeparator}Release';
    } else if (Platform.isMacOS) {
      installDest =
          'build${Platform.pathSeparator}macos${Platform.pathSeparator}Build${Platform.pathSeparator}Products${Platform.pathSeparator}Release';
    } else if (Platform.isLinux) {
      installDest =
          'build${Platform.pathSeparator}linux${Platform.pathSeparator}x64${Platform.pathSeparator}release${Platform.pathSeparator}bundle';
    }
  }

  if (installDest != null && installDest.isNotEmpty) {
    try {
      final instDir = Directory(installDest);
      await instDir.create(recursive: true);
      if (Platform.isMacOS) {
        // For macOS desktop, ensure core binaries are bundled inside the .app so
        // runtime resolution (Contents/MacOS/bin) works when distributed.
        final apps = instDir
            .listSync()
            .whereType<Directory>()
            .where((d) => d.path.toLowerCase().endsWith('.app'))
            .toList();
        if (apps.isEmpty) {
          throw Exception('No .app found under install destination: ${instDir.path}');
        }

        final app = apps.first;
        final macosBinDir = Directory(
          '${app.path}${Platform.pathSeparator}Contents${Platform.pathSeparator}MacOS${Platform.pathSeparator}bin',
        );
        await macosBinDir.create(recursive: true);

        for (final n in copiedNames) {
          final src = File(
            '${outDir.endsWith(Platform.pathSeparator) ? outDir : outDir + Platform.pathSeparator}$n',
          );
          final targetPath =
              '${macosBinDir.path}${Platform.pathSeparator}$n';
          if (await src.exists()) {
            await src.copy(targetPath);
            try {
              await Process.run('chmod', ['+x', targetPath]);
            } catch (_) {}
          }
        }

        await File(
          '${macosBinDir.path}${Platform.pathSeparator}version.txt',
        ).writeAsString(versionContents.toString().trim(), flush: true);
        stdout.writeln(
          'Copied ${copiedNames.join(', ')} into app bundle: ${macosBinDir.path}',
        );
      } else {
        // Preserve the out-dir path (typically app/bin) inside the build output
        final relativeOut =
            outDir.replaceAll(RegExp(r'[\\/]+'), Platform.pathSeparator);
        final targetDir = '${instDir.path}${Platform.pathSeparator}$relativeOut';
        final td = Directory(targetDir);
        await td.create(recursive: true);
        // copy all installed names into the build output under the preserved out-dir
        for (final n in copiedNames) {
          final src = File(
            '${outDir.endsWith(Platform.pathSeparator) ? outDir : outDir + Platform.pathSeparator}$n',
          );
          final targetPath = '$targetDir${Platform.pathSeparator}$n';
          if (await src.exists()) {
            await src.copy(targetPath);
            if (!Platform.isWindows) {
              try {
                await Process.run('chmod', ['+x', targetPath]);
              } catch (_) {}
            }
          }
        }
        // Also write version.txt next to installed binary for traceability
        await File('${td.path}${Platform.pathSeparator}version.txt')
            .writeAsString(
          versionContents.toString().trim(),
          flush: true,
        );
        stdout.writeln(
          'Copied ${copiedNames.join(', ')} to build output: ${td.path}',
        );
      }
    } catch (e) {
      stderr.writeln('Failed to copy to install target $installDest: $e');
      exit(6);
    }
  }

  // Optionally run a packager command (e.g., NSIS, codesign, dmg creation)
  if (packCmd.isNotEmpty) {
    stdout.writeln('Running pack command: $packCmd');
    try {
      ProcessResult pr;
      if (Platform.isWindows) {
        pr = await Process.run('cmd', ['/c', packCmd], runInShell: true);
      } else {
        pr = await Process.run('sh', ['-c', packCmd], runInShell: true);
      }
      stdout.writeln(pr.stdout.toString());
      stderr.writeln(pr.stderr.toString());
      if (pr.exitCode != 0) {
        stderr.writeln('Pack command failed with exit code ${pr.exitCode}');
        exit(pr.exitCode);
      }
      stdout.writeln('Pack command completed successfully');
    } catch (e) {
      stderr.writeln('Failed to run pack command: $e');
      exit(7);
    }
  }

  await tmpDir.delete(recursive: true);
}

String detectPlatform() {
  if (Platform.isWindows) return 'Windows';
  if (Platform.isMacOS) return 'Darwin';
  if (Platform.isLinux) return 'Linux';
  return Platform.operatingSystem;
}

Future<String> detectArch() async {
  if (Platform.isWindows) {
    final envArch = Platform.environment['PROCESSOR_ARCHITECTURE'];
    if (envArch != null) {
      if (envArch.toLowerCase().contains('amd64') ||
          envArch.toLowerCase().contains('x86_64')) {
        return 'x86_64';
      }
      if (envArch.toLowerCase().contains('arm')) {
        return 'arm64';
      }
      return envArch;
    }
  }
  try {
    final pr = await Process.run('uname', ['-m']);
    if (pr.exitCode == 0) {
      final out = (pr.stdout as String).trim();
      if (out == 'x86_64' || out == 'amd64') {
        return 'x86_64';
      }
      if (out.contains('arm') || out.contains('aarch64')) {
        return 'arm64';
      }
      return out;
    }
  } catch (_) {}
  return 'x86_64';
}

Future<void> downloadToFile(Uri url, File file, String token) async {
  final client = http.Client();
  try {
    final req = http.Request('GET', url);
    if (token.isNotEmpty) {
      req.headers['Authorization'] = 'token $token';
    }
    final streamed = await client.send(req);
    if (streamed.statusCode != 200) {
      throw HttpException('Download failed: ${streamed.statusCode}');
    }
    final sink = file.openWrite();
    await streamed.stream.pipe(sink);
    await sink.close();
  } finally {
    client.close();
  }
}

Future<String?> resolveAssetUrl(
  String repo,
  String tag,
  String name,
  String token,
) async {
  if (name.isEmpty) return null;
  final api = Uri.parse(
    'https://api.github.com/repos/$repo/releases${tag == 'latest' ? '/latest' : '/tags/$tag'}',
  );
  final headers = <String, String>{'Accept': 'application/vnd.github.v3+json'};
  if (token.isNotEmpty) headers['Authorization'] = 'token $token';
  final resp = await http.get(api, headers: headers);
  if (resp.statusCode != 200) return null;
  final data = json.decode(resp.body) as Map<String, dynamic>;
  final assets = (data['assets'] as List).cast<Map<String, dynamic>>();
  for (final a in assets) {
    if ((a['name'] as String) == name) {
      return a['browser_download_url'] as String;
    }
  }
  return null;
}
