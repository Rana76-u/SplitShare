class CalculationAPI {
  Map<String, double> sortAMap(Map<String, double> givenMap, double perPerson) {
    // Subtract perPerson from each value
    givenMap = givenMap.map((key, value) => MapEntry(key, (value - perPerson).abs() ));

    // Sort the map and update it in place
    givenMap = Map.fromEntries(
        givenMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
    );

    return givenMap;
  }

}