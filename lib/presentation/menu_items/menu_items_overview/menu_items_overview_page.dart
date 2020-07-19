import 'package:auto_route/auto_route.dart';
import 'package:flushbar/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localy/application/menu_item/menu_item_actor/menu_item_actor_bloc.dart';
import 'package:localy/application/menu_item/menu_item_watcher/menu_item_watcher_bloc.dart';
import 'package:localy/injection.dart';
import 'package:localy/presentation/core/routes/manager_router.gr.dart';
import 'package:localy/presentation/menu_items/menu_items_overview/widgets/menu_items_overview_body_widget.dart';

class MenuItemsOverviewPage extends StatelessWidget {
  final String menuID;

  const MenuItemsOverviewPage({
    Key key,
    @required this.menuID,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MenuItemActorBloc>(
          create: (context) => getIt<MenuItemActorBloc>(),
        ),
        BlocProvider<MenuItemWatcherBloc>(
          create: (context) => getIt<MenuItemWatcherBloc>()
            ..add(
              MenuItemWatcherEvent.watchAllStarted(menuID),
            ),
        ),
      ],
      child: BlocListener<MenuItemActorBloc, MenuItemActorState>(
          listener: (BuildContext context, state) {
            state.maybeMap(
              deleteFailure: (state) {
                FlushbarHelper.createError(
                    duration: const Duration(seconds: 5),
                    message: state.menuItemFailure.map(
                      unexpected: (_) =>
                          'Unexpected error occurred while deleting, please contact support.',
                      insufficientPermission: (_) =>
                          'Insufficient permissions ❌',
                      unableToUpdate: (_) => 'Impossible error',
                    ));
              },
              orElse: () {},
            );
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Menu Items"),
            ),
            body: MenuItemsOverviewBodyWidget(menuID: menuID),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                ExtendedNavigator.of(context).pushNamed(
                  ManagerRoute.menuItemsFormPage,
                  arguments: MenuItemsFormPageArguments(
                    editedMenuItem: null,
                    menuID: menuID,
                  ),
                );
              },
              child: Icon(Icons.add),
            ),
          )),
    );
  }
}
