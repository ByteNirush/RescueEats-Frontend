import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/model/game/daily_login_reward.dart';
import 'package:rescueeats/core/services/daily_login_service.dart';

class DailyLoginModal extends StatefulWidget {
  final DailyLoginState loginState;
  final DailyLoginService loginService;
  final VoidCallback onRewardClaimed;

  const DailyLoginModal({
    super.key,
    required this.loginState,
    required this.loginService,
    required this.onRewardClaimed,
  });

  @override
  State<DailyLoginModal> createState() => _DailyLoginModalState();
}

class _DailyLoginModalState extends State<DailyLoginModal>
    with TickerProviderStateMixin {
  late AnimationController _modalController;
  late AnimationController _coinController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  bool _isClaimed = false;
  bool _isClaimingInProgress = false;
  List<ConfettiParticle> _confettiParticles = [];
  late List<DailyLoginReward> _rewards;

  @override
  void initState() {
    super.initState();

    // Modal entrance animation
    _modalController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _modalController,
      curve: Curves.easeOutBack,
    );

    _slideAnimation = CurvedAnimation(
      parent: _modalController,
      curve: Curves.easeOut,
    );

    // Coin bounce animation
    _coinController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _modalController.forward();

    _modalController.forward();

    _isClaimed = !widget.loginState.canClaimToday;
    _rewards = List.from(widget.loginState.rewards);
  }

  @override
  void dispose() {
    _modalController.dispose();
    _coinController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _generateConfetti() {
    final random = Random();
    _confettiParticles = List.generate(50, (index) {
      return ConfettiParticle(
        x: random.nextDouble(),
        y: -0.1,
        color: [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
        ][random.nextInt(6)],
        size: random.nextDouble() * 8 + 4,
        velocityX: (random.nextDouble() - 0.5) * 2,
        velocityY: random.nextDouble() * 2 + 2,
        rotation: random.nextDouble() * 2 * pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
      );
    });
  }

  Future<void> _claimReward() async {
    if (_isClaimed || _isClaimingInProgress) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isClaimingInProgress = true;
    });

    setState(() {
      _isClaimingInProgress = true;
    });

    try {
      final result = await widget.loginService.claimReward();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _isClaimed = true;

          // Update local rewards state to show checkmark
          final currentDay = widget.loginState.currentDay;
          if (currentDay > 0 && currentDay <= _rewards.length) {
            _rewards[currentDay - 1] = _rewards[currentDay - 1].copyWith(
              isClaimed: true,
              isCurrentDay: false,
            );
          }
        });

        // Start coin animation
        _coinController.forward();

        // Start confetti animation
        _generateConfetti();
        _confettiController.forward();

        // Notify parent to reload data
        widget.onRewardClaimed();

        // Auto close after 2.5 seconds
        await Future.delayed(const Duration(milliseconds: 2500));
        if (mounted) {
          _closeModal();
        }
      } else {
        final errorMessage = result['message'] ?? 'Failed to claim reward';

        // Check if already claimed today
        if (errorMessage.contains('Already claimed')) {
          // Just close the modal since they already claimed
          if (mounted) {
            setState(() {
              _isClaimed = true;
              _isClaimingInProgress = false;
            });
            await Future.delayed(const Duration(milliseconds: 500));
            _closeModal();
          }
        } else {
          // Show error message with retry option
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange.shade700,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _claimReward,
                ),
              ),
            );
          }
          if (mounted) {
            setState(() {
              _isClaimingInProgress = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _claimReward,
            ),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _isClaimingInProgress = false;
        });
      }
    }
  }

  void _closeModal() {
    _modalController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isClaimed,
      child: Material(
        color: Colors.black54,
        child: Stack(
          children: [
            // Close on tap outside (only if claimed)
            if (_isClaimed)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeModal,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),

            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_slideAnimation),
                  child: _buildModalContent(),
                ),
              ),
            ),
            if (_confettiController.isAnimating)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ConfettiPainter(
                        particles: _confettiParticles,
                        progress: _confettiController.value,
                      ),
                      size: MediaQuery.of(context).size,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalContent() {
    final currentDay = widget.loginState.currentDay;
    final currentReward = currentDay > 0 && currentDay <= _rewards.length
        ? _rewards[currentDay - 1]
        : _rewards[0];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      padding: const EdgeInsets.all(28),
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎁 Daily Login',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (_isClaimed)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _closeModal,
                  color: Colors.grey.shade700,
                  tooltip: 'Close',
                  iconSize: 28,
                )
              else
                const Icon(Icons.close, color: Colors.grey, size: 28),
            ],
          ),
          const SizedBox(height: 8),

          // Streak counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  '${widget.loginState.currentStreak} Day Streak',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 7-Day Reward Grid
          _buildRewardGrid(),

          const SizedBox(height: 24),

          // Current reward display
          if (!_isClaimed) ...[
            AnimatedBuilder(
              animation: _coinController,
              builder: (context, child) {
                final bounce = sin(_coinController.value * pi * 4) * 10;
                return Transform.translate(
                  offset: Offset(0, bounce),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFED4E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Today\'s Reward',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '🪙 ${currentReward.coins}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (currentReward.xp != null)
                          Text(
                            '+ ${currentReward.xp} XP',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Claim Button or Success Message
          if (!_isClaimed)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isClaimingInProgress ? null : _claimReward,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isClaimingInProgress
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Claim Reward',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You must claim to continue',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Reward Claimed! 🎉',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRewardGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        final reward = _rewards[index];
        return _buildRewardCard(reward);
      },
    );
  }

  Widget _buildRewardCard(DailyLoginReward reward) {
    Color borderColor;
    Color backgroundColor;
    Widget statusIcon;

    if (reward.isClaimed) {
      borderColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
      statusIcon = const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 20,
      );
    } else if (reward.isCurrentDay) {
      borderColor = AppColors.primary;
      backgroundColor = AppColors.primary.withOpacity(0.1);
      statusIcon = const Icon(Icons.star, color: AppColors.primary, size: 20);
    } else if (reward.isLocked) {
      borderColor = Colors.grey.shade300;
      backgroundColor = Colors.grey.shade100;
      statusIcon = const Icon(Icons.lock, color: Colors.grey, size: 20);
    } else {
      borderColor = Colors.grey.shade300;
      backgroundColor = Colors.white;
      statusIcon = const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: reward.isCurrentDay ? 3 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Day ${reward.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: reward.isLocked ? Colors.grey : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          statusIcon,
          const SizedBox(height: 4),
          Text(
            reward.isLocked ? '🔒' : '🪙',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 2),
          Text(
            reward.isLocked ? '???' : '${reward.coins}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: reward.isLocked ? Colors.grey : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// Confetti particle class
class ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double size;
  final double velocityX;
  final double velocityY;
  double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update() {
    x += velocityX * 0.01;
    y += velocityY * 0.01;
    rotation += rotationSpeed;
  }
}

// Confetti painter
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update particle position
      particle.update();

      // Apply gravity
      particle.y += progress * 5;

      final paint = Paint()
        ..color = particle.color.withOpacity(1 - progress)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(particle.x * size.width, particle.y * size.height);
      canvas.rotate(particle.rotation);

      // Draw confetti piece (rectangle or circle)
      if (particle.size > 6) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size / 2,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
