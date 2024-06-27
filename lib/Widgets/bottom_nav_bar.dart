import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter/material.dart';
import 'package:splitshare_v3/Screens/Calculation/calculation_screen.dart';
import 'package:splitshare_v3/Screens/Info/info.dart';
import '../Screens/Home/home.dart';

// ignore: must_be_immutable
class BottomBar extends StatefulWidget {
  int bottomIndex = 0;
  BottomBar({super.key, required this.bottomIndex});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {

  int previousIndex = -1;

  Widget? check(){
    if(widget.bottomIndex == 0){
      previousIndex = 0;
      return const HomePage();
    }else if(widget.bottomIndex == 1){
      previousIndex = 1;
      return const CalculationScreen();//SearchPage(keyword: keyword,); //ShopHomePage
    }
    else if(widget.bottomIndex == 2){
      previousIndex = 1;
      return const InfoPage();//SearchPage(keyword: keyword,); //ShopHomePage
    }
    return null;
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Center(
        child: check(),
      ),
      //child: _options[widget.bottomIndex],
      bottomNavigationBar: FlashyTabBar(
        animationCurve: Curves.linear,
        selectedIndex: widget.bottomIndex,
        iconSize: 30,
        showElevation: false, // use this to remove appBar's elevation
        onItemSelected: (index) => setState(() {
          widget.bottomIndex = index;
        }),
        items: [
          FlashyTabBarItem(
            icon: const Icon(Icons.home_rounded),
            title: const Text('Home'),
          ),
          FlashyTabBarItem(
            icon: const Icon(Icons.calculate),
            title: const Text('Splits'),
          ),
          FlashyTabBarItem(
            icon: const Icon(Icons.info_outline_rounded),
            title: const Text('Info'),
          ),
        ],
      ),
    );
  }
}