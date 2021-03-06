import 'package:auto_route/auto_route.dart';
import 'package:flushbar/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localy/application/menu/menu_actor/menu_actor_bloc.dart';
import 'package:localy/presentation/core/pages/menu_builder/menu_builder_overview/widgets/menu_builder_overview_body_widget.dart';
import 'package:localy/presentation/core/routes/router.gr.dart';

class MenuBuilderOverviewPage extends StatelessWidget {
  const MenuBuilderOverviewPage({
    Key key,
    @required this.storeID,
  }) : super(key: key);
  final String storeID;

  @override
  Widget build(BuildContext context) {
    return BlocListener<MenuActorBloc, MenuActorState>(
      listener: (BuildContext context, state) {
        state.maybeMap(
          deleteFailure: (state) {
            FlushbarHelper.createError(
                duration: const Duration(seconds: 5),
                message: state.menuFailure.map(
                  unexpected: (_) =>
                      'Unexpected error occurred while deleting, please contact support.',
                  insufficientPermission: (_) => 'Insufficient permissions ❌',
                  unableToUpdate: (_) => 'Impossible error',
                ));
          },
          orElse: () {},
        );
      },
      child: Scaffold(
        body: MenuBuilderOverviewBodyWidget(
          storeID: storeID,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.navigator.pushMenuBuilderFormPage(
              storeID: storeID,
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
