import 'package:pi2/src/core/exceptions/service_exception.dart';
import 'package:pi2/src/core/fp/either.dart';
import 'package:pi2/src/core/fp/nil.dart';
import 'package:pi2/src/repositories/user/user_repository.dart';
import 'package:pi2/src/services/user_login/user_login_service.dart';
import 'package:pi2/src/services/user_register_adm/user_service_adm.dart';

final class UserRegisterServiceADMImpl implements UserRegisterServiceADM {
  UserRegisterServiceADMImpl({
    required UserRepository userRepository,
    required UserLoginService userService,
  })  : _userRepository = userRepository,
        _userService = userService;

  final UserRepository _userRepository;
  final UserLoginService _userService;

  @override
  Future<Either<ServiceException, Nil>> execute(
    ({String name, String email, String password}) userData,
  ) async {
    final result = await _userRepository.registerAdmin(userData);

    switch (result) {
      case Success():
        return _userService.execute(
          email: userData.email,
          password: userData.password,
        );
      case Failure(:final exception):
        return Failure(ServiceException(message: exception.message));
    }
  }
}
