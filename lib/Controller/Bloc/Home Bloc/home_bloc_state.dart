
import 'package:flutter/material.dart';

class HomeBlocState {
  final bool isSearching;
  final bool isLoading;
  final bool isBackupInProgress;
  final bool connection;

  final String selectedUserID;
  final String tripCode;

  final List<String> titles;
  final List<String> descriptions;
  final List<String> amounts;
  final List<String> times;
  final List<String> providerNames;
  final List<String> providerIDs;
  final List<String> docIDs;
  final List<dynamic> userNames;
  final List<dynamic> userImageUrls;
  final List<dynamic> userIDs;

  final TextEditingController searchController;

  HomeBlocState({
    required this.isSearching,
    required this.isLoading,
    required this.isBackupInProgress,
    required this.connection,
    required this.selectedUserID,
    required this.tripCode,
    required this.titles,
    required this.descriptions,
    required this.amounts,
    required this.times,
    required this.providerNames,
    required this.providerIDs,
    required this.docIDs,
    required this.userNames,
    required this.userImageUrls,
    required this.userIDs,
    required this.searchController,
});

  HomeBlocState copyWith({
    bool? isSearching,
    bool? isLoading,
    bool? isBackupInProgress,
    bool? connection,
    String? selectedUserID,
    String? tripCode,
    List<String>? titles,
    List<String>? descriptions,
    List<String>? amounts,
    List<String>? times,
    List<String>? providerNames,
    List<String>? providerIDs,
    List<String>? docIDs,
    List<dynamic>? userNames,
    List<dynamic>? userImageUrls,
    List<dynamic>? userIDs,
    TextEditingController? searchController,
  }) {
    return HomeBlocState(
      isSearching: isSearching ?? this.isSearching,
      isLoading: isLoading ?? this.isLoading,
      isBackupInProgress: isBackupInProgress ?? this.isBackupInProgress,
      connection: connection ?? this.connection,
      selectedUserID: selectedUserID ?? this.selectedUserID,
      tripCode: tripCode ?? this.tripCode,
      titles: titles ?? this.titles,
      descriptions: descriptions ?? this.descriptions,
      amounts: amounts ?? this.amounts,
      times: times ?? this.times,
      providerNames: providerNames ?? this.providerNames,
      providerIDs: providerIDs ?? this.providerIDs,
      docIDs: docIDs ?? this.docIDs,
      userNames: userNames ?? this.userNames,
      userImageUrls: userImageUrls ?? this.userImageUrls,
      userIDs: userIDs ?? this.userIDs,
      searchController: searchController ?? this.searchController
    );
  }
}