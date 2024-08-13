import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc_state.dart';

import '../Controller/Bloc/Home Bloc/home_bloc.dart';
import '../Controller/Bloc/Home Bloc/home_bloc_event.dart';
import '../Services/Utility/random_color_generator.dart';

Widget userListWidget(HomeBlocState state) {
  return Padding(
    padding: const EdgeInsets.only(top: 2, bottom: 6, left: 10, right: 10),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
      ),
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: state.userIDs.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 5),
              child: TextButton(
                onPressed: () {
                  //as user selected title search turns of and keyboard goes away
                  context.read<HomeBloc>().add(ChangeSearchControllerText(''));
                  FocusManager.instance.primaryFocus?.unfocus();
                  if(state.userIDs.indexOf(state.selectedUserID) == index) {
                    context.read<HomeBloc>().add(SelectedUserID(''));
                  }
                  else {
                    context.read<HomeBloc>().add(SelectedUserID(state.userIDs[index]));
                  }
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateColor.resolveWith(
                          (states) => state.userIDs.indexOf(state.selectedUserID) == index
                          ? Colors.deepPurple.shade400
                          : Colors.deepPurple.shade50), //deepPurple.withOpacity(0.08)
                ),
                child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        //image
                        state.connection && (state.userImageUrls[index] != '' || state.userImageUrls[index].isNotEmpty) ?
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(state.userImageUrls[index]),
                        )
                            :
                        Container(
                          width: 35,
                          decoration: BoxDecoration(
                            color: getColorFromIndex(index),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Center(
                            child: Text(
                              state.userNames[index][0].toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 5,),
                        Text(
                          state.userNames[index],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: state.userIDs.indexOf(state.selectedUserID) == index
                                  ? Colors.white
                                  : Colors.black
                          ),
                        )
                      ],
                    )
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}