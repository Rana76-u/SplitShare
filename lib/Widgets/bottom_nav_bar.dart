import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitshare_v3/Controller/Bloc/BottomBar%20Bloc/bottombar_event.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc_event.dart';
import 'package:splitshare_v3/View/Calculation/calculation_screen.dart';
import 'package:splitshare_v3/View/Info/info.dart';
import '../Controller/Bloc/BottomBar Bloc/bottombar_bloc.dart';
import '../Controller/Bloc/BottomBar Bloc/bottombar_state.dart';
import '../View/Home/home.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  Widget? _getPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        //todo: ho do I call Events of HomeBloc here?
      //error says that error: Undefined name 'context'.
        BlocProvider.of<HomeBloc>(context).add(InitStateEvent());
        return const HomePage();
      case 1:
        return const CalculationScreen();
      case 2:
        return const InfoPage();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BottomBarBloc(),
      child: Scaffold(
        body: Center(
          child: BlocBuilder<BottomBarBloc, BottomBarState>(
            builder: (context, state) {
              return _getPage(context, state.index) ?? const SizedBox();
            },
          ),
        ),
        bottomNavigationBar: BlocBuilder<BottomBarBloc, BottomBarState>(
          builder: (context, state) {
            return FlashyTabBar(
              animationCurve: Curves.linear,
              selectedIndex: state.index,
              iconSize: 30,
              showElevation: false,
              onItemSelected: (index) {
                context.read<BottomBarBloc>().add(BottomBarSelectedItem(index));
              },
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
                  icon: const Icon(Icons.group),
                  title: const Text('Trip'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
