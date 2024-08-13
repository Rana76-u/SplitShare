import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Controller/Bloc/Home Bloc/home_bloc.dart';
import '../Controller/Bloc/Home Bloc/home_bloc_event.dart';
import '../Controller/Bloc/Home Bloc/home_bloc_state.dart';

Widget searchWidget(BuildContext context, HomeBlocState state) {

  return Column(
    children: [
      // Search TextField
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50)
          ),
          child: SizedBox(
            height: 40,
            child: TextField(
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: const BorderSide(
                    color: Colors.black,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: const BorderSide(
                    color: Colors.grey,
                  ),
                ),
                //InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(left: 15),
                //focusedBorder: InputBorder.none,
                //enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: "Search Events . . .",
                hintStyle: TextStyle(
                  fontSize: 13.0,
                  color: Colors.grey.shade500,
                ),
                suffixIcon: state.searchController.text.isNotEmpty
                    ? GestureDetector(
                    onTap: () {
                      //setState(() {});
                      context
                          .read<HomeBloc>()
                          .add(ChangeSearchControllerText(''));
                    },
                    child: Icon(
                      Icons.cancel,
                      size: 15,
                      color: Colors.grey.shade400,
                    ))
                    : GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.search_rounded)),
              ),
              controller: state.searchController,
              onChanged: (value) {
                context.read<HomeBloc>().add(SelectedUserID(''));
              },
            ),
          ),
        ),
      ),
      //Search Loading
      state.isSearching
          ? LinearProgressIndicator(
        color: Colors.blue.shade100,
      )
          : const SizedBox(),
    ],
  );
}