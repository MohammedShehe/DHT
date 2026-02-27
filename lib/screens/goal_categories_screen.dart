import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gamification_models.dart';
import '../providers/gamification_provider.dart';
import '../services/goal_service.dart';
import '../widgets/goal_setting_dialog.dart';

class GoalCategoriesScreen extends StatefulWidget {
  const GoalCategoriesScreen({super.key});

  @override
  State<GoalCategoriesScreen> createState() => _GoalCategoriesScreenState();
}

class _GoalCategoriesScreenState extends State<GoalCategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  GoalMainCategory _selectedCategory = GoalMainCategory.all;
  
  final List<GoalMainCategory> _categories = GoalMainCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
      initialIndex: 0,
    );
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<GoalTemplate> get _filteredTemplates {
    if (_searchQuery.isNotEmpty) {
      return GoalTemplate.searchTemplates(_searchQuery);
    }
    
    if (_selectedCategory == GoalMainCategory.all) {
      return GoalTemplate.getAllTemplates();
    }
    
    return GoalTemplate.getTemplatesByCategory(_selectedCategory);
  }

  void _createGoalFromTemplate(GoalTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalSettingDialog(
        onGoalCreated: (goal) {
          final provider = Provider.of<GamificationProvider>(context, listen: false);
          provider.loadGoals();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${template.name} goal created!'),
              backgroundColor: template.color,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        template: template,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Browse Goals',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.grey,
          onTap: (index) {
            setState(() {
              _selectedCategory = _categories[index];
            });
          },
          tabs: _categories.map((category) {
            return Tab(
              icon: Icon(category.icon),
              text: category.displayName,
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search goals...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Recommended Section
          if (_searchQuery.isEmpty && _selectedCategory == GoalMainCategory.all) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommended for You',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = GoalMainCategory.all;
                        _tabController.animateTo(
                          GoalMainCategory.values.indexOf(GoalMainCategory.all),
                        );
                      });
                    },
                    child: const Text('View All'),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160, // Reduced from 180
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: GoalTemplate.getRecommendedTemplates().length,
                itemBuilder: (context, index) {
                  final template = GoalTemplate.getRecommendedTemplates()[index];
                  return _buildRecommendedCard(template);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Category Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  _selectedCategory.icon,
                  color: _selectedCategory.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _searchQuery.isNotEmpty 
                      ? 'Search Results' 
                      : _selectedCategory.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredTemplates.length} goals',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Goal Templates Grid
          Expanded(
            child: _filteredTemplates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No goals found for "$_searchQuery"'
                              : 'No goals in this category',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                            child: const Text('Clear Search'),
                          ),
                        ],
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75, // Changed from 0.85 to give more vertical space
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredTemplates.length,
                    itemBuilder: (context, index) {
                      final template = _filteredTemplates[index];
                      return _buildGoalTemplateCard(template);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCard(GoalTemplate template) {
    return GestureDetector(
      onTap: () => _createGoalFromTemplate(template),
      child: Container(
        width: 260, // Reduced from 280
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              template.color.withOpacity(0.8),
              template.color,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: template.color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 10,
              bottom: 10,
              child: Icon(
                template.icon,
                size: 60, // Reduced from 80
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12), // Reduced from 16
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6), // Reduced from 8
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10), // Reduced from 12
                    ),
                    child: Icon(
                      template.icon,
                      color: Colors.white,
                      size: 18, // Reduced from 24
                    ),
                  ),
                  const Spacer(),
                  Text(
                    template.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16, // Reduced from 20
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2), // Reduced from 4
                  Text(
                    template.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 10, // Reduced from 12
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4), // Reduced from 8
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced from 8,4
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8), // Reduced from 12
                        ),
                        child: Text(
                          '${template.defaultTarget.toInt()} ${_getUnitShort(template.type)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10, // Reduced from 12
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(2), // Reduced from 4
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: template.color,
                          size: 16, // Reduced from 20
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTemplateCard(GoalTemplate template) {
    return GestureDetector(
      onTap: () => _createGoalFromTemplate(template),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with color - fixed height
            Container(
              height: 70, // Reduced from 80
              decoration: BoxDecoration(
                color: template.color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Icon(
                      template.icon,
                      size: 40, // Reduced from 50
                      color: template.color.withOpacity(0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10), // Reduced from 12
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6), // Reduced from 8
                          decoration: BoxDecoration(
                            color: template.color,
                            borderRadius: BorderRadius.circular(10), // Reduced from 12
                          ),
                          child: Icon(
                            template.icon,
                            color: Colors.white,
                            size: 14, // Reduced from 16
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 10, // Reduced from 12
                              color: template.color,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${template.popularity}%',
                              style: TextStyle(
                                fontSize: 8, // Reduced from 10
                                color: template.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content - with fixed constraints
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10), // Reduced from 12
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 12, // Reduced from 14
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // Reduced from 4
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 8, // Reduced from 10
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // Reduced from 8
                    
                    // Tags
                    Wrap(
                      spacing: 2, // Reduced from 4
                      runSpacing: 2, // Reduced from 4
                      children: template.tags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Reduced from 6,2
                          decoration: BoxDecoration(
                            color: template.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4), // Reduced from 8
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 6, // Reduced from 8
                              color: template.color,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 4), // Reduced from 8
                    
                    // Target and period
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${template.defaultTarget.toInt()} ${_getUnitShort(template.type)}',
                          style: TextStyle(
                            fontSize: 10, // Reduced from 12
                            fontWeight: FontWeight.w700,
                            color: template.color,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Reduced from 6,2
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4), // Reduced from 8
                          ),
                          child: Text(
                            _getPeriodShort(template.period),
                            style: TextStyle(
                              fontSize: 6, // Reduced from 8
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
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

  String _getUnitShort(GoalType type) {
    switch (type) {
      case GoalType.steps:
        return 'steps';
      case GoalType.water:
        return 'gls';
      case GoalType.sleep:
        return 'hrs';
      case GoalType.meditation:
        return 'min';
      case GoalType.workouts:
        return 'wkts';
      case GoalType.calories:
        return 'kcal';
    }
  }

  String _getPeriodShort(GoalPeriod period) {
    switch (period) {
      case GoalPeriod.daily:
        return 'daily';
      case GoalPeriod.weekly:
        return 'weekly';
      case GoalPeriod.monthly:
        return 'monthly';
    }
  }
}