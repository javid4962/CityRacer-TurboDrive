// lib/widgets/developer_apps.dart
// ignore_for_file: use_super_parameters, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Model class representing a store application.
class StoreApp {
  final String name;
  final String iconUrl;
  final String detailsUrl;
  final String description;
  final String genres;
  final String price;

  StoreApp({
    required this.name,
    required this.iconUrl,
    required this.detailsUrl,
    required this.description,
    this.genres = '',
    this.price = '',
  });

  factory StoreApp.fromJson(Map<String, dynamic> json, String baseUrl) {
    return StoreApp(
      name: json['name'] as String,
      iconUrl: '$baseUrl${json['icon'] as String}',
      detailsUrl: json['detailsUrl'] as String,
      description: (json['description'] as String?) ?? '',
      genres: (json['genres'] as String?) ?? '',
      price: (json['price'] as String?) ?? '',
    );
  }
}

class DeveloperAppsScreen extends StatelessWidget {
  final DeveloperAppsMode mode;

  const DeveloperAppsScreen({
    super.key,
    this.mode = DeveloperAppsMode.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c2c),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Try Our Apps',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff1a1c2c), Color(0xff2d3142), Color(0xff4f5d75)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: DeveloperApps(mode: mode),
      ),
    );
  }
}

/// Enum to select layout mode
enum DeveloperAppsMode { horizontal, vertical }

/// Global in-memory cache for images
final Map<String, Future<File>> _imageCache = {};

Future<File> _getCachedImage(String url) {
  if (_imageCache.containsKey(url)) return _imageCache[url]!;
  final future = _downloadAndCacheImage(url);
  _imageCache[url] = future;
  return future;
}

Future<File> _downloadAndCacheImage(String url) async {
  final cacheDir = Directory.systemTemp;
  final file = File('${cacheDir.path}/cache_${url.hashCode}.img');
  if (await file.exists()) return file;
  final resp = await HttpClient().getUrl(Uri.parse(url)).then((r) => r.close());
  final bytes = await consolidateHttpClientResponseBytes(resp);
  await file.writeAsBytes(bytes);
  return file;
}

/// Cached image widget
class CachedImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _getCachedImage(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return Image.file(
            snapshot.data!,
            fit: fit,
            width: width,
            height: height,
          );
        }
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade300,
        );
      },
    );
  }
}

/// Main widget: supports both layouts
class DeveloperApps extends StatefulWidget {
  final DeveloperAppsMode mode;

  const DeveloperApps({Key? key, required this.mode}) : super(key: key);

  @override
  State<DeveloperApps> createState() => _DeveloperAppsState();
}

class _DeveloperAppsState extends State<DeveloperApps> {
  static const String _baseUrl = 'https://pixoplayusa.com/developerapps/';
  late Future<List<StoreApp>> _appsFuture;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  void _loadApps() {
    final url = Platform.isIOS
        ? '$_baseUrl/devapplist_ios.json'
        : '$_baseUrl/devapplist_android.json';
    _appsFuture = _fetchApps(url);
  }

  Future<List<StoreApp>> _fetchApps(String url) async {
    final fileName = Platform.isIOS ? "ios.json" : "android.json";
    final cacheFile = File('${Directory.systemTemp.path}/$fileName');

    String? cachedData;
    if (await cacheFile.exists()) {
      cachedData = await cacheFile.readAsString();
    }

    try {
      final resp = await HttpClient()
          .getUrl(Uri.parse(url))
          .then((r) => r.close());
      final text = await resp.transform(utf8.decoder).join();
      if (cachedData == null || cachedData != text) {
        await cacheFile.writeAsString(text);
        cachedData = text;
      }
    } catch (_) {
      if (cachedData == null) rethrow;
    }

    final List jsonList = json.decode(cachedData) as List;
    final apps = jsonList.map((j) => StoreApp.fromJson(j, _baseUrl)).toList();
    apps.shuffle(Random());
    return apps.take((apps.length * 0.5).ceil()).toList();
  }

  Future<void> _refreshApps() async {
    setState(_loadApps);
    await _appsFuture;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StoreApp>>(
      future: _appsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final apps = snapshot.data!;
        if (apps.isEmpty) {
          return const Center(
            child: Text(
              'No apps found.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        // Horizontal card layout
        if (widget.mode == DeveloperAppsMode.horizontal) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final double buttonFontSize =
                  10 * MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.3);
              // Adaptive sizing
              final itemSize =
                  screenWidth * 0.22; // e.g., 80–160 px depending on screen
              final buttonWidth = itemSize + 20;
              final height = itemSize + 90;
              final scaleFactor = MediaQuery.textScaleFactorOf(
                context,
              ).clamp(1.0, 1.3);

              return RefreshIndicator(
                onRefresh: _refreshApps,
                child: SizedBox(
                  height: height,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    itemCount: apps.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final app = apps[i];
                      return TweenAnimationBuilder<Offset>(
                        tween: Tween(
                          begin: const Offset(0.3, 0),
                          end: Offset.zero,
                        ),
                        duration: Duration(milliseconds: 500 + (i * 100)),
                        curve: Curves.easeOutCubic,
                        builder: (context, offset, child) {
                          return Transform.translate(
                            offset: Offset(offset.dx * screenWidth, 0),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity: 1.0,
                              child: child,
                            ),
                          );
                        },
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            double scale = 1.0;
                            return GestureDetector(
                              onTapDown: (_) => setState(() => scale = 0.95),
                              onTapUp: (_) => setState(() => scale = 1.0),
                              onTapCancel: () => setState(() => scale = 1.0),
                              onTap: () => _openUrl(app.detailsUrl),
                              child: AnimatedScale(
                                scale: scale,
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOut,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: CachedImage(
                                        url: app.iconUrl,
                                        width: itemSize,
                                        height: itemSize,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: itemSize,
                                      child: Text(
                                        app.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12 * scaleFactor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: buttonWidth,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _openUrl(app.detailsUrl),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.black.withOpacity(
                                            0.35,
                                          ),
                                          elevation: 6,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color.fromARGB(
                                                  255,
                                                  0,
                                                  207,
                                                  255,
                                                ), // Neon Blue
                                                Color.fromARGB(
                                                  255,
                                                  255,
                                                  0,
                                                  127,
                                                ), // Electric Pink
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                offset: const Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.download_rounded,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Download',
                                                  style: TextStyle(
                                                    fontSize: buttonFontSize,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary,
                                                    letterSpacing: 0.5,
                                                    decoration:
                                                        TextDecoration.none,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshApps,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth = constraints.maxWidth;
              final double iconSize = screenWidth < 400 ? 74 : 84;
              final double fontSize = screenWidth < 400 ? 12 : 14;
              final double buttonFontSize = screenWidth < 400 ? 12 : 14;
              final double scaleFactor = MediaQuery.textScaleFactorOf(
                context,
              ).clamp(1.0, 1.3);
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: apps.length,
                itemBuilder: (context, i) {
                  final app = apps[i];
                  return GestureDetector(
                    onTap: () => _openUrl(app.detailsUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Blurred background image
                          Positioned.fill(
                            child: CachedImage(
                              url: app.iconUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Blur overlay
                          // After
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                20,
                              ), // same radius as parent container
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(
                                  sigmaX: 14,
                                  sigmaY: 14,
                                ),
                                child: Container(
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),

                          // Fade gradient
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Ad badge
                                // Align(
                                //   alignment: Alignment.topLeft,
                                //   child: Container(
                                //     padding: const EdgeInsets.symmetric(
                                //         horizontal: 6, vertical: 2),
                                //     decoration: BoxDecoration(
                                //       color: Colors.orange,
                                //       borderRadius: BorderRadius.circular(4),
                                //     ),
                                //     // child: const Text(
                                //     //   'Ad',
                                //     //   style: TextStyle(
                                //     //     color: Colors.white,
                                //     //     fontSize: 10,
                                //     //     fontWeight: FontWeight.bold,
                                //     //   ),
                                //     // ),
                                //   ),
                                // ),
                                const SizedBox(height: 8),
                                // Main icon
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: CachedImage(
                                    url: app.iconUrl,
                                    width: iconSize,
                                    height: iconSize,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // App name
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    app.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Download button
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        ui.Color.fromARGB(255, 17, 45, 221),
                                        ui.Color.fromARGB(255, 70, 148, 226),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.shade700.withOpacity(
                                          0.5,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(30),
                                      onTap: () => _openUrl(app.detailsUrl),
                                      highlightColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.download,
                                              size: 18,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Download',
                                              style: TextStyle(
                                                fontSize: 10 * scaleFactor,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                                letterSpacing: 0.5,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
