import 'package:flutter/material.dart';

Widget spendingCard(double perPerson, double total) {
  return SizedBox(
    width: double.infinity,
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        //mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Spending',
                style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.bold,
                    fontSize: 25
                ),
              ),
              Text(
                'Per Person: ${perPerson.toStringAsFixed(2)}/-',
                style: const TextStyle(
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${total.toStringAsFixed(0)}/-',
            style: const TextStyle(
                fontFamily: 'Urbanist',
                fontWeight: FontWeight.bold,
                fontSize: 35
            ),
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}
