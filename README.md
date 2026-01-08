# 📱 KlikGadget - Electronic E-Commerce App

![KlikGadget Logo](assets/images/logo.png)

**KlikGadget** is a comprehensive mobile e-commerce application built with **Flutter** and **Supabase**. Designed for electronic products, it provides a seamless shopping experience for users and a robust management dashboard for administrators.

## 🌟 Features

### 👤 User Features
* **Authentication**: Secure Sign Up, Login, and Forgot Password functionality via Supabase Auth.
* **Product Browsing**:
    * Carousel banners for promotions.
    * Category-based filtering (HP, Laptop, TV, Tablet, etc.).
    * Search functionality with keyword filtering.
* **Product Details**: View detailed specifications, prices, and variants.
* **Shopping Cart**: Add items with specific variants (Color, Size/Specs), update quantities, and view total prices.
* **Checkout System**: Select shipping address, courier service, and payment method.
* **Wishlist**: Save favorite items for later.
* **Order History**: Track order status (Packed, Shipping, Completed) in real-time.
* **Reviews & Ratings**: Users can leave star ratings and comments on purchased products.
* **Profile Management**: Edit profile details, upload avatar, and manage shipping addresses.

### 🛡️ Admin Features
* **Dashboard**: Overview of store activities.
* **Product Management (CRUD)**: Add, Read, Update, and Delete electronic products with image uploading.
* **User Management**: View registered customers and manage accounts.
* **Transaction Management**: View incoming orders and update order statuses (e.g., from 'Packed' to 'Delivered').

## 🛠️ Tech Stack

* **Frontend**: [Flutter](https://flutter.dev/) (Dart)
* **Backend & Database**: [Supabase](https://supabase.com/) (PostgreSQL)
* **State Management**: `setState` & `StreamBuilder` (Real-time updates)
* **Key Packages**:
    * `supabase_flutter`: Backend integration.
    * `google_fonts`: Custom typography.
    * `flutter_rating_bar`: Star rating UI.
    * `carousel_slider`: Home screen banners.
    * `image_picker`: Uploading profile and product images.
    * `flutter_slidable`: Swipe actions in lists.
    * `intl`: Currency and date formatting.

## 📂 Project Structure

```text
lib/
├── components/      # Reusable UI widgets (e.g., profile_picture.dart)
├── constant/        # Configuration files (config.dart)
├── Model/           # Data models (e.g., Varian.dart)
├── screens/
│   ├── admin/       # Admin specific screens (CRUD Product, User, Transaction)
│   ├── user/        # User screens (Home, Cart, Checkout, Profile, History)
│   ├── login.dart   # Auth screens
│   ├── signup.dart
│   └── ...
├── services/        # Logic for Authentication
├── utils/           # Helper extensions
└── main.dart        # Entry point
