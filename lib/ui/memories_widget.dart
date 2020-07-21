import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:photos/memory_service.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/memory.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/ui/video_widget.dart';
import 'package:photos/ui/zoomable_image.dart';
import 'package:photos/utils/date_time_util.dart';

class MemoriesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Memory>>(
      future: MemoryService.instance.getMemories(),
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data.length == 0) {
          return Container();
        } else {
          return _buildMemories(snapshot.data);
        }
      },
    );
  }

  Widget _buildMemories(List<Memory> memories) {
    final collatedMemories = _collateMemories(memories);
    final memoryWidgets = List<Widget>();
    for (final memories in collatedMemories) {
      memoryWidgets.add(MemoryWidget(memories: memories));
    }
    return Row(children: memoryWidgets);
  }

  List<List<Memory>> _collateMemories(List<Memory> memories) {
    final yearlyMemories = List<Memory>();
    final collatedMemories = List<List<Memory>>();
    for (int index = 0; index < memories.length; index++) {
      if (index > 0 &&
          !_areMemoriesFromSameYear(memories[index - 1], memories[index])) {
        final collatedYearlyMemories = List<Memory>();
        collatedYearlyMemories.addAll(yearlyMemories);
        collatedMemories.add(collatedYearlyMemories);
        yearlyMemories.clear();
      }
      yearlyMemories.add(memories[index]);
    }
    if (yearlyMemories.isNotEmpty) {
      collatedMemories.add(yearlyMemories);
    }
    return collatedMemories;
  }

  bool _areMemoriesFromSameYear(Memory first, Memory second) {
    var firstDate =
        DateTime.fromMicrosecondsSinceEpoch(first.file.creationTime);
    var secondDate =
        DateTime.fromMicrosecondsSinceEpoch(second.file.creationTime);
    return firstDate.year == secondDate.year;
  }
}

class MemoryWidget extends StatelessWidget {
  const MemoryWidget({
    Key key,
    @required this.memories,
  }) : super(key: key);

  final List<Memory> memories;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return FullScreenMemory(memories);
            },
          ),
        );
      },
      child: Container(
        width: 100,
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ClipOval(
                child: Container(
                  width: 76,
                  height: 76,
                  child: Hero(
                    tag: "memories" + memories[0].file.tag(),
                    child: ThumbnailWidget(memories[0].file),
                  ),
                ),
              ),
              Padding(padding: EdgeInsets.all(2)),
              _getTitle(memories[0]),
            ],
          ),
        ),
      ),
    );
  }

  Text _getTitle(Memory memory) {
    final present = DateTime.now();
    final then = DateTime.fromMicrosecondsSinceEpoch(memory.file.creationTime);
    final diffInYears = present.year - then.year;
    if (diffInYears == 1) {
      return Text("1 year ago");
    } else {
      return Text(diffInYears.toString() + " years ago");
    }
  }
}

class FullScreenMemory extends StatefulWidget {
  final List<Memory> memories;

  FullScreenMemory(this.memories, {Key key}) : super(key: key);

  @override
  _FullScreenMemoryState createState() => _FullScreenMemoryState();
}

class _FullScreenMemoryState extends State<FullScreenMemory> {
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        child: new Swiper(
          itemBuilder: (BuildContext context, int index) {
            final file = widget.memories[index].file;
            return Stack(children: [
              file.fileType == FileType.image
                  ? ZoomableImage(
                      file,
                      tagPrefix: "memories",
                    )
                  : VideoWidget(file, tagPrefix: "memories"),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                child: Text(
                  getFormattedDate(
                      DateTime.fromMicrosecondsSinceEpoch(file.creationTime)),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ]);
          },
          itemCount: widget.memories.length,
          pagination: new SwiperPagination(
              builder: DotSwiperPaginationBuilder(activeColor: Colors.white)),
          control: new SwiperControl(),
          loop: false,
          autoplay: true,
          autoplayDelay: 5000,
          autoplayDisableOnInteraction: true,
          layout: SwiperLayout.DEFAULT,
        ),
      ),
    );
  }
}