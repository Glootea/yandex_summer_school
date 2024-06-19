import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:yandex_summer_school/data/data_sources/local_database.dart';
import 'package:yandex_summer_school/data/providers/todo.dart';
import 'package:yandex_summer_school/screens/todo_edit/bloc/bloc.dart';
import 'package:yandex_summer_school/screens/todo_edit/to_do_edit.dart';
import 'package:yandex_summer_school/screens/todo_list/bloc/bloc.dart';
import 'package:yandex_summer_school/screens/todo_list/todo_list.dart';
import 'package:yandex_summer_school/theme/theme_bloc.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
        ),
      );
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      final localDatabase = AppDatabase();
      final todoProvider = ToDoProvider(localDatabase: localDatabase);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => BlocProvider(
              create: (context) => ToDoListBloc(ToDoProvider(localDatabase: localDatabase)),
              child: const TodoListScreen(),
            ),
            routes: [
              ShellRoute(
                builder: (context, state, child) => BlocProvider(
                  create: (context) => ToDoEditBloc(todoProvider: todoProvider),
                  child: child,
                ),
                routes: [
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) {
                      final idString = state.pathParameters['id'];
                      final data = state.uri.queryParameters['data']; // from deep link
                      if (idString == null) {
                        return const TodoListScreen();
                      }
                      final id = int.parse(idString);
                      return ToDoEditScreen(id: id, data: data);
                    },
                  ),
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const ToDoEditScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final brightness = PlatformDispatcher.instance.platformBrightness;
      final themeBloc = ThemeBloc(brightness);
      final app = MultiBlocProvider(
        providers: [
          BlocProvider.value(value: themeBloc),
        ],
        child: MaterialApp.router(
          theme: ThemeData(
              brightness: PlatformDispatcher.instance.platformBrightness,
              scaffoldBackgroundColor: themeBloc.state.backColors.primary),
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      );
      runApp(app);
    },
    (o, s) => logger.f(o, stackTrace: s),
  );
}

final Logger logger = Logger();
