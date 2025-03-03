import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '茶室情報',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final WebViewController controller;
  bool isLoading = true;
  bool showWebView = false;
  List<Map<String, dynamic>> chashitsuData = [];
  String debugMessage = '';
  bool isInitialLoad = true;

  bool isKantoArea(String prefecture) {
    return prefecture == '東京都' || prefecture == '神奈川県';
  }

  Future<void> openMap(String address) async {
    final mapUrl = Uri.parse(
      'comgooglemaps://?q=${Uri.encodeComponent(address)}'
    );
    
    try {
      if (await canLaunchUrl(mapUrl)) {
        await launchUrl(mapUrl);
      } else {
        final webUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}'
        );
        await launchUrl(
          webUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('地図を開けませんでした: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final String scrapeScript = '''
    function getChashitsuInfo() {
      const result = [];
      const custom = document.querySelector('gds-boshu-custom');
      if (!custom) return JSON.stringify({error: 'No gds-boshu-custom found'});
      if (!custom.shadowRoot) return JSON.stringify({error: 'No shadowRoot found'});
      
      const shadow = custom.shadowRoot;
      const items = shadow.querySelectorAll('.Custom_item_ry2Np');
      if (!items.length) return JSON.stringify({error: 'No items found'});
      
      items.forEach(item => {
        const texts = Array.from(item.querySelectorAll('.Custom_item__middle__text_zskKQ'))
          .map(el => el.textContent.trim())
          .filter(Boolean);
        const dateEl = item.querySelector('.Custom_item__info_EveEw div');
        const date = dateEl ? dateEl.textContent.trim() : '';
        
        if (texts.length >= 3) {
          const info = {date: date};
          
          for (const text of texts) {
            if (text.includes('【') && text.includes('】')) {
              info.busho = text;
            } else if (text.includes('都') || text.includes('県') || text.includes('府')) {
              info.prefecture = text;
            } else if (text.includes('市') || text.includes('区') || text.includes('町') || text.includes('村')) {
              info.location = text;
            }
          }
          
          if (info.busho && info.prefecture && info.location) {
            result.push({
              busho: info.busho,
              prefecture: info.prefecture,
              location: info.location,
              date: info.date,
              text: texts.join(' ')
            });
          }
        }
      });
      
      return JSON.stringify(result.length > 0 ? result : {error: 'No valid data found'});
    }
    getChashitsuInfo();
  ''';

  Future<void> extractData() async {
    try {
      await Future.delayed(const Duration(seconds: 3));
      final result = await controller.runJavaScriptReturningResult(scrapeScript);
      final data = jsonDecode(result.toString());

      setState(() {
        if (data is List) {
          chashitsuData = List<Map<String, dynamic>>.from(data);
          chashitsuData.sort((a, b) {
            final isAKanto = isKantoArea(a['prefecture']);
            final isBKanto = isKantoArea(b['prefecture']);
            if (isAKanto && !isBKanto) return -1;
            if (!isAKanto && isBKanto) return 1;
            return 0;
          });
          debugMessage = 'データ取得成功: ${chashitsuData.length}件';
          if (!isInitialLoad) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${chashitsuData.length}件のデータを更新しました'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (data is Map && data.containsKey('error')) {
          debugMessage = 'エラー: ${data['error']}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラー: ${data['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        debugMessage = 'スクレイピングエラー: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } finally {
      setState(() {
        isLoading = false;
        isInitialLoad = false;
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
    });
    await controller.reload();
  }

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() => isLoading = true);
        },
        onPageFinished: (url) async {
          await extractData();
        },
        onWebResourceError: (error) {
          setState(() {
            debugMessage = 'ページ読み込みエラー: ${error.description}';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ページ読み込みエラー: ${error.description}'),
                backgroundColor: Colors.red,
              ),
            );
          });
        },
      ))
      ..loadRequest(
        Uri.parse('https://gamewith.jp/nobunaga-shutsujin/article/show/420796'),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('茶室情報'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          if (!isLoading) IconButton(
            icon: Icon(showWebView ? Icons.view_list : Icons.web),
            onPressed: () {
              setState(() {
                showWebView = !showWebView;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (showWebView)
            WebViewWidget(controller: controller)
          else
            chashitsuData.isEmpty
                ? const Center(child: Text('データを読み込んでいます...'))
                : ListView.builder(
                    itemCount: chashitsuData.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final item = chashitsuData[index];
                      final isKanto = isKantoArea(item['prefecture']);
                      return Card(
                        elevation: isKanto ? 2 : 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isKanto 
                            ? theme.colorScheme.primaryContainer
                            : null,
                        child: InkWell(
                          onTap: () {
                            openMap('${item['prefecture']}${item['location']}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['busho'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isKanto 
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item['prefecture']}${item['location']}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                    Icon(
                                      Icons.map,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['date'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: !isLoading ? FloatingActionButton(
        onPressed: refreshData,
        child: const Icon(Icons.refresh),
      ) : null,
    );
  }
}
