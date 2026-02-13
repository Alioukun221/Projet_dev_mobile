import 'package:flutter/material.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/profile.dart';
import 'package:spendwise/services/auth_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  final bool isDarkMode;

  const ProfilePage({super.key, required this.isDarkMode});

  static const List<AvatarOption> avatars = [
    AvatarOption('avatar_1', Icons.person_rounded, Color(0xFF005EFF)),
    AvatarOption('avatar_2', Icons.face_rounded, Color(0xFF7B2FFF)),
    AvatarOption('avatar_3', Icons.face_2_rounded, Color(0xFF00D9B5)),
    AvatarOption('avatar_4', Icons.face_3_rounded, Color(0xFFE53935)),
    AvatarOption('avatar_5', Icons.face_4_rounded, Color(0xFFFF9800)),
    AvatarOption('avatar_6', Icons.face_5_rounded, Color(0xFF4CAF50)),
    AvatarOption('avatar_7', Icons.face_6_rounded, Color(0xFF2196F3)),
    AvatarOption('avatar_8', Icons.sentiment_very_satisfied_rounded, Color(0xFF9C27B0)),
    AvatarOption('avatar_9', Icons.emoji_emotions_rounded, Color(0xFFFF5722)),
    AvatarOption('avatar_10', Icons.mood_rounded, Color(0xFF009688)),
    AvatarOption('avatar_11', Icons.tag_faces_rounded, Color(0xFF673AB7)),
    AvatarOption('avatar_12', Icons.emoji_people_rounded, Color(0xFF3F51B5)),
  ];

  static AvatarOption getAvatarById(String id) {
    return avatars.firstWhere(
      (a) => a.id == id,
      orElse: () => avatars.first,
    );
  }

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Profile? _profile;
  bool _loading = true;
  String _selectedAvatar = 'avatar_1';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await AuthService().getProfile();
    if (data != null && mounted) {
      final profile = Profile.fromJson(data);
      setState(() {
        _profile = profile;
        _selectedAvatar = profile.avatar;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectAvatar(String avatarId) async {
    setState(() => _selectedAvatar = avatarId);
    await AuthService().updateProfile(avatar: avatarId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileUpdated),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDarkMode ? AppTheme.darkBgColor : const Color(0xFFF7F8FC);
    final cardColor = widget.isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A1D29);
    final subtextColor = widget.isDarkMode ? AppTheme.darkTextSecondaryColor : const Color(0xFF6B7280);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.profileTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Avatar display
                  _buildAvatarHeader(cardColor, textColor, subtextColor),
                  const SizedBox(height: 24),
                  // User info card
                  _buildInfoCard(cardColor, textColor, subtextColor, l10n),
                  const SizedBox(height: 24),
                  // Avatar picker
                  _buildAvatarPicker(cardColor, textColor, subtextColor, l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarHeader(Color cardColor, Color textColor, Color subtextColor) {
    final avatar = ProfilePage.getAvatarById(_selectedAvatar);
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [avatar.color, avatar.color.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: avatar.color.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(avatar.icon, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 16),
        Text(
          _profile?.displayName ?? '',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _profile?.email ?? '',
          style: TextStyle(
            fontSize: 14,
            color: subtextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Color cardColor, Color textColor, Color subtextColor, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.person_outline_rounded,
            l10n.displayName,
            _profile?.displayName ?? '',
            textColor,
            subtextColor,
          ),
          Divider(
            color: widget.isDarkMode ? AppTheme.darkBorderColor : Colors.black.withOpacity(0.06),
            height: 24,
          ),
          _buildInfoRow(
            Icons.email_outlined,
            l10n.email,
            _profile?.email ?? '',
            textColor,
            subtextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textColor, Color subtextColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: subtextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPicker(Color cardColor, Color textColor, Color subtextColor, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.chooseAvatar,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: ProfilePage.avatars.length,
            itemBuilder: (context, index) {
              final avatar = ProfilePage.avatars[index];
              final isSelected = avatar.id == _selectedAvatar;
              return GestureDetector(
                onTap: () => _selectAvatar(avatar.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [avatar.color, avatar.color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: avatar.color.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          avatar.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: avatar.color,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AvatarOption {
  final String id;
  final IconData icon;
  final Color color;

  const AvatarOption(this.id, this.icon, this.color);
}
