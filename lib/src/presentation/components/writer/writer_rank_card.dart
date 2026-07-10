import 'package:flutter/material.dart';

import '../../../domain/models/user_model.dart';
import '../profile/premium_ranks_widget.dart';

class WriterRankCard extends StatelessWidget {
  const WriterRankCard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) => PremiumRanksWidget(user: user);
}
