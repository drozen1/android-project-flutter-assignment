Dor Rozen
318965365
HW3

Ex.1
1. The class is used to implement the controller pattern is the SnappingSheetContent class.

In genral, controllers allow user interactions which can make changes the app.
They allow to not "lift the state up", as the State is still managed by the child.
They also allow having a complex API without having thousands of callbacks on the widget.
In snapping-sheet case you can control the Snapping Sheet using the SnappingSheetController and extract information from the sheet for example.
Also, you can listen to the changes, meaning you can do things onSnapStart, onSheetMoved & onSnapCompleted.

2. The parameter which control this behaviour is the snappingPositions parameter.

3. The InkWell works better for handling taps.
   For listening gestures without ink splashes is better to use GestureDetector.
# android-project-flutter-assignment
