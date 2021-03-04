import 'package:app/youtube_playlist_api.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:filesize/filesize.dart';

class PlaylistDownload extends StatefulWidget {
  @override
  _PlaylistDownloadState createState() => _PlaylistDownloadState();
}

class _PlaylistDownloadState extends State<PlaylistDownload> {
  Map data = {};
  Map trackData;
  YoutubePlaylistAPI api;
  int length;
  List<Map> tracks = [];
  bool syncStarted = false;
  bool gotPermission = false;
  bool isTrack;

  void getTracks() async {
    Map data;

    this.syncStarted = true;
    print(this.length);
    for (var offset = 0; offset < this.length; offset++) {
      print('got in');
      data = await this.api.getTrack(offset);
      print(data);
      if (data != null) {
        data['progress'] = 0.0;
        data['progress_indicator'] = ' ';
        data['downloaded'] = false;
        data['is_downloading'] = false;
        setState(() {
          this.tracks.add(data);
        });
      }
    }
  }

  Future<void> downloadFile(int index, bool isMp3) async {
    if (await Permission.storage.request().isGranted &&
        !this.tracks[index]['downloaded'] &&
        !this.tracks[index]['is_downloading']) {
      String savePath = await getFilePath(this.tracks[index]['title'], isMp3);
      print('Download path is: $savePath');

      Dio dio = Dio();

      this.tracks[index]['is_downloading'] = true;

      Map<String, String> queryData = {'artist': this.tracks[index]['artist']};
      String targetUrl = this.tracks[index]['download_url'];
      if (isMp3) {
        queryData['audio_url'] = this.tracks[index]['audio_url'];
        targetUrl = '${this.api.apiEndpoint}/convert';
      }

      print(queryData);
      await dio.download(
        targetUrl,
        savePath,
        onReceiveProgress: (rcv, total) {
          //print('received: ${rcv.toStringAsFixed(0)} out of total: ${total.toStringAsFixed(0)}');

          setState(() {
            this.tracks[index]['progress'] = rcv / total;
            this.tracks[index]['progress_indicator'] =
                '${filesize(rcv)} / ${filesize(total)}';
            this.tracks[index]['total'] = filesize(total);
            this.tracks[index]['received'] = filesize(rcv);
          });
        },
        deleteOnError: true,
        queryParameters: queryData,
      ).then((_) {
        setState(() {
          this.tracks[index]['is_downloading'] = false;
          if (this.tracks[index]['progress'] == 1) {
            this.tracks[index]['progress_indicator'] = 'Done!';
            this.tracks[index]['downloaded'] = true;
          }
        });
      });
    }
  }

  Future<String> getFilePath(String uniqueFileName, bool isMp3) async {
    String path;

    String extension = isMp3 ? 'mp3' : 'mp4';
    uniqueFileName = uniqueFileName.replaceAll(r'/', '');
    path = '/storage/emulated/0/Download/$uniqueFileName.$extension';

    return path;
  }

  @override
  Widget build(BuildContext context) {
    this.data = ModalRoute.of(context).settings.arguments;
    this.api = YoutubePlaylistAPI(url: this.data['playlist_url']);
    this.length = data['length'];
    this.isTrack = data['isTrack'];
    this.trackData = data['trackData'];

    if (!this.syncStarted && !this.isTrack) this.getTracks();

    if (this.isTrack && this.tracks.length == 0) {
      this.trackData['progress'] = 0.0;
      this.trackData['progress_indicator'] = ' ';
      this.trackData['downloaded'] = false;
      this.trackData['is_downloading'] = false;
      this.tracks.add(this.trackData);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Youtube Playlist Downloader'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number of Loaded Tracks: ${this.tracks.length} / ${this.length}',
                ),
                SizedBox(
                  height: 15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    RaisedButton(
                      onPressed: () async {
                        for (var i = 0; i < this.length; i++) {
                          print('current track: $i');
                          while (this.tracks.length <= i) {
                            print('${this.tracks.length} $i');
                            await Future.delayed(Duration(seconds: 5));
                          }

                          await this.downloadFile(
                            i,
                            false,
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.file_download),
                          SizedBox(
                            width: 1,
                          ),
                          Text('Download All in MP4'),
                        ],
                      ),
                    ),
                    RaisedButton(
                      onPressed: () async {
                        for (var i = 0; i < this.length; i++) {
                          print('current track: $i');
                          while (this.tracks.length <= i) {
                            print('${this.tracks.length} $i');
                            await Future.delayed(Duration(seconds: 5));
                          }

                          await this.downloadFile(
                            i,
                            true,
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.audiotrack),
                          SizedBox(
                            width: 1,
                          ),
                          Text('Download All in MP3'),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              NetworkImage(this.tracks[index]['thumbnail']),
                        ),
                        title: Text(this.tracks[index]['title']),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          LinearPercentIndicator(
                            width: 200,
                            lineHeight: 20.0,
                            percent: this.tracks[index]['progress'],
                            center:
                                Text(this.tracks[index]['progress_indicator']),
                            backgroundColor: Colors.grey,
                            progressColor: Colors.blue,
                          ),
                          IconButton(
                            icon: Icon(Icons.file_download),
                            onPressed: () {
                              this.downloadFile(
                                index,
                                false,
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.audiotrack),
                            onPressed: () {
                              setState(() {
                                this.tracks[index]['progress_indicator'] =
                                    'Converting';
                                this.downloadFile(
                                  index,
                                  true,
                                );
                              });
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
