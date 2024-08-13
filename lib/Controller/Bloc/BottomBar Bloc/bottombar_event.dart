
abstract class BottomBarEvent {}

class BottomBarSelectedItem extends BottomBarEvent {
  final int index;
  BottomBarSelectedItem(this.index);
}