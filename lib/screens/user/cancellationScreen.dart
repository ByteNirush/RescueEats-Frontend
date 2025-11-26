import 'package:flutter/material.dart';

import 'package:rescueeats/core/utils/responsive_utils.dart';

class CancellationScreen extends StatelessWidget {
  const CancellationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Cancellations",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cancel_presentation_outlined,
              size: context.sizes.iconExtraLarge,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              "No cancellations yet",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
