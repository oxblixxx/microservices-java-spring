package com.pm.authservice.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.pm.authservice.model.User;
import com.pm.authservice.repository.UserRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

  @Mock
  private UserRepository userRepository;

  @InjectMocks
  private UserService userService;

  @Test
  void findByEmailReturnsUserFromRepository() {
    User user = new User();
    user.setEmail("jane@example.com");
    user.setPassword("hashed-password");
    user.setRole("ADMIN");
    when(userRepository.findByEmail("jane@example.com"))
        .thenReturn(Optional.of(user));

    Optional<User> result = userService.findByEmail("jane@example.com");

    assertEquals(Optional.of(user), result);
    verify(userRepository).findByEmail("jane@example.com");
  }

  @Test
  void findByEmailReturnsEmptyWhenRepositoryFindsNothing() {
    when(userRepository.findByEmail("missing@example.com"))
        .thenReturn(Optional.empty());

    Optional<User> result = userService.findByEmail("missing@example.com");

    assertTrue(result.isEmpty());
    verify(userRepository).findByEmail("missing@example.com");
  }
}
