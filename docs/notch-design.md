# Native notch integration

Adapted from the supplied September 18 React prototype: inset circular status icon, two-level message hierarchy, actual shortcut keycaps, repeat count, neutral practice state, permission errors and a non-notched floating pill.

The SwiftUI surface uses a centered animatable silhouette with curved top shoulders and preserved lower corner radii. Content is clipped to that same silhouette and remains full-size. Entrance is 220 ms and exit 180 ms using the prototype's (0.32, 0.72, 0, 1) curve. Updates replace content immediately and extend the existing lifetime; identical sent shortcuts increment a count. Reduce Motion fixes the silhouette at its final size and uses a 120 ms fade.

The panel attaches to the physical notch's auxiliary-area midpoint. It ignores mouse input and never delays gesture execution. Success means the shortcut events were posted, not proof that the target app completed an action. No simulated Safari recipient, camera data or metrics are copied from the prototype.

The supplied Hand3D component consists of CSS segments and transforms, not an articulated model asset. It is not included in the native utility. A genuine 3D guide remains separate work requiring a suitable model and a finite, replayable demonstration.
