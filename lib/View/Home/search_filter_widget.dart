import 'package:flutter/material.dart';

import '../../Controller/Bloc/Home Bloc/home_bloc_state.dart';
import '../../Widgets/internet_checker_widget.dart';
import '../../Widgets/search.dart';
import '../../Widgets/user_list.dart';

Widget searchAndFilterWidget(BuildContext context, HomeBlocState state) {
  return Column(
    children: [
      // Search TextField
      searchWidget(context, state),

      //Users
      userListWidget(state),

      internetCheckerWidget(state),
    ],
  );
}