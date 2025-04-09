import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel_slider;

class CarouselImage extends StatefulWidget {
  final List<String> imageLinks;

  const CarouselImage({
    super.key,
    required this.imageLinks,
  });

  @override
  State<CarouselImage> createState() => _CarouselImageState();
}

class _CarouselImageState extends State<CarouselImage> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            carousel_slider.CarouselSlider(
              items: widget.imageLinks.map((link) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.all(10),
                  child: Image.network(link, fit: BoxFit.contain),
                );
              }).toList(),
              options: carousel_slider.CarouselOptions(
                  height: 400,
                  enableInfiniteScroll: false,
                  viewportFraction: 1,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _current = index;
                    });
                  }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.imageLinks.asMap().entries.map(
                (e) {
                  return Container(
                    // onTap: () => carousel_slider.CarouselSlider.of(context)?.animateToPage(e.key),
                    // child: Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white
                          .withOpacity(_current == e.key ? 0.9 : 0.4),
                      //_current == e.key ? Colors.blue : Colors.grey,
                    ),
                    // ),
                  );
                },
              ).toList(),
            ),
          ],
        )
      ],
    );
  }
}
