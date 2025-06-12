import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Sub-Domain Finder'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
String status = '';

class _MyHomePageState extends State<MyHomePage> {
  void extreamcheck(durl) async {
    List todata = [];
    try {
      final ssldata =
          await http.get(Uri.parse('https://crt.sh/?q=${durl}&output=json'));
      if (ssldata.statusCode == 200) {
        for (var dataa in jsonDecode(ssldata.body)) {
          print(dataa['common_name']);
          bool isDomainInList = todata.any((entry) => entry == dataa['common_name']);
          todata.add(dataa['common_name'].toString());
          if(!isDomainInList){
            try {
            final addresses =
                await InternetAddress.lookup(dataa['common_name']);
            if (addresses.length > 0) {
              for (var address in addresses) {
                bool isActiver = await isUrlActive(
                    'http://${dataa['common_name'].toString()}');
                setState(() {
                  data.add([
                    dataa['common_name'],
                    address.address.toString(),
                    address.type.toString(),
                    isActiver.toString(),
                  ]);
                });
              }
            }
          } catch (e) {
            print('goot error');
          }
          }
        }
      } else {
        print('check internet connection');
      }
      setState(() {
                    status = 'SEARCH COMPLETE ..';
                  });
    } catch (e) {}
  }

  Future<bool> isUrlActive(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isValidDomain(String domain) async {
    final domainRegex = RegExp(
      r'^(?!\-)([a-zA-Z0-9\-]{1,63}\.)+[a-zA-Z]{2,}$',
      caseSensitive: false,
    );

    if (!domainRegex.hasMatch(domain)) {
      setState(() {
        vdmn = false;
      });
      return false;
    } else {
      setState(() {
        vdmn = true;
      });
      return true;
    }
  }

  bool vdmn = false;

  Future<void> performDnsLookup(String domain) async {
    String jsonString = await rootBundle.loadString('assets/sub.json');
    var jsonData = jsonDecode(jsonString);

    for (String dns in jsonData['subdomains']) {
      try {
        final addresses = await InternetAddress.lookup('$dns.$domain');
        for (var address in addresses) {
          bool isActive = await isUrlActive('http://$dns.$domain');
          setState(() {
            data.add([
              '$dns.$domain',
              address.address.toString(),
              address.type.toString(),
              isActive.toString(),
            ]);
          });
        }
      } catch (e) {
        // Handle lookup error
      }
    }
    setState(() {
                    status = 'SEARCH COMPLETE ..';
                  });
  }

  TextEditingController domaininput = TextEditingController();
  List<List<String>> data = [
    ['blog.google.com', '125.465.5464.5465', 'IPv4', 'true'],
    ['blog.google.com', '125.465.5464.5465', 'IPv4', 'true'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Domain Checker',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: domaininput,
              onChanged: (value) async => await isValidDomain(value),
              decoration: InputDecoration(
                hintText: 'Enter a domain (e.g., google.com)',
                suffixIcon: Icon(
                  vdmn ? Icons.thumb_up : Icons.thumb_down,
                  color: vdmn ? Colors.green : Colors.red,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    status = 'PLEASE WAIT ..';
                  });
                  data = [];
                  if (await isValidDomain(domaininput.text)) {
                    performDnsLookup(domaininput.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Check Subdomains (Recomended)'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    status = 'PLEASE WAIT ..';
                  });
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Exream search'),
                      content: Text('1. Using SSL certificates to find subdomains.\n2. You might use bandwidth and take more time.\n3. Wait Patently and result might include duplicate entries. '),
                      actions: [
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.check))
                      ],
                    ),
                  );
                  data = [];
                  if (await isValidDomain(domaininput.text)) {
                    extreamcheck(domaininput.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Extreame Check'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              status,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Results',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data[index][0],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('IP: ${data[index][1]}'),
                          Text('${data[index][2]}'),
                          Text('Active: ${data[index][3]}'),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
