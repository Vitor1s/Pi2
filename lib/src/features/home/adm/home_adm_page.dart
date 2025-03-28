import 'dart:developer';

import 'package:pi2/src/core/constants/constants.dart';
import 'package:pi2/src/core/providers/application_providers.dart';
import 'package:pi2/src/core/ui/barbeariapi_icons.dart';
import 'package:pi2/src/core/ui/widgets/barbeariapi_loader.dart';
import 'package:pi2/src/features/home/adm/home_adm_state.dart';
import 'package:pi2/src/features/home/adm/home_adm_vm.dart';
import 'package:pi2/src/features/home/adm/widgets/home_employee_tile.dart';
import 'package:pi2/src/features/home/widgets/home_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeADMPage extends ConsumerWidget {
  const HomeADMPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeADMVMProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).pushNamed('/employee/register');
          ref.invalidate(getMeProvider);
          ref.invalidate(homeADMVMProvider);
        },
        shape: const CircleBorder(),
        backgroundColor: AppColors.brown,
        child: const CircleAvatar(
          backgroundColor: Colors.white,
          maxRadius: 12,
          child: Icon(BarbeariapiIcons.addEmployee, color: AppColors.brown),
        ),
      ),
      body: homeState.when(
        loading: () => const BarbeariapiLoader(),
        error: (e, s) {
          log('UI Erro ao buscar colaboradores', error: e, stackTrace: s);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Erro ao carregar página.',
                  style: TextStyle(color: Colors.black),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(homeADMVMProvider.notifier).logout();
                  },
                  child: const Text('Deslogar'),
                ),
              ],
            ),
          );
        },
        data:
            (HomeADMState data) => CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: HomeHeader()),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: data.employees.length,
                    (context, index) =>
                        HomeEmployeeTile(employee: data.employees[index]),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
