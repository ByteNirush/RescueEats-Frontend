class Player {
  double x = 0.5;
  double size = 0.08;
  bool isInvincible = false;
  DateTime? invincibilityEnd;
  int animationFrame = 0;

  void updateInvincibility() {
    if (isInvincible && invincibilityEnd != null) {
      if (DateTime.now().isAfter(invincibilityEnd!)) {
        isInvincible = false;
        invincibilityEnd = null;
      }
    }
  }

  void activateInvincibility(Duration duration) {
    isInvincible = true;
    invincibilityEnd = DateTime.now().add(duration);
  }
}
