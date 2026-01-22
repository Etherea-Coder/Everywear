import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/achievement_badge_widget.dart';
import './widgets/module_card_widget.dart';
import './widgets/progress_header_widget.dart';

/// Learning Paths Screen - Progressive fashion education curriculum
/// Implements mobile-optimized learning modules unlocked by user engagement
class LearningPaths extends StatefulWidget {
  const LearningPaths({Key? key}) : super(key: key);

  @override
  State<LearningPaths> createState() => _LearningPathsState();
}

class _LearningPathsState extends State<LearningPaths> {
  // User progress data
  int _currentLevel = 2;
  int _totalModulesCompleted = 3;
  int _totalModules = 12;
  double _overallProgress = 0.25;
  int _outfitsLogged = 15;
  int _wardrobeItems = 42;

  // Learning modules data with unlock requirements
  final List<Map<String, dynamic>> _learningModules = [
    {
      "id": 1,
      "title": "Understanding Your Style Foundation",
      "description":
          "Discover your personal style preferences and what makes you feel confident",
      "difficulty": "Beginner",
      "estimatedTime": "15 min",
      "isUnlocked": true,
      "isCompleted": true,
      "progress": 1.0,
      "unlockRequirement": "Available from start",
      "requiredOutfits": 0,
      "keyLearnings": [
        "Style personality types",
        "Color preferences",
        "Comfort zones",
      ],
      "image":
          "https://images.unsplash.com/photo-1660150912355-83e1298d0115",
      "semanticLabel":
          "Minimalist wardrobe with neutral colored clothing hanging on wooden rack against white wall",
    },
    {
      "id": 2,
      "title": "Cost-Per-Wear Fundamentals",
      "description":
          "Learn how to calculate and optimize the true value of your clothing investments",
      "difficulty": "Beginner",
      "estimatedTime": "20 min",
      "isUnlocked": true,
      "isCompleted": true,
      "progress": 1.0,
      "unlockRequirement": "Log 5 outfits",
      "requiredOutfits": 5,
      "keyLearnings": [
        "CPW calculation",
        "Quality vs quantity",
        "Investment pieces",
      ],
      "image":
          "https://images.unsplash.com/photo-1735377143405-0a936298221c",
      "semanticLabel":
          "Close-up of clothing price tags and calculator on wooden surface with fabric swatches",
    },
    {
      "id": 3,
      "title": "Sustainable Fashion Principles",
      "description":
          "Explore eco-friendly fashion choices and their impact on the environment",
      "difficulty": "Beginner",
      "estimatedTime": "25 min",
      "isUnlocked": true,
      "isCompleted": true,
      "progress": 1.0,
      "unlockRequirement": "Complete 2 modules",
      "requiredOutfits": 5,
      "keyLearnings": [
        "Fast fashion impact",
        "Sustainable materials",
        "Circular fashion",
      ],
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_17ec43db6-1764655133593.png",
      "semanticLabel":
          "Eco-friendly clothing made from organic cotton and recycled materials on natural wooden background",
    },
    {
      "id": 4,
      "title": "Building a Capsule Wardrobe",
      "description":
          "Master the art of creating a versatile wardrobe with fewer, better pieces",
      "difficulty": "Intermediate",
      "estimatedTime": "30 min",
      "isUnlocked": true,
      "isCompleted": false,
      "progress": 0.6,
      "unlockRequirement": "Log 10 outfits",
      "requiredOutfits": 10,
      "keyLearnings": [
        "Essential pieces",
        "Mix and match",
        "Seasonal transitions",
      ],
      "image":
          "https://images.unsplash.com/photo-1714386450125-4ffb8fad9ef7",
      "semanticLabel":
          "Organized capsule wardrobe with coordinated neutral clothing items neatly arranged on shelves",
    },
    {
      "id": 5,
      "title": "Color Theory for Personal Style",
      "description":
          "Understand how colors work together and complement your natural features",
      "difficulty": "Intermediate",
      "estimatedTime": "25 min",
      "isUnlocked": true,
      "isCompleted": false,
      "progress": 0.0,
      "unlockRequirement": "Add 20 wardrobe items",
      "requiredOutfits": 10,
      "keyLearnings": [
        "Color wheel basics",
        "Complementary colors",
        "Seasonal palettes",
      ],
      "image":
          "https://images.unsplash.com/photo-1655706512475-2c4f64dc15e1",
      "semanticLabel":
          "Colorful fabric swatches arranged in rainbow spectrum showing various textile colors and textures",
    },
    {
      "id": 6,
      "title": "Wardrobe Rotation Strategies",
      "description":
          "Learn techniques to maximize wear from all your clothing items",
      "difficulty": "Intermediate",
      "estimatedTime": "20 min",
      "isUnlocked": false,
      "isCompleted": false,
      "progress": 0.0,
      "unlockRequirement": "Log 20 outfits",
      "requiredOutfits": 20,
      "keyLearnings": [
        "Rotation systems",
        "Seasonal storage",
        "Outfit planning",
      ],
      "image":
          "https://images.unsplash.com/photo-1614990354198-b06764dcb13c",
      "semanticLabel":
          "Well-organized closet with clothing arranged by category and color on wooden hangers",
    },
    {
      "id": 7,
      "title": "Fabric Care and Longevity",
      "description":
          "Extend the life of your clothes with proper care and maintenance techniques",
      "difficulty": "Intermediate",
      "estimatedTime": "25 min",
      "isUnlocked": false,
      "isCompleted": false,
      "progress": 0.0,
      "unlockRequirement": "Add 30 wardrobe items",
      "requiredOutfits": 15,
      "keyLearnings": [
        "Washing techniques",
        "Storage methods",
        "Repair basics",
      ],
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1f9d47d8d-1767708713635.png",
      "semanticLabel":
          "Hands gently washing delicate fabric in basin with natural soap and water",
    },
    {
      "id": 8,
      "title": "Mindful Shopping Habits",
      "description":
          "Develop intentional purchasing strategies to avoid regret and waste",
      "difficulty": "Advanced",
      "estimatedTime": "30 min",
      "isUnlocked": false,
      "isCompleted": false,
      "progress": 0.0,
      "unlockRequirement": "Log 30 outfits",
      "requiredOutfits": 30,
      "keyLearnings": [
        "Pre-purchase checklist",
        "Trend evaluation",
        "Budget planning",
      ],
      "image":
          "https://images.unsplash.com/photo-1687405181685-9f27883eb11b",
      "semanticLabel":
          "Person thoughtfully examining clothing quality in minimalist boutique with natural lighting",
    },
    {
      "id": 9,
      "title": "Style Evolution and Adaptation",
      "description":
          "Navigate style changes while maintaining authenticity and sustainability",
      "difficulty": "Advanced",
      "estimatedTime": "25 min",
      "isUnlocked": false,
      "isCompleted": false,
      "progress": 0.0,
      "unlockRequirement": "Complete 6 modules",
      "requiredOutfits": 25,
      "keyLearnings": [
        "Style transitions",
        "Wardrobe updates",
        "Authentic expression",
      ],
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_17907d6fb-1768169633649.png",
      "semanticLabel":
          "Fashion evolution concept with vintage and modern clothing styles displayed side by side",
    },
    {
      "id": 10,
      "title": "Advanced Outfit Composition",
      "description":
          "Master the principles of creating visually balanced and intentional outfits",
      "difficulty": "Advanced",
      "estimatedTime": "35 min",
      "isUnlocked": false,
      "isCompleted": false,
      "progress": 0.0,
      "unlockRequirement": "Log 40 outfits",
      "requiredOutfits": 40,
      "keyLearnings": [
        "Proportion and balance",
        "Layering techniques",
        "Accessory integration",
      ],
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1c8e1ab76-1764798615891.png",
      "semanticLabel":
          "Stylish outfit flat lay with coordinated clothing pieces and accessories arranged artistically",
    },
    {
      "id": 11,
      "title": "Ethical Fashion Ecosystem",
      "description":
          "Understand the broader impact of fashion choices on people and planet",
      "difficulty": "Advanced",
      "estimatedTime": "30 min",
      "isUnlocked": false,
      "isCompleted": false,
      "progress": 0.0,
      "unlockRequirement": "Add 50 wardrobe items",
      "requiredOutfits": 35,
      "keyLearnings": [
        "Supply chain transparency",
        "Fair labor practices",
        "Brand evaluation",
      ],
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_155085adc-1767350981605.png",
      "semanticLabel":
          "Ethical fashion concept with natural fabrics and sustainable clothing production materials",
    },
    {
      "id": 12,
      "title": "Personal Style Mastery",
      "description":
          "Synthesize all learnings into a cohesive, sustainable personal style philosophy",
      "difficulty": "Advanced",
      "estimatedTime": "40 min",
      "isUnlocked": false,
      "isCompleted": false,
      "progress": 0.0,
      "unlockRequirement": "Complete all previous modules",
      "requiredOutfits": 50,
      "keyLearnings": [
        "Style manifesto",
        "Long-term planning",
        "Community impact",
      ],
      "image":
          "https://images.unsplash.com/photo-1656332694799-5fd721c0c2d8",
      "semanticLabel":
          "Confident person in signature personal style outfit standing in minimalist modern space",
    },
  ];

  // Achievement badges
  final List<Map<String, dynamic>> _achievements = [
    {
      "id": 1,
      "title": "First Steps",
      "description": "Completed your first module",
      "isUnlocked": true,
      "icon": "school",
    },
    {
      "id": 2,
      "title": "Knowledge Seeker",
      "description": "Completed 3 modules",
      "isUnlocked": true,
      "icon": "auto_stories",
    },
    {
      "id": 3,
      "title": "Style Scholar",
      "description": "Reached Level 2",
      "isUnlocked": true,
      "icon": "workspace_premium",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: CustomAppBar(
          title: 'Learning Paths',
          variant: CustomAppBarVariant.detail,
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'info_outline',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () => _showInfoDialog(context),
              tooltip: 'About Learning Paths',
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Progress header
          SliverToBoxAdapter(
            child: ProgressHeaderWidget(
              currentLevel: _currentLevel,
              overallProgress: _overallProgress,
              totalModulesCompleted: _totalModulesCompleted,
              totalModules: _totalModules,
            ),
          ),

          // Achievement badges section
          _achievements.isNotEmpty
              ? SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.h),
                        child: Text(
                          'Recent Achievements',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 12.h,
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          scrollDirection: Axis.horizontal,
                          itemCount: _achievements.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(width: 3.w),
                          itemBuilder: (context, index) {
                            final achievement = _achievements[index];
                            return AchievementBadgeWidget(
                              title: achievement["title"] as String,
                              description: achievement["description"] as String,
                              icon: achievement["icon"] as String,
                              isUnlocked: achievement["isUnlocked"] as bool,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],
                  ),
                )
              : const SliverToBoxAdapter(child: SizedBox.shrink()),

          // Modules section header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Learning Modules',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_totalModulesCompleted/$_totalModules completed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Learning modules list
          SliverPadding(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 10.h),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final module = _learningModules[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: ModuleCardWidget(
                    title: module["title"] as String,
                    description: module["description"] as String,
                    difficulty: module["difficulty"] as String,
                    estimatedTime: module["estimatedTime"] as String,
                    isUnlocked: module["isUnlocked"] as bool,
                    isCompleted: module["isCompleted"] as bool,
                    progress: module["progress"] as double,
                    unlockRequirement: module["unlockRequirement"] as String,
                    requiredOutfits: module["requiredOutfits"] as int,
                    currentOutfits: _outfitsLogged,
                    keyLearnings: (module["keyLearnings"] as List)
                        .cast<String>(),
                    imageUrl: module["image"] as String,
                    semanticLabel: module["semanticLabel"] as String,
                    onTap: () => _handleModuleTap(context, module),
                  ),
                );
              }, childCount: _learningModules.length),
            ),
          ),
        ],
      ),
    );
  }

  void _handleModuleTap(BuildContext context, Map<String, dynamic> module) {
    final theme = Theme.of(context);
    final isUnlocked = module["isUnlocked"] as bool;
    final isCompleted = module["isCompleted"] as bool;

    if (!isUnlocked) {
      _showUnlockRequirementDialog(context, module);
      return;
    }

    // Navigate to module content (placeholder for now)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomImageWidget(
                      imageUrl: module["image"] as String,
                      width: double.infinity,
                      height: 25.h,
                      fit: BoxFit.cover,
                      semanticLabel: module["semanticLabel"] as String,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(
                              module["difficulty"] as String,
                              theme,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            module["difficulty"] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getDifficultyColor(
                                module["difficulty"] as String,
                                theme,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        CustomIconWidget(
                          iconName: 'schedule',
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          module["estimatedTime"] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      module["title"] as String,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      module["description"] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Key Learnings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ...(module["keyLearnings"] as List<String>).map(
                      (learning) => Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 0.5.h),
                              child: CustomIconWidget(
                                iconName: 'check_circle',
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                learning,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showComingSoonMessage(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.8.h),
                        ),
                        child: Text(
                          isCompleted ? 'Review Module' : 'Start Module',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlockRequirementDialog(
    BuildContext context,
    Map<String, dynamic> module,
  ) {
    final theme = Theme.of(context);
    final requiredOutfits = module["requiredOutfits"] as int;
    final remaining = requiredOutfits - _outfitsLogged;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'lock',
              size: 24,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text('Module Locked', style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              module["unlockRequirement"] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            remaining > 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: $_outfitsLogged / $requiredOutfits outfits logged',
                        style: theme.textTheme.bodyMedium,
                      ),
                      SizedBox(height: 1.h),
                      LinearProgressIndicator(
                        value: _outfitsLogged / requiredOutfits,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '$remaining more ${remaining == 1 ? 'outfit' : 'outfits'} needed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Complete the required modules to unlock this content',
                    style: theme.textTheme.bodyMedium,
                  ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About Learning Paths', style: theme.textTheme.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Learning Paths helps you develop sustainable fashion knowledge through progressive modules.',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              Text(
                'How it works:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              _buildInfoPoint(
                context,
                'Log outfits and add wardrobe items to unlock new modules',
              ),
              _buildInfoPoint(
                context,
                'Complete modules to earn achievements and level up',
              ),
              _buildInfoPoint(
                context,
                'Learn at your own pace with mobile-optimized content',
              ),
              _buildInfoPoint(
                context,
                'Premium users get advanced modules and personalized recommendations',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 0.3.h),
            child: CustomIconWidget(
              iconName: 'check_circle',
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  void _showComingSoonMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Module content coming soon! Continue logging outfits to unlock more.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty, ThemeData theme) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return theme.colorScheme.primary;
      case 'intermediate':
        return const Color(0xFFB8860B);
      case 'advanced':
        return const Color(0xFFA0522D);
      default:
        return theme.colorScheme.primary;
    }
  }
}
