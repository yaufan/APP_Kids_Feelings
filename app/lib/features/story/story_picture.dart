import 'package:flutter/material.dart';

import '../../app/cloud.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/feelings.dart';
import '../../core/looks.dart';
import '../../core/stories.dart';

/// A little story's picture (4:3): the background, the things, the other
/// clouds and 小雨 (docs/art.md: props by middle x, bottom y and width).
/// [feeling] is 小雨's face (null: no feeling yet, a 「？」 over her head).
/// [helper] shows how the child helped: 棉棉 comes over (and hugs), or a
/// grown-up arrives.
class StoryPicture extends StatelessWidget {
  const StoryPicture({super.key, required this.story, this.feeling, this.helper});

  final Story story;
  final Feeling? feeling;
  final HelpWay? helper;

  /// A cloud's feet are this far up from the bottom of its box.
  static const _feet = 26 / 180;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: mallowBox(Colors.white, radius: 26),
          padding: const EdgeInsets.all(5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth, h = box.maxHeight;
              Widget cloud(Widget c, double x, double y, double cw, {Key? key}) {
                // The cloud's box is wider than the cloud itself.
                final width = cw * w * 1.3;
                return AnimatedPositioned(
                  key: key,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  left: x * w - width / 2,
                  width: width,
                  bottom: (1 - y) * h - width * .9 * _feet,
                  child: c,
                );
              }

              final (xx, xy, xw) = story.xiaoyu;
              final helping = helper != null;
              final hug = helper == HelpWay.hug || helper == HelpWay.share;
              final xiaoyuX = helping ? (xx < .5 ? xx + .06 : xx) : xx;
              return Stack(clipBehavior: Clip.hardEdge, children: [
                Positioned.fill(child: Art('stories/bg_${story.place.name}', fit: BoxFit.cover)),
                for (final p in story.props)
                  Positioned(left: (p.x - p.w / 2) * w, width: p.w * w, top: 0, bottom: (1 - p.y) * h, child: Art('stories/${p.art}', alignment: Alignment.bottomCenter)),
                for (final c in story.cast)
                  cloud(Cloud(kind: c.kind, feeling: c.feeling, tint: c.tint == null ? null : Color(c.tint!), flip: c.flip), c.x, c.y, c.w),
                if (helper == HelpWay.adult)
                  cloud(const Cloud(kind: CloudKind.grownup, tint: Color(0xFFFFDDBE), flip: true), xiaoyuX + xw * .95, xy, xw * 1.25, key: const ValueKey('grownup')),
                cloud(
                  Semantics(
                    key: const ValueKey('xiaoyu'),
                    label: '小雨',
                    child: Cloud(kind: CloudKind.xiaoyu, feeling: feeling, extras: feeling == null ? const {Extra.question: 1} : const {}),
                  ),
                  xiaoyuX,
                  xy,
                  xw,
                ),
                if (helping && helper != HelpWay.adult)
                  cloud(
                    Cloud(feeling: hug ? Feeling.calm : Feeling.happy, squash: hug ? .4 : 0),
                    xiaoyuX + (xiaoyuX < .55 ? 1 : -1) * xw * (hug ? .62 : .95),
                    xy,
                    xw * .92,
                    key: const ValueKey('mianmian-helper'),
                  ),
                if (helping)
                  Positioned(left: xiaoyuX * w - 18, top: (xy - xw * .95) * h - 10, width: 36, height: 34, child: const Bob(amount: 4, child: Art('calm/heart'))),
                Positioned(left: 0, right: 0, bottom: 0, height: 6, child: ColoredBox(color: Mallow.shade.withValues(alpha: .03))),
              ]);
            }),
          ),
        ),
      );
}
