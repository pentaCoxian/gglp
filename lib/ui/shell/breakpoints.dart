import 'package:flutter/widgets.dart';

import '../plus/plus.dart';

/// Desktop breakpoint: anchored navigation panel, capped feed
/// column, 360px activity panel.
bool isDesktopWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= PlusDims.desktopMinWidth;
