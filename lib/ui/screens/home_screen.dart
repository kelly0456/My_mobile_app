import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly_plus/flutter_iconly_plus.dart';
import 'package:provider/provider.dart';
import 'package:my_mobile_app/constants/app_constants.dart';
import 'package:my_mobile_app/data/models/product_model.dart';
import 'package:my_mobile_app/ui/screens/viewmodels/product_viewmodel.dart';
import 'package:my_mobile_app/ui/screens/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  static const routName = "/HomeScreen";

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _searchController;
  String _selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Electronics',
    'Clothing',
    'Shoes',
    'Food',
    'Beauty',
    'Home',
    'Books',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productViewModel = context.read<ProductViewModel>();
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shopify"),
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.notification),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // =====================================================
          // SEARCH BAR
          // =====================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search products...",
                      prefixIcon: const Icon(IconlyLight.search),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ),

          // =====================================================
          // BANNER SWIPER
          // =====================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: AspectRatio(
                    aspectRatio: isTablet ? 3 / 1 : 2 / 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Swiper(
                        itemBuilder: (context, index) {
                          return Image.asset(
                            AppConstants.bannerImage[index],
                            fit: BoxFit.cover,
                          );
                        },
                        autoplay: true,
                        itemCount: AppConstants.bannerImage.length,
                        pagination: const SwiperPagination(
                          builder: DotSwiperPaginationBuilder(
                            activeColor: Colors.blue,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // =====================================================
          // CATEGORIES
          // =====================================================
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      selectedColor: Colors.blue.withValues(alpha: 0.2),
                      checkmarkColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue.shade900 : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // =====================================================
          // SECTION TITLE
          // =====================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                _selectedCategory == 'All' ? "Latest Products" : "$_selectedCategory Products",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // =====================================================
          // PRODUCTS GRID
          // =====================================================
          StreamBuilder<List<ProductModel>>(
            stream: productViewModel.products,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(child: Text("Error: ${snapshot.error}")),
                );
              }

              var products = snapshot.data ?? [];

              if (_selectedCategory != 'All') {
                products = products.where((p) => p.category == _selectedCategory).toList();
              }
              if (_searchController.text.isNotEmpty) {
                final query = _searchController.text.toLowerCase();
                products = products.where((p) => p.name.toLowerCase().contains(query)).toList();
              }

              if (products.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No products found.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 4 : (isTablet ? 3 : 2),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(product: products[index]),
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
