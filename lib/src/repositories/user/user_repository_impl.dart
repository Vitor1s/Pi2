import 'dart:developer';
import 'dart:io';

import 'package:pi2/src/core/exceptions/auth_exception.dart';
import 'package:pi2/src/core/exceptions/repository_exception.dart';
import 'package:pi2/src/core/fp/either.dart';
import 'package:pi2/src/core/fp/nil.dart';
import 'package:pi2/src/core/rest_client/rest_client.dart';
import 'package:pi2/src/models/user_model.dart';
import 'package:pi2/src/repositories/user/user_repository.dart';
import 'package:dio/dio.dart';

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<Either<AuthException, String>> login({
    required String email,
    required String password,
  }) async {
    try {
      final Response(:data) = await _restClient.unAuth.post(
        '/auth',
        data: {'email': email, 'password': password},
      );

      log('Resposta da API de autenticação: $data');

      // Verifica se a resposta contém o campo access_token
      if (data is Map && data.containsKey('access_token')) {
        final accessToken = data['access_token'];
        if (accessToken is String) {
          return Success(accessToken);
        } else {
          log('Formato de token inválido: $accessToken');
          return Failure(
            const AuthError(
              message: 'Formato de resposta inválido do servidor',
            ),
          );
        }
      } else {
        log('Resposta não contém access_token: $data');
        return Failure(
          const AuthError(message: 'Resposta de autenticação inválida'),
        );
      }
    } on DioException catch (e, s) {
      if (e.response != null) {
        final Response(:statusCode) = e.response!;
        if (statusCode == HttpStatus.forbidden) {
          log('Login ou senha inválido login', error: e, stackTrace: s);
          return Failure(const AuthUnauthorizedException());
        }
      }
      log('Erro ao realizar login', error: e, stackTrace: s);
      return Failure(const AuthError(message: 'Erro ao realizar login'));
    } catch (e, s) {
      log('Erro inesperado durante o login', error: e, stackTrace: s);
      return Failure(AuthError(message: 'Erro não esperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<RepositoryException, UserModel>> me() async {
    try {
      final Response(:data) = await _restClient.auth.get('/me');
      return Success(UserModel.fromMap(data));
    } on DioException catch (e, s) {
      log('Erro ao buscar usuário logado', error: e, stackTrace: s);
      return Failure(
        const RepositoryException(message: 'Erro ao buscar usuário logado'),
      );
    } on ArgumentError catch (e, s) {
      log('Invalid JSON', error: e, stackTrace: s);
      return Failure(const RepositoryException(message: 'Invalid JSON'));
    }
  }

  @override
  Future<Either<RepositoryException, Nil>> registerAdmin(
    ({String email, String name, String password}) userData,
  ) async {
    try {
      await _restClient.unAuth.post(
        '/users',
        data: {
          'name': userData.name,
          'email': userData.email,
          'password': userData.password,
          'profile': 'ADM',
        },
      );
      return Success(nil);
    } on DioException catch (e, s) {
      log('Erro ao registrar usuário', error: e, stackTrace: s);
      return Failure(
        const RepositoryException(
          message: 'Erro ao registrar usuário adminstrador',
        ),
      );
    }
  }

  @override
  Future<Either<RepositoryException, List<UserModel>>> getEmployees(
    int barbeariapiId,
  ) async {
    try {
      final Response(:List data) = await _restClient.auth.get(
        '/users',
        queryParameters: {'barbeariapi_id': barbeariapiId},
      );
      final employees = data.map((e) => UserModelEmployee.fromMap(e)).toList();
      return Success(employees);
    } on DioException catch (e, s) {
      const errorMessage = 'Erro ao buscar colaboradores';
      log(errorMessage, error: e, stackTrace: s);
      return Failure(const RepositoryException(message: errorMessage));
    } on ArgumentError catch (e, s) {
      const errorMessage = 'Erro ao buscar colaboradores (Invalid JSON)';
      log(errorMessage, error: e, stackTrace: s);
      return Failure(const RepositoryException(message: errorMessage));
    }
  }

  @override
  Future<Either<RepositoryException, Nil>> registerADMAsEmployee(
    ({List<int> workHours, List<String> workDays}) userModel,
  ) async {
    try {
      final userModelResult = await me();

      final int userId;

      switch (userModelResult) {
        case Success(value: UserModel(:var id)):
          userId = id;
        case Failure(:var exception):
          return Failure(exception);
      }

      await _restClient.auth.put(
        '/users/$userId',
        data: {
          'work_days': userModel.workDays,
          'work_hours': userModel.workHours,
        },
      );

      return Success(nil);
    } on DioException catch (e, s) {
      const errorMessage = 'Erro ao inserir administrador como colaborador';
      log(errorMessage, error: e, stackTrace: s);
      return Failure(const RepositoryException(message: errorMessage));
    }
  }

  @override
  Future<Either<RepositoryException, Nil>> registerEmployee(
    ({
      int barbeariapiId,
      String email,
      String name,
      String password,
      List<String> workDays,
      List<int> workHours,
    })
    userModel,
  ) async {
    try {
      await _restClient.auth.post(
        '/users/',
        data: {
          'name': userModel.name,
          'email': userModel.email,
          'password': userModel.password,
          'work_days': userModel.workDays,
          'work_hours': userModel.workHours,
          'barbeariapi_id': userModel.barbeariapiId,
          'profile': 'EMPLOYEE',
        },
      );

      return Success(nil);
    } on DioException catch (e, s) {
      const errorMessage = 'Erro ao inserir colaborador';
      log(errorMessage, error: e, stackTrace: s);
      return Failure(const RepositoryException(message: errorMessage));
    }
  }
}
