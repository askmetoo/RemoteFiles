import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/shared.dart';

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _version;
  bool _isLatestVersion;
  Map<dynamic, dynamic> _latestVersion;

  Future<Map<dynamic, dynamic>> _getLatestVersion() async {
    int convertTimeStringToInt(String publishedAt) {
      var timeString = "";
      for (int i = 0; i < publishedAt.length; i++) {
        if (i != 4 && i != 7 && i != 10 && i != 13 && i != 16 && i != 19) {
          timeString += publishedAt[i];
        }
      }
      return int.parse(timeString);
    }

    var result = await http.get(
      Uri.encodeFull(
        "https://api.github.com/repos/niklas-8/RemoteFiles/releases",
      ),
    );
    var content = json.decode(result.body);
    int latestIndex = 0;
    int latestTime =
        convertTimeStringToInt(content[latestIndex]["published_at"]);
    try {
      for (int i = 0; i < content.length; i++) {
        int time = convertTimeStringToInt(content[i]["published_at"]);
        if (time > latestTime) {
          latestTime = time;
          latestIndex = i;
        }
      }
      return content[latestIndex];
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text("Could not launch $url"),
        ),
      );
    }
  }

  Widget _buildButton(
    BuildContext context, {
    @required IconData iconData,
    @required String label,
    @required String url,
  }) {
    return RaisedButton.icon(
      color: Provider.of<CustomTheme>(context).isLightTheme(context)
          ? Colors.grey[200]
          : Colors.grey[850],
      elevation: 0,
      highlightElevation: 4,
      icon: Icon(iconData),
      label: Text(label),
      onPressed: () async {
        await _launchUrl(url);
      },
    );
  }

  @override
  void initState() {
    PackageInfo.fromPlatform().then((packageInfo) {
      _version = packageInfo.version;
      _getLatestVersion().then((latestVersion) async {
        _latestVersion = latestVersion;
        _isLatestVersion = _version == latestVersion["tag_name"];
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        brightness: Provider.of<CustomTheme>(context).isLightTheme(context)
            ? Brightness.light
            : Brightness.dark,
        backgroundColor: Theme.of(context).bottomAppBarColor,
        leading: Padding(
          padding: EdgeInsets.all(7),
          child: CustomIconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Text("About", style: TextStyle(fontSize: 19)),
        titleSpacing: 4,
        elevation: 2,
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        children: <Widget>[
          SizedBox(height: 16),
          Image.asset("assets/app_icon_bg.png", height: 86),
          SizedBox(height: 6),
          Text(
            "RemoteFiles",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 5),
          Text(
            _version ?? "Version unknown",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).hintColor,
            ),
          ),
          SizedBox(height: 14),
          Padding(
            padding: EdgeInsets.all(10),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              children: <Widget>[
                _buildButton(
                  context,
                  iconData: MdiIcons.githubCircle,
                  label: "GitHub",
                  url: "https://github.com/niklas-8/RemoteFiles",
                ),
                _buildButton(
                  context,
                  iconData: Icons.link,
                  label: "Website",
                  url: "https://niklas-8.github.io/RemoteFiles",
                ),
                _buildButton(
                  context,
                  iconData: MdiIcons.googlePlay,
                  label: "Google PlayStore",
                  url:
                      "https://play.google.com/store/apps/details?id=com.niklas8.remotefiles",
                ),
              ],
            ),
          ),
          Divider(),
          Column(
            children: <Widget>[
              ListTile(
                leading: _isLatestVersion == null
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(
                            Provider.of<CustomTheme>(context)
                                    .isLightTheme(context)
                                ? Colors.black45
                                : Theme.of(context).iconTheme.color,
                          ),
                        ),
                      )
                    : Icon(_isLatestVersion ? Icons.done : Icons.error_outline),
                title: Text(
                  _isLatestVersion == null
                      ? "Checking for updates..."
                      : (_isLatestVersion
                          ? "You have the latest version"
                          : "You don't have the latest version"),
                ),
              ),
              if (_isLatestVersion != null)
                if (!_isLatestVersion)
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      children: <Widget>[
                        _buildButton(
                          context,
                          iconData: Icons.open_in_new,
                          label: "Update on PlayStore",
                          url:
                              "https://play.google.com/store/apps/details?id=com.niklas8.remotefiles",
                        ),
                        _buildButton(
                          context,
                          iconData: Icons.save_alt,
                          label: "Download from GitHub",
                          url: _latestVersion["assets"][0]
                              ["browser_download_url"],
                        ),
                      ],
                    ),
                  ),
            ],
          ),
          Divider(),
          ListTile(
            leading: Icon(MdiIcons.heartOutline),
            title: Text("If you like the app please consider rating it " +
                "on the Google PlayStore or donating via GitHub"),
          ),
        ],
      ),
    );
  }
}
